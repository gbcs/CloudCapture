//
//  AudioVolumeConfirmViewController.m
//  Capture
//
//  Created by Gary Barnett on 2/1/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AudioVolumeConfirmViewController.h"
#import "AppDelegate.h"
@interface AudioVolumeConfirmViewController ()

@end

@interface AudioVolumeConfirmViewController () {
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
    
    
    BOOL isPlaying;
    
    UIDynamicAnimator *animator;
    UIView *audioPlayerView;
    UISlider *audioPlayerSlider;
    UILabel *audioPosLabel;
    
    AVAudioPlayer *audioPlayer;
    
    NSTimer *audioPlayTimer;
    float updatedPosition;
    
    AVMutableAudioMix *audioMixer;
}

@end

@implementation AudioVolumeConfirmViewController

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
        //NSLog(@"%s", __func__);
    
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    progress = nil;
    activityView = nil;
    processingLabel = nil;
    playButton = nil;
    composition = nil;
    movieURL = nil;
    exporter = nil;
    progressTimer = nil;
    movieFname = nil;
    audioPlayer = nil;
    audioPlayTimer = nil;
    animator = nil;
    audioPlayerView = nil;
    audioPlayerSlider = nil;
    audioPosLabel = nil;
    _clip = nil;
    _volList = nil;
}

