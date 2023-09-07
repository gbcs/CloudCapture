//
//  ReTimeConfirmViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/1/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ReTimeConfirmViewController.h"
#import "MovieManager.h"
#import "AppDelegate.h"

@interface ReTimeConfirmViewController () {
    __weak IBOutlet UIProgressView *progress;
    __weak IBOutlet UIActivityIndicatorView *activityView;
    __weak IBOutlet UILabel *processingLabel;
    __weak IBOutlet GradientAttributedButton *playButton;
    
     AVComposition *composition;
    
    NSURL *movieURL;
    AVAssetExportSession *exporter;
    NSTimer *progressTimer;
    NSString *movieFname;

    BOOL processingComplete;
}

@end

@implementation ReTimeConfirmViewController

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
    activityView = nil;
    processingLabel = nil;
    playButton = nil;
    
    composition = nil;
    
    movieURL = nil;
    exporter = nil;
    progressTimer = nil;
    movieFname = nil;
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
    AVMutableCompositionTrack *audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *clipVideoTrack = [[_clip tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVAssetTrack *clipAudioTrack = nil;
    
    if ([[_clip tracksWithMediaType:AVMediaTypeAudio] count]>0) {
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
  
    [videoTrack setPreferredTransform:clipVideoTrack.preferredTransform];
    
    CMTime timeMod = kCMTimeZero;
    
    for (NSInteger x=0;x<[cuts count];x++) {
        CMTime start = [[[cuts objectAtIndex:x] objectAtIndex:0] CMTimeValue];
        CMTime end = [[[cuts objectAtIndex:x] objectAtIndex:1] CMTimeValue];
        NSInteger fps = [[[cuts objectAtIndex:x] objectAtIndex:2] integerValue];
        
        CMTimeRange r = CMTimeRangeFromTimeToTime(CMTimeAdd(start, timeMod), CMTimeAdd(end, timeMod));
        
        CMTime duration  = kCMTimeZero;
        
        if (fps == 0) {
            duration = CMTimeMake([[[cuts objectAtIndex:x] objectAtIndex:3] integerValue] * self.naturalFrameRate, (int)self.naturalFrameRate);
            end = CMTimeAdd(start, CMTimeMake(1,(int)self.naturalFrameRate));
            r = CMTimeRangeFromTimeToTime(start, end);
        } else {
            duration = CMTimeMake(r.duration.value * ((float)self.naturalFrameRate / (float)fps), r.duration.timescale);
        }

        [mutableComposition scaleTimeRange:r toDuration:duration];
        
        CMTime durationChange = CMTimeSubtract(duration, r.duration);
        
        timeMod = CMTimeAdd(timeMod, durationChange);
    }
    
    composition  = [mutableComposition copy];
    
    movieFname = [[UtilityBag bag] pathForNewResourceWithExtension:@"mov"];
    NSString *newMovieFile = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname];
    movieURL = [NSURL fileURLWithPath:newMovieFile];
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
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
   
    if (clipAudioTrack) {
        exporter.audioTimePitchAlgorithm  = AVAudioTimePitchAlgorithmVarispeed;
    }
    
    exporter.timeRange=CMTimeRangeFromTimeToTime(CMTimeMake(1,composition.duration.timescale), composition.duration);
    
    if (!progressTimer) {
        progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(progressTimerEvent) userInfo:nil repeats:YES];
    }
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self enablePlayButton];
                    [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
                });
            }
        }
        [self performSelectorOnMainThread:@selector(stopProgressIndicators) withObject:nil waitUntilDone:NO];
        
    }];
}

-(void)enablePlayButton {
    processingLabel.text = @"Complete";
    [self updateButton];
    
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
    playButton.delegate = self;
    playButton.tag = 0;

    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];
}


-(void)userTappedCancel {
    if (movieFname) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname] error:&error];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)userTappedCommit {
    [[UtilityBag bag] makeThumbnail:movieFname];
    [[UtilityBag bag] logEvent:@"retimeVideo" withParameters:nil];
    
    UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 3];
    [self.navigationController popToViewController:vc animated:YES];
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (!processingComplete) {
        return;
    }
    
    if (tag == 0) {
        [[MovieManager manager] playClipAtPath:movieFname];
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
     playButton.enabled = YES;
   
    if (processingComplete) {
         [playButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    } else {
         [playButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    [playButton update];
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
    [[UtilityBag bag] startTimingOperation];
    [self performSelector:@selector(cutClip) withObject:nil afterDelay:0.1];
}


@end
