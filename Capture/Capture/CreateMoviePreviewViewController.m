//
//  CreateMoviePreviewViewController.m
//  Capture
//
//  Created by Gary Barnett on 9/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CreateMoviePreviewViewController.h"
#import "APLCompositionDebugView.h"
#import "AppDelegate.h"

@interface CreateMoviePreviewViewController () {
    AVAssetExportSession *session;
    AVMutableComposition *composition;
    NSString *outputFilePath;

    AVMutableVideoComposition * videoComp;
    
        //APLCompositionDebugView *debugView;
    BOOL processing;
    BOOL hasProcessed;
    
    __weak IBOutlet UIProgressView *progress;
    __weak IBOutlet UIActivityIndicatorView *activityView;
    __weak IBOutlet UILabel *processingLabel;
    __weak IBOutlet GradientAttributedButton *playButton;
    
    NSString *movieFname;
    AVMutableAudioMix *audioMixer;
    
}

@end

@implementation CreateMoviePreviewViewController

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
    
    session = nil;
    composition = nil;
    outputFilePath = nil;
    audioMixer = nil;
    videoComp = nil;
    
        //APLCompositionDebugView *debugView;
    
    progress = nil;
    activityView = nil;
    processingLabel = nil;
    playButton = nil;
    movieFname = nil;
}

- (IBAction)sliderValueChanged:(id)sender {
}
- (IBAction)userDidTapPlayButton:(id)sender {
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
    playButton.enabled = YES;
    playButton.delegate = self;
    playButton.tag = 0;
    [self updateButton];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];

    self.navigationItem.title = @"Create Movie";
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (tag == 0) {
        [[MovieManager manager] playClipAtPath:movieFname];
    } if (tag == 2000) {
        [self assembleAndSave];
    } else if (tag >=1000) {
        [[SettingsTool settings] setDefaultMovieCreationSize:tag - 1000];
        [self setupMovieSelectionButtonsWithPageSize:self.view.bounds.size];
    }
}


/*
-(void)debugComposition {
    debugView = [[APLCompositionDebugView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:debugView];

    [debugView synchronizeToComposition:composition videoComposition:videoComp audioMix:audioMix];
  

}
*/

