//
//  FilterClipConfirmViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/1/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "FilterClipConfirmViewController.h"
#import "MovieManager.h"
#import <GPUImage/GPUImage.h>
#import "FilterClipTool2.h"
#import "AppDelegate.h"

@interface FilterClipConfirmViewController () {
    __weak IBOutlet UIProgressView *progress;
    __weak IBOutlet UIActivityIndicatorView *activityView;
    __weak IBOutlet UILabel *processingLabel;
 
    AVAssetWriter *videoWriter;
    
    AVAssetReader *reader;
    AVAssetReader *audioReader;
    
    dispatch_queue_t _processingQueue;
    
    NSString *moviePath;

    BOOL videoComplete;
    BOOL audioComplete;

    FilterClipTool2 *filterClipTool;
    
    NSInteger totalSeconds;
    CMTime duration;
    
    BOOL cancelWriting;
    BOOL hasAudio;
}

@end

@implementation FilterClipConfirmViewController

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
    videoWriter = nil;
    reader = nil;
    audioReader = nil;
    _processingQueue = nil;
    moviePath = nil;
    filterClipTool = nil;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timingUpdate:) name:@"movieRenderedAtTimestamp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishRecordingFilterMovie:) name:@"finishRecordingFilterMovie" object:nil];
    
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = @"Process Clip";
    self.navigationItem.rightBarButtonItem = nil;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];
}

-(void)userTappedCancel {
    cancelWriting = YES;
    [reader performSelector:@selector(cancelReading) withObject:nil afterDelay:0.25f];
    [videoWriter performSelector:@selector(cancelWriting) withObject:nil afterDelay:0.50f];
    [self performSelector:@selector(cleanupTool) withObject:nil afterDelay:0.75f];
    [self performSelector:@selector(popNav) withObject:nil afterDelay:1.0f];
}

-(void)cleanupTool {
    [filterClipTool shutdown];
    filterClipTool = nil;
}

-(void)popNav {
    UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 2];
    [self.navigationController popToViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UtilityBag bag] startTimingOperation];
    [self performSelector:@selector(cutClip) withObject:nil afterDelay:0.1];
}



