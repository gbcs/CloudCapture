//
//  CutConfirmViewController.m
//  Capture
//
//  Created by Gary Barnett on 9/9/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CutConfirmViewController.h"
#import "MovieManager.h"
#import "AppDelegate.h"

@interface CutConfirmViewController () {
    __weak IBOutlet UIProgressView *progress;
    
    __weak IBOutlet GradientAttributedButton *rotateButton;
    __weak IBOutlet UIActivityIndicatorView *activityView;
    __weak IBOutlet UILabel *processingLabel;
    __weak IBOutlet GradientAttributedButton *playButton;
    
   AVComposition *composition;
    NSURL *movieURL;
    AVAssetExportSession *exporter;
    NSTimer *progressTimer;
    NSString *movieFname;
    BOOL rotateClip;
    BOOL processingComplete;

    AVComposition *audioComposition;
}

@end

@implementation CutConfirmViewController

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
    //NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    _clip = nil;
    
    progress = nil;
    
    rotateButton = nil;
    activityView = nil;
    processingLabel = nil;
    playButton = nil;
    
    composition = nil;
    movieURL = nil;
    exporter = nil;
    progressTimer = nil;
    movieFname = nil;
    audioComposition = nil;
    _clip = nil;
    _cutList = nil;
    
}

-(void)rotateAndEncode {
    rotateClip = !rotateClip;
    
    composition = nil;
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    while ([mutableComposition.tracks count] >0) {
        AVMutableCompositionTrack *track = [mutableComposition.tracks objectAtIndex:0];
        [mutableComposition removeTrack:track];
    }
        // NSLog(@"comp:%@", mutableComposition);
    NSString *badMovieFile = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:badMovieFile error:&error];
    processingComplete = NO;
    [self updateButton];
    
    progress.progress = 0.0f;
    progress.hidden = NO;
    processingLabel.text = @"Processing";
    
    [activityView startAnimating];
    
    [self performSelector:@selector(cutClip) withObject:nil afterDelay:0.01];
}