-(void)assembleForPreview {
        //NSLog(@"Assembling %@", self.clips);
    composition = [AVMutableComposition composition];
    NSMutableArray *audioMix = [[NSMutableArray alloc] initWithCapacity:3];
    
    NSInteger clipCount = [self.clips count];
    
    CMTime curPos = kCMTimeZero;
    videoComp = [AVMutableVideoComposition videoComposition];
    
    BOOL currentTrackIsA = YES;
    
    CMTime maxPos = kCMTimeZero;
   
    CGSize videoSize = CGSizeZero;
    NSInteger frameRate = 1;
    for (NSInteger x=0;x<clipCount;x++ ) {
        AVAsset *clip = [self.clips objectAtIndex:x];
        
        AVAssetTrack *track = [[clip tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        CGSize trackSize = [track naturalSize];
        if (trackSize.height > videoSize.height) {
            videoSize = trackSize;
        }
        if (track.nominalFrameRate > frameRate) {
            frameRate = track.nominalFrameRate;
        }
        maxPos = CMTimeAdd(maxPos, [clip duration]);
    }
    
    [videoComp setRenderSize:videoSize];
    [videoComp setFrameDuration:CMTimeMake(1, (int)frameRate)];
    
    NSMutableArray *instructions = [[NSMutableArray alloc] initWithCapacity:3];
    
    if ([_audioTracks count] > 0) {
        AVMutableCompositionTrack *audioTrack  = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTime curAudioPos = kCMTimeZero;
        
        for (NSArray *audioArray in _audioTracks) {
            AVAsset *audio = [audioArray objectAtIndex:0];
            if (CMTimeCompare(curAudioPos, maxPos) == NSOrderedDescending) {
                break;
            }
            
            CMTime remainingTime = CMTimeSubtract(maxPos, curAudioPos);
            CMTime timeForThisTrack = [audio duration];
            if (CMTimeCompare(remainingTime, timeForThisTrack) == NSOrderedAscending
                ) {
                timeForThisTrack = remainingTime;
            }
            AVAssetTrack *audioClipTrack = [[audio tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            NSError *audioError = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeForThisTrack) ofTrack:audioClipTrack atTime:curAudioPos error:&audioError];
            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioClipTrack];
            [trackMix setVolumeRampFromStartVolume:0 toEndVolume:1 timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(1, 1))];
            [trackMix setVolume:[[audioArray objectAtIndex:2] floatValue] atTime:kCMTimeZero];
            [audioMix addObject:trackMix];
            curAudioPos = CMTimeAdd(curAudioPos, timeForThisTrack);
            if (audioError) {
                NSLog(@"audioErr:%@", [audioError localizedDescription]);
            }
        }
    }
    
    for (NSInteger x=0;x<clipCount;x++ ) {
        AVAsset *clip = [self.clips objectAtIndex:x];
       
        NSArray *tracksVideo = [clip tracksWithMediaType:AVMediaTypeVideo];
        NSArray *tracksAudio = [clip tracksWithMediaType:AVMediaTypeAudio];
      
        CMTime videoDuration = [[_clipDurations objectAtIndex:x] CMTimeValue];
        
        AVAssetTrack *videoTrack = [tracksVideo objectAtIndex:0];
        
        BOOL hasAudio = YES;
        AVAssetTrack *audioTrack = nil;
        
        if ([tracksAudio count]<1) {
            hasAudio = NO;
        } else {
            audioTrack = [tracksAudio objectAtIndex:0];
        }

        
        NSDictionary *transitionDict = [self.clipTransitionInstructions objectForKey:[NSNumber numberWithInteger:x]];
        
        NSDictionary *prevTransitionDict = nil;
        
        if (x > 0) {
            prevTransitionDict = [self.clipTransitionInstructions objectForKey:[NSNumber numberWithInteger:x-1]];
        }
        
        BOOL fadeIn = NO;
        BOOL fadeOut = NO;
            //BOOL xFadePrev = NO;
        
        if (prevTransitionDict && ([prevTransitionDict objectForKey:@"transition"])) {
            NSInteger prevTransition = [[prevTransitionDict objectForKey:@"transition"] integerValue];
            if (prevTransition == 1) {
                fadeIn = YES;
            } else if (prevTransition == 2) {
                fadeIn = YES;
                    //xFadePrev = YES;
            }
        }
        
        if (transitionDict && ([transitionDict objectForKey:@"transition"])) {
            NSInteger t = [[transitionDict objectForKey:@"transition"] integerValue];
            if (t == 1) {
                fadeOut = YES;
            } else if (t == 2) {
                fadeOut = YES;
            }
        }
    
        NSError *error = nil;
        
        CMTime fadeLength = CMTimeMakeWithSeconds(2, videoComp.frameDuration.timescale);
        if (CMTimeCompare(videoDuration, fadeLength) == NSOrderedDescending) {
            fadeLength = videoDuration;
        }
        
        if (fadeIn && fadeOut) {
            if (CMTimeCompare(videoDuration, CMTimeMake(fadeLength.value *2, fadeLength.timescale)) == NSOrderedAscending) {
                fadeLength = CMTimeMake(videoDuration.value / 2, videoDuration.timescale);
            }
        }
        
        if (clip.duration.timescale == 1) {
            fadeLength = CMTimeMake(1, 2);
        }
       
            //if (xFadePrev) {
            //   curPos = CMTimeSubtract(curPos, fadeLength);
            // }
        
        AVMutableCompositionTrack *vTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *aTrack = nil;
      
        [vTrack setPreferredTransform:videoTrack.preferredTransform];
        
        [vTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoDuration) ofTrack:videoTrack atTime:curPos error:&error];
        
        if (hasAudio) {
            aTrack  = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [aTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoDuration) ofTrack:audioTrack atTime:curPos error:&error];
            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:aTrack];
            [trackMix setVolumeRampFromStartVolume:0 toEndVolume:1 timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(1, 1))];
            
            CGFloat audioLevelForThisPosition = 1.0f;
            
            if ([_audioTracks count] >0) {
                CMTime testPos = kCMTimeZero;
                CMTime endPos = kCMTimeZero;
                for (NSArray *array in _audioTracks) {
                    AVAsset *a = [array objectAtIndex:0];
                    endPos = CMTimeAdd(testPos, [a duration]);
                    CMTimeRange r = CMTimeRangeFromTimeToTime(testPos, endPos);
                    if (CMTimeRangeContainsTime(r, curPos)) {
                        audioLevelForThisPosition = [[array objectAtIndex:1] floatValue];
                        break;
                    }
                }
            }
         
            [trackMix setVolume:audioLevelForThisPosition atTime:kCMTimeZero];
            [audioMix addObject:trackMix];
        }
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:vTrack];
       
        AVMutableVideoCompositionLayerInstruction *layerScale = nil;
        
        CGSize trackSize = [videoTrack naturalSize];
        
        if (trackSize.height < videoSize.height) {
            layerScale = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:vTrack];
            CGAffineTransform transform = CGAffineTransformMakeScale(videoSize.width / trackSize.width, videoSize.height / trackSize.height);
            [layerScale setTransform:transform atTime:kCMTimeZero];
            NSLog(@"track:%ld vs:%@ ts:%@", (long)x, [NSValue valueWithCGSize:videoSize], [NSValue valueWithCGSize:trackSize]);
        }
        
        CMTime clipStart = curPos;
        CMTime clipEnd = CMTimeAdd(clipStart, videoDuration);
        CMTime fadeOutStart = CMTimeSubtract(clipEnd, fadeLength);
        
        if (fadeIn && fadeOut) {
            CMTime endFadeIn = CMTimeAdd(clipStart, fadeLength);
            if (CMTimeCompare(endFadeIn, fadeOutStart) == NSOrderedDescending) {
                CMTime fadeLengthIn = CMTimeMake(videoDuration.value / 2, videoDuration.timescale);
                CMTime fadeLengthOut = CMTimeMake(videoDuration.value - fadeLengthIn.value, videoDuration.timescale);
                 [self setOpacityRampForInstrucion:layerInstruction startOpacity:0.0f endOpacity:1.0f timeRange:CMTimeRangeMake(clipStart, fadeLengthIn)];
                 [self setOpacityRampForInstrucion:layerInstruction startOpacity:1.0 endOpacity:0.0f timeRange:CMTimeRangeMake(CMTimeSubtract(videoDuration, fadeLengthOut), fadeLengthOut)];
            } else {
                [self setOpacityRampForInstrucion:layerInstruction startOpacity:0.0f endOpacity:1.0f timeRange:CMTimeRangeMake(clipStart, fadeLength)];
                [self setOpacityRampForInstrucion:layerInstruction startOpacity:1.0f endOpacity:0.0f timeRange:CMTimeRangeMake(fadeOutStart, fadeLength)];
            }
        } else if (fadeIn) {
            [self setOpacityRampForInstrucion:layerInstruction startOpacity:0.0f endOpacity:1.0f timeRange:CMTimeRangeMake(clipStart, fadeLength)];
        } else if (fadeOut) {
            [self setOpacityRampForInstrucion:layerInstruction startOpacity:1.0f endOpacity:0.0f timeRange:CMTimeRangeMake(fadeOutStart, fadeLength)];
        }
        
        currentTrackIsA = !currentTrackIsA;
        
        instruction.timeRange = CMTimeRangeMake(curPos, videoDuration);
        
        if (layerScale) {
            instruction.layerInstructions = @[ layerInstruction , layerScale ];
        } else {
            instruction.layerInstructions = @[ layerInstruction ];
        }
        
        [instructions addObject:instruction];
        
        curPos = clipEnd;
        
    }
    
    audioMixer = [AVMutableAudioMix audioMix];
    audioMixer.inputParameters = audioMix;
    

    videoComp.instructions = [instructions copy];
}