-(void)cutClip {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = NO;
    filterClipTool = [[FilterClipTool2 alloc] init];
    filterClipTool.cutList = self.cutList;
    filterClipTool.clip = self.clip;
    [filterClipTool setup];
    duration = [self.clip duration];
    totalSeconds = CMTimeGetSeconds(duration);
    
    moviePath =[[UtilityBag bag] pathForNewResourceWithExtension:@"mov"];
    NSString *filePath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:moviePath];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];

    NSError *error = nil;
    NSError *aerror = nil;
    
    AVURLAsset *avAsset = self.clip;
    reader = [[AVAssetReader alloc] initWithAsset:avAsset error:&aerror];
    AVAssetTrack *videoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    CGSize frameSize = [videoTrack naturalSize];
    NSLog(@"naturalSize:%@", [NSValue valueWithCGSize:frameSize]);
    videoWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    float dataRate = 0.0f;
    
    AVOutputSettingsAssistant *settingsAssistant = [AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset1280x720];
  
    switch ([@(frameSize.height) integerValue]) {
        case 1080:
            dataRate = [[SettingsTool settings]  videoCameraVideoDataRate1080];
            settingsAssistant =[AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset1920x1080];
            break;
        case 720:
            dataRate = [[SettingsTool settings]  videoCameraVideoDataRate720];
            settingsAssistant =[AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset1280x720];
            break;
        case 576:
            dataRate = [[SettingsTool settings]  videoCameraVideoDataRate576];
            settingsAssistant =[AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset1280x720];
            break;
        case 540:
            dataRate = [[SettingsTool settings]  videoCameraVideoDataRate540];
            settingsAssistant =[AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset960x540];
            break;
        case 480:
            dataRate = [[SettingsTool settings]  videoCameraVideoDataRate480];
            settingsAssistant =[AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset960x540];
            break;
        case 360:
            dataRate = [[SettingsTool settings]  videoCameraVideoDataRate360];
            settingsAssistant =[AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset960x540];
            break;
    }

    NSMutableDictionary *avOutputDict = nil;

    if (dataRate > 0.0f) {
        avOutputDict = [settingsAssistant.videoSettings mutableCopy];
        NSMutableDictionary *videoCompressionSettings = [[settingsAssistant.videoSettings objectForKey:AVVideoCompressionPropertiesKey] mutableCopy];
        [videoCompressionSettings setObject:[NSNumber numberWithInteger:(NSInteger)dataRate] forKey:AVVideoAverageBitRateKey];
        [avOutputDict setObject:[videoCompressionSettings copy] forKey:AVVideoCompressionPropertiesKey];
        [avOutputDict setObject:[NSNumber numberWithInt:frameSize.width] forKey:AVVideoWidthKey];
        [avOutputDict setObject:[NSNumber numberWithInt:frameSize.height] forKey:AVVideoHeightKey];
    } else {
        avOutputDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                         nil] mutableCopy];
    }
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[avOutputDict copy]];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = NO;
    [videoWriter addInput:videoWriterInput];
    videoWriterInput.transform = videoTrack.preferredTransform;
    
    NSDictionary *videoOptions = @{
                                   (id)kCVPixelBufferWidthKey :[NSNumber numberWithUnsignedInteger:frameSize.width],
                                   (id)kCVPixelBufferHeightKey : [NSNumber numberWithUnsignedInteger:frameSize.height],
                                   (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                   };
    AVAssetReaderTrackOutput *asset_reader_output = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoOptions];
    [reader addOutput:asset_reader_output];

    AVAssetWriterInput* audioWriterInput = nil;
    AVAssetTrack* audioTrack = nil;
    AVAssetReaderOutput *readerOutput = nil;
    hasAudio = NO;
    if ([[avAsset tracksWithMediaType:AVMediaTypeAudio] count]>0) {
        hasAudio = YES;
        audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
        audioReader = [AVAssetReader assetReaderWithAsset:avAsset error:&error];

        audioTrack = [[avAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        readerOutput =  [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        [audioReader addOutput:readerOutput];
        NSParameterAssert(audioWriterInput);
        
        NSParameterAssert([videoWriter canAddInput:audioWriterInput]);
        audioWriterInput.expectsMediaDataInRealTime = NO;
        [videoWriter addInput:audioWriterInput];

    }
   
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    [reader startReading];
    [audioReader startReading];

    _processingQueue = dispatch_queue_create("assetAudioWriterQueue", NULL);

    if (audioTrack) {
        [audioWriterInput requestMediaDataWhenReadyOnQueue:_processingQueue usingBlock:^
         {
             while (audioWriterInput.readyForMoreMediaData) {
                 CMSampleBufferRef nextBuffer;
                 if ([audioReader status] == AVAssetReaderStatusReading &&
                     (nextBuffer = [readerOutput copyNextSampleBuffer])) {
                     if (nextBuffer) {
                         [audioWriterInput appendSampleBuffer:nextBuffer];
                         CFRelease(nextBuffer);
                     }
                 }else{
                     [audioWriterInput markAsFinished];
                     switch ([audioReader status]) {
                         case AVAssetReaderStatusCompleted:
                             audioComplete = YES;
                             if (videoComplete)  {
                                 [videoWriter finishWritingWithCompletionHandler:^{
                                 }];
                             }
                             
                             [self handleComplete];
                             break;
                     }
                 }
             }
             
         }
         ];
    }
    
    [videoWriterInput requestMediaDataWhenReadyOnQueue:_processingQueue usingBlock:
     ^{
         while ([videoWriterInput isReadyForMoreMediaData]) {
             CMSampleBufferRef sampleBuffer;
             if ([reader status] == AVAssetReaderStatusReading &&
                 (sampleBuffer = [asset_reader_output copyNextSampleBuffer])) {
                 
                 CMTime timestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
                 
                 [filterClipTool filterSampleBuffer:sampleBuffer frameSize:frameSize timestamp:timestamp];
                 
                 NSInteger left = CMTimeGetSeconds(CMTimeSubtract(duration, timestamp));
                 CGFloat perc = 1.0 - ((float)left / (float)totalSeconds);
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     progress.progress = perc;
                     processingLabel.text = [[UtilityBag bag] returnRemainingTimeForOperationWithProgress:perc];
                 });

                 BOOL result = [videoWriterInput appendSampleBuffer:sampleBuffer];
                 CFRelease(sampleBuffer);
                 
                 if (!result) {
                     [reader cancelReading];
                     break;
                 }
                           } else {
                 [videoWriterInput markAsFinished];
                 
                 switch ([reader status]) {
                     case AVAssetReaderStatusReading:
                             // the reader has more for other tracks, even if this one is done
                         break;
                         
                     case AVAssetReaderStatusCompleted:
                     {
                         videoComplete = YES;
                         if (audioComplete || (!audioTrack) )  {
                             [videoWriter finishWritingWithCompletionHandler:^{
                             }];
                         }
                         
                         [self handleComplete];
                        
                     }
                         break;
                         
                     case AVAssetReaderStatusFailed:
                         [videoWriter cancelWriting];
                         [filterClipTool shutdown];
                         filterClipTool = nil;
                         break;
                 }
                 
                 break;
             }
         }
     }
     ];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)handleComplete {
    if (videoComplete && (audioComplete || (!hasAudio)) ) {
        [filterClipTool shutdown];
        filterClipTool = nil;
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            audioReader = nil;
            videoWriter = nil;
            reader = nil;
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [[UtilityBag bag] makeThumbnail:moviePath];
            [[UtilityBag bag] logEvent:@"filterVideo" withParameters:nil];
            [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
            UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 3];
            [self.navigationController popToViewController:vc animated:YES];
        });
    }
}