-(void)cutClip {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = NO;
    
    _volList = [[AssetManager manager] sortCutList:_volList];
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
  
    NSError *editError;
    CMTime begin = CMTimeMake(1,_clip.duration.timescale);
    
    AVMutableCompositionTrack *audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *clipAudioTrack = [[_clip tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    BOOL error = NO;
    
    [audioTrack insertTimeRange:CMTimeRangeMake(begin, _clip.duration) ofTrack:clipAudioTrack atTime:begin error:&editError];
    
    if (editError) {
        error = YES;
    }
    
    if(error) {
        NSLog(@"adderr:%@", [editError localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clip Error" message:@"Unable to access existing clip." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    
    NSLog(@"Clip duration:%@", [NSValue valueWithCMTime:_clip.duration]);
   
    NSMutableArray *audioMix = [[NSMutableArray alloc] initWithCapacity:[_volList count]];
   

    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
    
    for (NSInteger x=0;x<[_volList count];x++) {
        CMTime start = [[[_volList objectAtIndex:x] objectAtIndex:0] CMTimeValue];
        CMTime end = [[[_volList objectAtIndex:x] objectAtIndex:1] CMTimeValue];
        CGFloat volume = [[[_volList objectAtIndex:x] objectAtIndex:2] floatValue];
        NSInteger transitionIn = [[[_volList objectAtIndex:x] objectAtIndex:3] integerValue];
        NSInteger transitionOut = [[[_volList objectAtIndex:x] objectAtIndex:4] integerValue];
        CMTime duration = CMTimeMakeWithSeconds([[[_volList objectAtIndex:x] objectAtIndex:5] floatValue], _clip.duration.timescale);
       
        CMTimeRange r = CMTimeRangeFromTimeToTime(start, end);
        CMTime halfLen = CMTimeMake(r.duration.value / 2, r.duration.timescale);
        
        if (duration.value == 0) {
            transitionIn = 0;
            transitionOut = 0;
        } else {
            if (CMTimeCompare(duration, halfLen) == NSOrderedDescending) {
                duration = halfLen;
            }
        }
        
        if (transitionIn && transitionOut) {
            [trackMix setVolumeRampFromStartVolume:1.0f toEndVolume:volume timeRange:CMTimeRangeMake(start, duration)];
            [trackMix setVolumeRampFromStartVolume:volume toEndVolume:1.0f timeRange:CMTimeRangeFromTimeToTime(CMTimeSubtract(end, duration), end)];
            NSLog(@"rampIn:1.0->%0.1f:%@", volume, [NSValue valueWithCMTimeRange:CMTimeRangeMake(start, duration)]);
            NSLog(@"rampOut:%0.1f->1.0:%@", volume, [NSValue valueWithCMTimeRange:CMTimeRangeFromTimeToTime(CMTimeSubtract(end, duration), end)]);
        } else if (transitionIn) {
            [trackMix setVolumeRampFromStartVolume:1.0f toEndVolume:volume timeRange:CMTimeRangeMake(start, duration)];
            NSLog(@"volumeSetOut:%0.1f:%@", 1.0, [NSValue valueWithCMTime:end]);
            [trackMix setVolume:1.0 atTime:end];
            NSLog(@"rampIn:1.0->%0.1f:%@", volume, [NSValue valueWithCMTimeRange:CMTimeRangeMake(start, duration)]);
        } else if (transitionOut) {
            NSLog(@"volumeSetIn:%0.1f:%@", 1.0, [NSValue valueWithCMTime:start]);
            [trackMix setVolume:1.0 atTime:start];
            NSLog(@"rampOut:%0.1f->1.0:%@", volume, [NSValue valueWithCMTimeRange:CMTimeRangeFromTimeToTime(CMTimeSubtract(end, duration), end)]);
            [trackMix setVolumeRampFromStartVolume:volume toEndVolume:1.0f timeRange:CMTimeRangeFromTimeToTime(CMTimeSubtract(end, duration), end)];
        } else {
            NSLog(@"volumeSetIn:%0.1f:%@", volume, [NSValue valueWithCMTime:start]);
            [trackMix setVolume:volume atTime:start];
            NSLog(@"volumeSetOut:%0.1f:%@", 1.0, [NSValue valueWithCMTime:end]);
            [trackMix setVolume:1.0 atTime:end];
        }
    }
    
    
    [audioMix addObject:trackMix];

    audioMixer = [AVMutableAudioMix audioMix];
    audioMixer.inputParameters = [audioMix copy];
    
    composition  = [mutableComposition copy];
    
    movieFname = [[UtilityBag bag] pathForNewResourceWithExtension:@"m4a"];
    NSString *newMovieFile = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname];
    movieURL = [NSURL fileURLWithPath:newMovieFile];
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    exporter.outputFileType=AVFileTypeAppleM4A;
    exporter.outputURL=movieURL;
    exporter.audioMix = [audioMixer copy];
	
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
    
    if ([[SettingsTool settings] useGPS]) {
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
    item.value = [NSString stringWithFormat:@"%@[volume adjust]", originalTitle];
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
                processingLabel.text = @"Failed";
                break;
            }
            case AVAssetExportSessionStatusCancelled:{
                NSLog(@"Export canceled");
                processingLabel.text = @"Cancelled";
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
    playButton.enabled = YES;
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCommit)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    processingComplete = NO;
    self.navigationItem.title = @"Volume";
    playButton.enabled = YES;
    playButton.delegate = self;
    playButton.tag = 0;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanupAudioEditor" object:nil];
    
    
}


-(void)userTappedCancel {
    
    if (audioPlayer) {
        [self userPressedGradientAttributedButtonWithTag:0];
    }
    
    if (movieFname) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname] error:&error];
    }
    [[AssetManager manager] cleanupMoviePhotosTemp];
    
    UIViewController *libVC = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] -3];
    [self.navigationController popToViewController:libVC animated:YES];
}


-(void)userTappedCommit {
    if (audioPlayer) {
        [self userPressedGradientAttributedButtonWithTag:0];
    }
    
    [[UtilityBag bag] logEvent:@"volumeAudio" withParameters:nil];
    [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
    
    UIViewController *libVC = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] -3];
    [self.navigationController popToViewController:libVC animated:YES];
    [[AssetManager manager] cleanupMoviePhotosTemp];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAudioLibraryAndReload" object:nil];
    
}

-(void)closeAudioPlayer {
    
    [audioPlayTimer invalidate];
    audioPlayTimer = nil;
    
    [animator removeAllBehaviors];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ audioPlayerView] ];
    [animator addBehavior:gravity];
    [self performSelector:@selector(removeAudioPlayer) withObject:nil afterDelay:1.0];
    
}

-(void)removeAudioPlayer {
    [animator removeAllBehaviors];
    animator = nil;
    [audioPlayerView removeFromSuperview];
    audioPlayerView = nil;
    
    audioPlayerSlider = nil;
    audioPosLabel = nil;
    
    playButton.enabled = YES;
    [self updateButton];
}