-(void)setOpacityRampForInstrucion:(AVMutableVideoCompositionLayerInstruction *)ins startOpacity:(CGFloat)startOpacity endOpacity:(CGFloat)endOpacity timeRange:(CMTimeRange)timeRange {
        //NSLog(@"layerins:%f:%f:%@", startOpacity, endOpacity, [NSValue valueWithCMTimeRange:timeRange]);
    [ins setOpacityRampFromStartOpacity:startOpacity toEndOpacity:endOpacity timeRange:timeRange];
}

-(void)updateButton {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    NSAttributedString *sActive = [[NSAttributedString alloc] initWithString:@"Play Movie" attributes:@{
                                                                                                              NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                              NSShadowAttributeName : shadow,
                                                                                                              NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                              }];
    playButton.enabled = YES;
    
    if (!processing) {
        [playButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    } else {
        [playButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    [playButton update];
    
    self.navigationItem.rightBarButtonItem.enabled = (!processing) && hasProcessed;
}

-(void)userTappedCancel {
    if (movieFname) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname] error:&error];
    }
   
    [self performSelector:@selector(cleanup:) withObject:nil afterDelay:0.4];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)userTappedCommit {
    [[UtilityBag bag] makeThumbnail:movieFname];
    [[AssetManager manager] cleanupMoviePhotosTemp];
    [[UtilityBag bag] logEvent:@"makeMovie" withParameters:nil];
    
    [self performSelector:@selector(cleanup:) withObject:nil afterDelay:0.4];
    
    UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-4];
    [self.navigationController popToViewController:vc animated:YES];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setupMovieSelectionButtonsWithPageSize:(CGSize)pageSize {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    NSInteger movieCreationSize = [[SettingsTool settings] defaultMovieCreationSize];
   
    CGFloat middle = (pageSize.height / 2.0f) - 25;
    CGFloat buttonwidth = 100;
  
    for (NSInteger x=0;x<4;x++) {
        NSString *title = @"";
        NSString *bColorStr = (x == movieCreationSize) ? @"#009900" : @"#CCCCCC";
        NSString *eColorStr = (x == movieCreationSize) ? @"#006600" : @"#999999";
        
        CGFloat spacing = (pageSize.width / 5.0f);
        CGRect pos = CGRectMake((spacing * (x+1)) - (buttonwidth / 2.0f), middle, buttonwidth, 50);
        BOOL disabled = NO;
        switch (x) {
            case 0: {
                title = @"1920x1080";
                if ([[SettingsTool settings] isOldDevice]) {
                    disabled = YES;
                }
            }
                break;
            case 1:  {
                title = @"1280x720";
            }
                break;
            case 2: {
                title = @"960x540";
            }
                break;
            case 3:  {
                title = @"Smallest";
            }
                break;
        }
        
        if (disabled) {
            bColorStr = @"#333333";
            eColorStr = @"#111111";
        }
        
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:title attributes:@{
                                                                                                         NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                         NSShadowAttributeName : shadow,
                                                                                                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                         }];
        
        GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:pos];
        [button setTitle:attrStr disabledTitle:attrStr beginGradientColorString:bColorStr endGradientColor:eColorStr];
        button.enabled = !disabled;
        button.delegate = self;
        button.tag = 1000 + x;
        [button update];
        [self.view addSubview:button];
    }
    
    NSAttributedString *attrStr2 = [[NSAttributedString alloc] initWithString:@"Start" attributes:@{
                                                                                                NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                NSShadowAttributeName : shadow,
                                                                                                NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                }];

    buttonwidth = 140;
    GradientAttributedButton *button2 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake((pageSize.width / 2.0f) - (buttonwidth /2.0f), middle + 100, buttonwidth, 75)];
    [button2 setTitle:attrStr2 disabledTitle:attrStr2 beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    button2.enabled = YES;
    button2.delegate = self;
    button2.tag = 2000;
    [button2 update];
    [self.view addSubview:button2];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,middle- 100, pageSize.width, 50)];
    l.text = @"Select Size For Movie";
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont boldSystemFontOfSize:20];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor whiteColor];
    l.tag = 3000;
    [self.view addSubview:l];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration  {
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        return;
    }
    
    if (processing || hasProcessed) {
        return;
    }
    
    NSMutableArray *list = [self.view.subviews mutableCopy];
    for (UIView *l in list) {
        if (l.tag >= 1000) {
            [l removeFromSuperview];
        }
    }
    
    [self setupMovieSelectionButtonsWithPageSize:UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? CGSizeMake(1024,768) : CGSizeMake(768,1024)];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateButton];
    playButton.alpha = 1.0f;
    playButton.hidden = YES;
    progress.hidden = YES;
    processingLabel.hidden = YES;
    activityView.hidden = YES;
    [activityView stopAnimating];
    
    [self setupMovieSelectionButtonsWithPageSize:self.view.bounds.size];
}