/*
 
 
 
 -(void)stopProgressIndicators {
 progress.hidden = YES;
 statusLabel.hidden = YES;
 [progressTimer invalidate];
 progressTimer = nil;
 [activityView stopAnimating];
 
 }
 __strong AVComposition *composition;
 AVAssetExportSession *exporter;
 AVMutableVideoComposition *videoComp;
 APLCompositionDebugView *debugView;
 
 #import "APLCompositionDebugView.h"
 #import "GPUVIdeoCompositionInstruction.h"
 #import "GPUVideoCompositor.h"

 
 -(void)cutClip {
 AVMutableComposition *mutableComposition = [AVMutableComposition composition];
 
 NSError *editError;
 CMTime begin = kCMTimeZero;
 
 AVMutableCompositionTrack *videoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
 AVMutableCompositionTrack *audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
 
 AVAssetTrack *clipVideoTrack = [[_clip tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
 AVAssetTrack *clipAudioTrack = [[_clip tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
 
 BOOL error = NO;
 
 [videoTrack insertTimeRange:CMTimeRangeMake(begin, _clip.duration) ofTrack:clipVideoTrack atTime:begin error:&editError];
 
 if (editError) {
 error = YES;
 }
 
 [audioTrack insertTimeRange:CMTimeRangeMake(begin, _clip.duration) ofTrack:clipAudioTrack atTime:begin error:&editError];
 
 if (editError) {
 error = YES;
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
 
 videoComp = [AVMutableVideoComposition videoComposition];
 
 CGSize videoSize = CGSizeZero;
 NSInteger frameRate = 1;
 
 CGSize trackSize = [videoTrack naturalSize];
 if (trackSize.height > videoSize.height) {
 videoSize = trackSize;
 }
 
 if (videoTrack.nominalFrameRate > frameRate) {
 frameRate = videoTrack.nominalFrameRate;
 }
 
 [videoComp setRenderSize:videoSize];
 [videoComp setFrameDuration:CMTimeMake(1, (int)frameRate)];
 
 [videoComp setCustomVideoCompositorClass:[GPUVideoCompositor class]];
 
 GPUVIdeoCompositionInstruction *instruction = [[GPUVIdeoCompositionInstruction alloc] init];
 [instruction setTimeRange:CMTimeRangeMake(begin, self.clip.duration)];
 
 videoComp.instructions = @[ instruction ];
 
 [videoComp isValidForAsset:self.clip timeRange:CMTimeRangeMake(begin, _clip.duration) validationDelegate:self];
 
 composition  = [mutableComposition copy];
 
 movieFname = [[UtilityBag bag] pathForNewResourceWithExtension:@"mov"];
 NSString *newMovieFile = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:movieFname];
 movieURL = [NSURL fileURLWithPath:newMovieFile];
 
 if (videoComp.renderSize.width == 1920.0f) {
 exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset1920x1080];
 } else if (videoComp.renderSize.width == 1280.0f) {
 exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset1280x720];
 } else if (videoComp.renderSize.width == 960.0f) {
 exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset960x540];
 } else {
 exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
 }
 
 
 
 [self debugComposition];
 
 
 exporter.outputFileType=AVFileTypeQuickTimeMovie;
 exporter.outputURL=movieURL;
 exporter.videoComposition = [videoComp copy];
 
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
 item.value = [NSString stringWithFormat:@"%@[cut]", originalTitle];
 [metadata addObject:item];
 
 
 AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
 [metadata addObject:descUID];
 
 exporter.metadata = [metadata copy];
 
 exporter.timeRange=CMTimeRangeMake(begin, composition.duration);
 
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
 NSLog(@"Export complete");
 processingLabel.text = @"Complete";
 [self performSelectorOnMainThread:@selector(enablePlayButton) withObject:nil waitUntilDone:NO];
 }
 }
 }];
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


-(void)debugComposition {
    debugView = [[APLCompositionDebugView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:debugView];
    
    [debugView synchronizeToComposition:composition videoComposition:videoComp audioMix:nil];
    
    
}
 */

@end