-(NSString *)durationStr:(NSInteger )seconds {
    NSString *str = @"--:--:--";
    if (seconds >= 0) {
        NSInteger hours = seconds / (60 * 60);
        NSInteger mins = (seconds - (hours * 60*60)) / 60;
        NSInteger secs = seconds - (hours * 60 * 60) - (mins * 60);
        str = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)mins, (long)secs];
    }
    return str;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)showAudioPlayer {
    
    if (audioPlayerView) {
        return;
    }
    
    isPlaying = YES;
    playButton.enabled = NO;
    [self updateButton];
    
    
    audioPlayerView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200, -270, 400, 220)];
    audioPlayerView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [self.view addSubview:audioPlayerView];
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    CGFloat y = self.view.frame.size.height - 50;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = 340;
    }
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ audioPlayerView] ];
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ audioPlayerView] ];
    
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
    
    audioPosLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,100,400,50)];
    audioPosLabel.text = [self durationStr:CMTimeGetSeconds(asset.duration)];
    audioPosLabel.textColor = [UIColor whiteColor];
    audioPosLabel.textAlignment = NSTextAlignmentCenter;
    [audioPlayerView addSubview:audioPosLabel];
    
    
    audioPlayerSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,170,400,50)];
    [audioPlayerSlider addTarget:self action:@selector(posSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [audioPlayerView addSubview:audioPlayerSlider];
    
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:movieURL error:&error];
    if (error) {
        NSLog(@"audio file error:%@", [error localizedDescription]);
    }
    audioPlayer.numberOfLoops = 0;
    [audioPlayer setMeteringEnabled:YES];
    
    audioPlayerSlider.maximumValue = audioPlayer.duration;
    
    [self performSelector:@selector(startPlaying) withObject:nil afterDelay:2.0f];
    
    GradientAttributedButton *stopButton = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(310,0,80,50)];
    stopButton.enabled = YES;
    stopButton.delegate = self;
    stopButton.tag = 0;
    [audioPlayerView addSubview:stopButton];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    NSAttributedString *sActive = [[NSAttributedString alloc] initWithString:@"Close" attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                    NSShadowAttributeName : shadow,
                                                                                                    NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                    }];
    
    [stopButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    [stopButton update];
    
    
}

-(void)startPlaying {
    audioPlayTimer  = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateTimerEvent) userInfo:nil repeats:YES];
    [audioPlayer play];
}

-(void)updateTimerEvent {
    if (updatedPosition != 0.0f) {
        [audioPlayer setCurrentTime:updatedPosition];
        [audioPlayer play];
        updatedPosition = 0.0f;
    }
    
    [self updateBarPos];
    [self updateBarLabel];
    
    
}

- (void)posSliderValueChanged:(id)sender {
    updatedPosition = audioPlayerSlider.value;
}

-(void)updateBarPos {
    audioPlayerSlider.value = audioPlayer.currentTime;
}

-(void)updateBarLabel {
    
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    float hundreths = 0.0;
    
    days = audioPlayer.currentTime / (24 * 60 * 60);
    
    int remain = audioPlayer.currentTime - (days * 24 * 60 * 60);
    
    hours = remain / (60 * 60);
    
    int remain2 = remain - (hours * 60 * 60);
    
    minutes = remain2 / 60;
    
    int remain3 = remain2 - (minutes * 60);
    
    seconds = remain3;
    
    hundreths = audioPlayer.currentTime - (days *24 * 60 * 60) - (hours * 60 * 60) - (minutes * 60) - (seconds) ;
    
    hours = hours + (days * 24);
    
    audioPosLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d.%d", hours, minutes,seconds, (int)(hundreths * 10.0f)];
}


-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (!processingComplete) {
        return;
    }
    
    if (tag == 0) {
        if (audioPlayer) {
            isPlaying = NO;
            if (audioPlayer.playing) {
                [audioPlayer stop];
                audioPlayer = nil;
            }
            if (audioPlayerView) {
                [self closeAudioPlayer];
            }
        } else {
            [self showAudioPlayer];
        }
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
    
    if (processingComplete) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
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