-(void)assembleAndSave {
    NSMutableArray *list = [self.view.subviews mutableCopy];
    for (UIView *l in list) {
        if (l.tag >= 1000) {
            [l removeFromSuperview];
        }
    }

    playButton.hidden = NO;
    progress.hidden = NO;
    processingLabel.hidden = NO;
    activityView.hidden = NO;
    [activityView startAnimating];
    [[UtilityBag bag] startTimingOperation];
    [self assembleForPreview];
    [self performSelector:@selector(saveComposition) withObject:nil afterDelay:0.01f];
}

-(void)updateProgress {
    if (processing) {
        progress.progress = session.progress;
        processingLabel.text = [[UtilityBag bag] returnRemainingTimeForOperationWithProgress:progress.progress];
        [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.5];
    }
}

-(void)saveComposition {
	
    if (processing) {
        return;
    }

    [UIApplication sharedApplication].idleTimerDisabled = YES;
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = NO;
    processing = YES;
    
    [self updateButton];
    
    [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.5];
   
    movieFname =[[UtilityBag bag] pathForNewResourceWithExtension:@"mov"];
    
    outputFilePath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname];

    NSString *preset = AVAssetExportPreset1280x720;

    switch ([[SettingsTool settings] defaultMovieCreationSize]) {
        case  0:
            preset = AVAssetExportPreset1920x1080;
            if ([[SettingsTool settings] isOldDevice]) {
                preset = AVAssetExportPreset1280x720;
            }
            break;
        case  1:
            preset = AVAssetExportPreset1280x720;
            break;
        case  2:
            preset = AVAssetExportPreset960x540;
            break;
        case  3:
            preset = AVAssetExportPresetLowQuality;
            break;
    }
    
	session = [[AVAssetExportSession alloc] initWithAsset:[composition copy] presetName:preset];

	session.audioMix = [audioMixer copy];
	session.outputURL = [NSURL fileURLWithPath:outputFilePath];
	session.outputFileType=AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComp;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *originalTimeStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableArray *metadata = [[NSMutableArray alloc] initWithCapacity:3];
    
    AVMutableMetadataItem *item = nil;
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.key = AVMetadataCommonKeyCreationDate;
    item.value = originalTimeStr;
    [metadata addObject:item];
    
    if ([[SettingsTool settings] useGPS]) {
        CLLocation *location = [LocationHandler tool].location;
        NSString *locationString = [NSString stringWithFormat:@"%+08.4lf,%+09.4lf/", location.coordinate.latitude, location.coordinate.longitude];
        item = [[AVMutableMetadataItem alloc] init];
        item.keySpace = AVMetadataKeySpaceCommon;
        item.key = AVMetadataCommonKeyLocation;
        item.value = locationString;
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
    item.value = @"Created Movie";
    [metadata addObject:item];
    
    
    AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
    [metadata addObject:descUID];
    
    session.metadata = [metadata copy];

	[session exportAsynchronouslyWithCompletionHandler:^(void){
        [UIApplication sharedApplication].idleTimerDisabled = NO;
		switch (session.status) {
			case AVAssetExportSessionStatusCompleted:
            {
                    //NSLog(@"Completed:%@",session.error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    processingLabel.text = @"Complete";
                    progress.progress = 1.0f;
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                    [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
                });
            }
                break;
			case AVAssetExportSessionStatusFailed:
            {
                NSLog(@"Failed:%@",session.error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    processingLabel.text = @"Failed";
                });
			}
                break;
			case AVAssetExportSessionStatusCancelled:
                    //NSLog(@"Canceled:%@",session.error);
				break;
			default:
				break;
		}
        dispatch_async(dispatch_get_main_queue(), ^{
            processing = NO;
            hasProcessed = YES;
            [activityView stopAnimating];
            [self updateButton];
        });
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingInvalidValueForKey:(NSString *)key {
    NSLog(@"shouldContinueValidatingAfterFindingInvalidValueForKey:%@", key);
    return YES;
}

- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingEmptyTimeRange:(CMTimeRange)timeRange {
    NSLog(@"shouldContinueValidatingAfterFindingEmptyTimeRange:%@", [NSValue valueWithCMTimeRange:timeRange]);
    return YES;
}

- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingInvalidTimeRangeInInstruction:(id<AVVideoCompositionInstruction>)videoCompositionInstruction  {
    NSLog(@"shouldContinueValidatingAfterFindingInvalidTimeRangeInInstruction:%@", videoCompositionInstruction);
    return YES;
}

- (BOOL)videoComposition:(AVVideoComposition *)videoComposition shouldContinueValidatingAfterFindingInvalidTrackIDInInstruction:(id<AVVideoCompositionInstruction>)videoCompositionInstruction layerInstruction:(AVVideoCompositionLayerInstruction *)layerInstruction asset:(AVAsset *)asset {
    NSLog(@"shouldContinueValidatingAfterFindingInvalidTrackIDInInstruction:%@:%@:%@", videoCompositionInstruction, layerInstruction, asset);
    return YES;
}


@end