-(void)cutClip {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = NO;
    
    NSArray *cuts = [[AssetManager manager] sortCutList:_cutList];

    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    NSError *editError;
    CMTime begin = CMTimeMake(1,_clip.duration.timescale);
   
    AVMutableCompositionTrack *videoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = nil;
    
    AVAssetTrack *clipVideoTrack = [[_clip tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    if ([[_clip tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
        audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    }
   
    AVAssetTrack *clipAudioTrack = nil;
    
    if (audioTrack) {
        clipAudioTrack = [[_clip tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    
    BOOL error = NO;
    
    [videoTrack insertTimeRange:CMTimeRangeMake(begin, _clip.duration) ofTrack:clipVideoTrack atTime:begin error:&editError];
    
    if (editError) {
        error = YES;
    }
    
    if (clipAudioTrack) {
        [audioTrack insertTimeRange:CMTimeRangeMake(begin, _clip.duration) ofTrack:clipAudioTrack atTime:begin error:&editError];
        
        if (editError) {
            error = YES;
        }
    }
    
    if(error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clip Error" message:@"Unable to access existing clip." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

    if (rotateClip) {
        CGAffineTransform rotationTransform = CGAffineTransformRotate(clipVideoTrack.preferredTransform, (-90 + 270) * M_PI/180);
        [videoTrack setPreferredTransform:rotationTransform];
    } else {
        [videoTrack setPreferredTransform:clipVideoTrack.preferredTransform];
    }
    
    CMTime timeRemoved = kCMTimeZero;
    for (NSInteger x=0;x<[cuts count];x++) {
        CMTime start = [[[cuts objectAtIndex:x] objectAtIndex:0] CMTimeValue];
        CMTime end = [[[cuts objectAtIndex:x] objectAtIndex:1] CMTimeValue];
        
        CMTime modStart = CMTimeSubtract(start, timeRemoved);
        CMTime modEnd = CMTimeSubtract(end, timeRemoved);
        
        [mutableComposition removeTimeRange:CMTimeRangeFromTimeToTime(modStart, modEnd)];
        timeRemoved = CMTimeAdd(timeRemoved, CMTimeSubtract(end, start));
        
        NSLog(@"Removed %@ -> %@", [NSValue valueWithCMTime:modStart], [NSValue valueWithCMTime:modEnd]);
    }
    
    composition  = [mutableComposition copy];
    
    movieFname = [[UtilityBag bag] pathForNewResourceWithExtension:@"mov"];
    NSString *newMovieFile = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname];
    movieURL = [NSURL fileURLWithPath:newMovieFile];
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    exporter.outputURL=movieURL;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *originalTimeStr = [dateFormatter stringFromDate:[NSDate date]];
   
    NSString *originalLoc = @"";
    NSString *originalTitle = @"";
    
    NSArray *originalMetadata = [_clip metadataForFormat:@"com.apple.quicktime.mdta"];
    for (AVMutableMetadataItem *a in originalMetadata) {
        if ([a.commonKey isEqualToString:@"creationDate"]) {
            originalTimeStr = (NSString *)a.value;
        } else if ([a.commonKey isEqualToString:@"location"]) {
            originalLoc = (NSString *)a.value;
        } else if ([a.commonKey isEqualToString:@"title"]) {
            originalTitle = (NSString *)a.value;
        }
    }
    
    NSMutableArray *metadata = [[NSMutableArray alloc] initWithCapacity:3];
                                
    AVMutableMetadataItem *item = nil;
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.key = AVMetadataCommonKeyCreationDate;
    item.value = originalTimeStr;
    [metadata addObject:item];

    if ([[SettingsTool settings] useGPS] && originalLoc && ([originalLoc length] >0) ) {
        item = [[AVMutableMetadataItem alloc] init];
        item.keySpace = AVMetadataKeySpaceCommon;
        item.key = AVMetadataCommonKeyLocation;
        item.value = originalLoc;
        [metadata addObject:item];
    }
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceQuickTimeUserData;
    item.key = AVMetadataQuickTimeUserDataKeyTrack;
    item.value = [NSNumber numberWithInt:1];
    [metadata addObject:item];
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.locale = [NSLocale currentLocale];
    item.key = AVMetadataCommonKeyTitle;
    item.value = [NSString stringWithFormat:@"%@[cut]", originalTitle];
    [metadata addObject:item];
    
    
    AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
    [metadata addObject:descUID];

    
    exporter.metadata = [metadata copy];
    
    exporter.timeRange=CMTimeRangeFromTimeToTime(CMTimeMake(1,composition.duration.timescale), composition.duration);
    
    if (!progressTimer) {
        progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(progressTimerEvent) userInfo:nil repeats:YES];
    }
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        [self performSelectorOnMainThread:@selector(stopProgressIndicators) withObject:nil waitUntilDone:NO];
        processingComplete = YES;
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed:{
                NSLog(@"Export failed: %@ %@", [[exporter error] localizedDescription],[[exporter error]debugDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    processingLabel.text = @"Failed";
                });
                break;
            }
            case AVAssetExportSessionStatusCancelled:{
                NSLog(@"Export canceled");
                dispatch_async(dispatch_get_main_queue(), ^{
                    processingLabel.text = @"Cancelled";
                });
                break;
            }
            case AVAssetExportSessionStatusCompleted:
            {
                [self performSelectorOnMainThread:@selector(enablePlayButton) withObject:nil waitUntilDone:NO];
            }
        }
    }];
}

-(void)enablePlayButton {
    processingLabel.text = @"Complete";
    [self updateButton];
    [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
}
     
-(void)stopProgressIndicators {
    progress.hidden = YES;
    [progressTimer invalidate];
    progressTimer = nil;
    [activityView stopAnimating];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

-(void)progressTimerEvent {
    dispatch_async(dispatch_get_main_queue(), ^{
        progress.progress = exporter.progress;
        processingLabel.text = [[UtilityBag bag] returnRemainingTimeForOperationWithProgress:exporter.progress];
    });
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    processingComplete = NO;
    self.navigationItem.title = @"Confirm Edit";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCommit)];
    playButton.enabled = YES;
    rotateButton.enabled = playButton.enabled;
    playButton.delegate = self;
    rotateButton.delegate = self;
    playButton.tag = 0;
    rotateButton.tag = 1;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];
    
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [[MovieManager manager] closePlayer];
}

-(void)userTappedCancel {
    if (movieFname) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname] error:&error];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)userTappedCommit {
    [[UtilityBag bag] makeThumbnail:movieFname];
    [[UtilityBag bag] logEvent:@"cutVideo" withParameters:nil];
    
    UIViewController *libVC = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] -3];
    [self.navigationController popToViewController:libVC animated:YES];

}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (!processingComplete) {
        return;
    }
    
    if (tag == 0) {
        [[MovieManager manager] playClipAtPath:movieFname];
    } else {
        [self rotateAndEncode];
    }
}

-(void)updateButton {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    NSAttributedString *sActive = [[NSAttributedString alloc] initWithString:@"Play Edited Clip" attributes:@{
                                                                                                   NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                   NSShadowAttributeName : shadow,
                                                                                                   NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                   }];
    NSAttributedString *sRotate = [[NSAttributedString alloc] initWithString:@"Rotate Clip" attributes:@{
                                                                                                              NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                              NSShadowAttributeName : shadow,
                                                                                                              NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                             
                                                                                                              }];

    playButton.enabled = YES;
    rotateButton.enabled = YES;
    
    if (processingComplete) {
        [rotateButton setTitle:sRotate disabledTitle:sRotate beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
        [playButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    } else {
        [rotateButton setTitle:sRotate disabledTitle:sRotate beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
        [playButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }

    [playButton update];
    [rotateButton update];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateButton];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateButton];
    playButton.alpha = 1.0f;
    rotateButton.alpha = 1.0f;
    [[UtilityBag bag] startTimingOperation];
   [self performSelector:@selector(cutClip) withObject:nil afterDelay:0.1];
}





@end
