//
//  AudioCaptureViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/21/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioCaptureViewController.h"
#import "EngineViewController.h"
#import "AppDelegate.h"
#import "GenerateSilentTrackViewController.h"
#import "AudioSoundsViewController.h"

@interface AudioCaptureViewController () {
    NSString *recorderFilePath;
    BOOL recorderSetup;
    BOOL recording;
    NSTimer *updateTimer;
    int elapsed;
  
    
    AVCaptureSession *session;
    AVCaptureDeviceInput *audioDeviceInput;
    AVCaptureDevice *audioDevice;
    dispatch_queue_t _captureSessionQueue;
    AVCaptureAudioDataOutput *audioDataOutput;
    
    AVAssetWriter *assetWriter;
    AVAssetWriterInput *assetWriterAudioInput;

    CMFormatDescriptionRef _currentAudioSampleBufferFormatDescription;
    
    BOOL firstFrameCompleted;
    __weak IBOutlet UILabel *readyLabel;
    BOOL editingSettings;
    
    AVAudioPlayer *beepPlayer;
    NSDate *startTime;
    AudioLevelView *audioL;
    AudioLevelView *audioR;
    UILabel *signalLabel;

}

@end

@implementation AudioCaptureViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    //NSLog(@"%@:%s", [self class], __func__);
    
    _captureSessionQueue = nil;
    recorderFilePath = nil;
    updateTimer = nil;
    session = nil;
    audioDeviceInput = nil;
    audioDevice = nil;
    _captureSessionQueue = nil;
    audioDataOutput = nil;
    
    if (_currentAudioSampleBufferFormatDescription) {
        CFRelease(_currentAudioSampleBufferFormatDescription);
        _currentAudioSampleBufferFormatDescription = nil;
    }
    
    readyLabel = nil;
    beepPlayer = nil;
    assetWriter = nil;
    assetWriterAudioInput = nil;
    startTime = nil;
}

-(void)cleanup:(NSNotification *)n {
    

    
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
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanupAudioRecorder" object:nil];
    readyLabel.text = @"Loading Recorder";
    self.navigationItem.title = @"Record Audio";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(startRecording)];
    
    audioL.backgroundColor = [UIColor clearColor];
    audioL.isLeft = YES;
    
    audioR.backgroundColor = [UIColor clearColor];
    audioR.isLeft = NO;
    
    [[AudioManager manager] playbackMode:NO];
    [[AudioManager manager] updateAudioUnit];
    
    NSError *error = nil;
    NSString *audioStr = [[NSBundle mainBundle] pathForResource:@"beep-7" ofType:@"wav"];
    NSURL *audioURL = [NSURL fileURLWithPath:audioStr];
    beepPlayer = [[AVAudioPlayer alloc]  initWithContentsOfURL:audioURL error:&error];
    beepPlayer.volume = 0.15;
    [beepPlayer prepareToPlay];

    self.navigationItem.title = @"Audio Recorder";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateTimerEvent {
    if (recorderSetup) {
        NSArray *connections = audioDataOutput.connections;
        if ([connections count] > 0) {
            AVCaptureConnection *connection = [connections objectAtIndex:0];
            
            NSArray *audioChannels = connection.audioChannels;
            AVCaptureAudioChannel *channel = [audioChannels objectAtIndex:0];
                // float avg = channel.averagePowerLevel;
            float peak = channel.peakHoldLevel;
            
            [audioL updateValue:  pow (10., 0.05 * peak) ];
            if ([audioChannels count]>1) {
                AVCaptureAudioChannel *channel = [audioChannels objectAtIndex:0];
                    //  float avg = channel.averagePowerLevel;
                float peak = channel.peakHoldLevel;
                [audioR updateValue: pow (10., 0.05 * peak)  ];
            } else {
                [audioR noDataForThisTrack];
            }
        }
        if (assetWriter) {
            readyLabel.text = [[UtilityBag bag] durationStr:[[NSDate date] timeIntervalSinceDate:startTime  ]];
        }
    }

}

-(void)viewDidAppear:(BOOL)animated  {
    [super viewDidAppear:animated];
    
    [self startRecorder];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    editingSettings = NO;
    
    if (!session) {
        [self startRecorder];
    }
    
    self.navigationController.toolbarHidden = NO;
    self.toolbarItems = @[ [[UIBarButtonItem alloc] initWithTitle:@"Audio Settings" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedOptions)],
                         ];
    
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = NO;
  
}


-(void)userTappedOptions {
    editingSettings = YES;
    EngineViewController *vc = [[EngineViewController alloc] initWithNibName:@"EngineViewController" bundle:nil];
    vc.audioControlsOnly = YES;
    [self.navigationController pushViewController:vc animated:YES];

}


-(void)unableToRecord {
    NSLog(@"Unable to record");
}

-(void)stopRecorder {
    if (!recorderSetup) {
        return;
    }
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    
    [session stopRunning];
    [session removeInput:audioDeviceInput];
    [session removeOutput:audioDataOutput];
    
    session = nil;
    audioDeviceInput = nil;
    audioDevice = nil;

    audioDataOutput = nil;
    _captureSessionQueue = nil;
    recorderSetup = NO;

}

-(void)startRecorder {
    NSString *model = [[UIDevice currentDevice] model];
    if (YES == [model isEqualToString:@"iPhone Simulator"]) {
        return;
    }
    
    if (recorderSetup) {
        return;
    }

    if (!updateTimer) {
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimerEvent) userInfo:nil repeats:YES];
    }
    NSError *error = nil;
    
    audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    if (audioDevice) {
        audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];

        if (!audioDeviceInput)
        {
            [self unableToRecord];
            return;
        }
    } else {
        [self unableToRecord];
        return;
    }
    
    audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    if (!_captureSessionQueue) {
        _captureSessionQueue = dispatch_queue_create("capture_session_queue", NULL);
    }
    
    [audioDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
    
    session = [[AVCaptureSession alloc] init];

    [session beginConfiguration];
    
    if (audioDevice && audioDeviceInput)
    {
        [session addInput:audioDeviceInput];
        [session addOutput:audioDataOutput];
    }
    
    [session commitConfiguration];
    
    [session startRunning];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    recorderSetup = YES;
    readyLabel.text = @"Ready";
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if (mediaType == kCMMediaType_Audio)
    {
        CMFormatDescriptionRef tmpDesc = _currentAudioSampleBufferFormatDescription;
        _currentAudioSampleBufferFormatDescription = formatDesc;
        CFRetain(_currentAudioSampleBufferFormatDescription);
        
        
        
        if (tmpDesc)
            CFRelease(tmpDesc);
        
        if (assetWriter && (!firstFrameCompleted)) {
            firstFrameCompleted = YES;
            [assetWriter startSessionAtSourceTime:timestamp];
        }
        
        if (assetWriter &&  assetWriterAudioInput.readyForMoreMediaData && ![assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
            NSLog(@"Cannot write audio data, recording aborted");
            [self unableToRecord];
        }
    }

}

-(void)stopRecording {
    if (!assetWriter) {
        return;
    }
    
    [[UtilityBag bag] logEventEnd:@"audioRecording" withParameters:nil];
    
    UIBarButtonItem *optionsButton =[self.toolbarItems objectAtIndex:0];
    optionsButton.enabled = YES;
    
    AVAssetWriter *writer = assetWriter;
    
    assetWriterAudioInput = nil;
    assetWriter = nil;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    dispatch_async(_captureSessionQueue, ^(void){
        
        [writer finishWritingWithCompletionHandler:^(void){
            if (writer.status == AVAssetWriterStatusFailed)
            {
                NSLog(@"Cannot complete writing the audio file, the output could be corrupt.");
                [self unableToRecord];
            }
            else if (writer.status == AVAssetWriterStatusCompleted)
            {
                NSLog(@"recording completed");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishedRecording];
            });
        }];
        
    });
    
    
}

-(void)finishUpdatingLabel {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    readyLabel.text = @"Ready";
}

-(void)finishedRecording {

    NSLog(@"Finished recording:%@", recorderFilePath);
    recorderFilePath = nil;
    readyLabel.text = @"Finished Recording";
    self.navigationItem.rightBarButtonItem.title = @"Start";
    [self performSelector:@selector(finishUpdatingLabel) withObject:nil afterDelay:2.0f];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)viewDidDisappear:(BOOL)animated {
    if (!editingSettings) {
        [self stopRecorder];
        AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appD.allowRotation = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAudioLibraryAndReload" object:nil];
        
    }
    [super viewDidDisappear:animated];
}

-(void)startRecording {
    if (assetWriter) {
        [self stopRecording];
        return;
    }
    
    [[UtilityBag bag] logEvent:@"audioRecording" withParameters:nil];
    [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
    
    startTime = [NSDate date];
    self.navigationItem.rightBarButtonItem.title = @"Stop";
    UIBarButtonItem *optionsButton =[self.toolbarItems objectAtIndex:0];
    optionsButton.enabled = NO;
    
    [beepPlayer play];
    [self performSelector:@selector(startRecording2) withObject:nil afterDelay:0.5];
}

-(void)startRecording2 {
    readyLabel.text = @"Recording";
    dispatch_async(_captureSessionQueue, ^{
        NSError *error = nil;
        NSString *fType = nil;
        
        if ([[SettingsTool settings] audioOutputEncodingIsAAC]) {
            recorderFilePath = [[UtilityBag bag] pathForNewResourceWithExtension:@"m4a"];
            fType = AVFileTypeAppleM4A;
        } else {
            recorderFilePath = [[UtilityBag bag] pathForNewResourceWithExtension:@"wav"];
            fType = AVFileTypeWAVE;
        }
        
        NSString *fpath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:recorderFilePath];
        
        AVAssetWriter *newAssetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:fpath] fileType:fType error:&error];
        
        if (!newAssetWriter || error) {
            [self unableToRecord];
            return;
        }
        
        if (audioDevice) {
            NSDictionary *audioOutputSettings = [self audioDictForCurrentSetup];
            if ([newAssetWriter canApplyOutputSettings:audioOutputSettings forMediaType:AVMediaTypeAudio]) {
                assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
                assetWriterAudioInput.expectsMediaDataInRealTime = YES;
                
                if ([newAssetWriter canAddInput:assetWriterAudioInput]) {
                    [newAssetWriter addInput:assetWriterAudioInput];
                } else {
                    NSLog(@"Couldn't add asset writer audio input");
                    [self unableToRecord];
                    return;
                }
            } else {
                NSLog(@"Couldn't apply audio output settings.");
                [self unableToRecord];
                return;
            }
        }
        
        assetWriter = newAssetWriter;
        firstFrameCompleted = NO;
        [assetWriter startWriting];
    });
    
}

-(NSDictionary *)audioDictForCurrentSetup {
    size_t layoutSize = 0;
    const AudioChannelLayout *channelLayout = CMAudioFormatDescriptionGetChannelLayout(_currentAudioSampleBufferFormatDescription, &layoutSize);
    const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(_currentAudioSampleBufferFormatDescription);
    
    NSData *channelLayoutData = [NSData dataWithBytes:channelLayout length:layoutSize];
 
    NSDictionary *dict = nil;

    if ([[SettingsTool settings] audioOutputEncodingIsAAC]) {
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                [NSNumber numberWithInteger:basicDescription->mChannelsPerFrame], AVNumberOfChannelsKey,
                [NSNumber numberWithFloat:basicDescription->mSampleRate], AVSampleRateKey,
                channelLayoutData, AVChannelLayoutKey
                , nil];
        
    } else {
        dict = [ NSDictionary dictionaryWithObjectsAndKeys:
                [ NSNumber numberWithInt:kAudioFormatLinearPCM] , AVFormatIDKey ,
                [NSNumber numberWithInteger:basicDescription->mChannelsPerFrame], AVNumberOfChannelsKey,
                [NSNumber numberWithFloat:basicDescription->mSampleRate], AVSampleRateKey,
                [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                [NSNumber numberWithBool:NO] , AVLinearPCMIsFloatKey ,
                [NSNumber numberWithBool:NO] , AVLinearPCMIsNonInterleaved ,
                [NSNumber numberWithBool:NO] , AVLinearPCMIsBigEndianKey ,
                channelLayoutData, AVChannelLayoutKey
                , nil];
    }
    
    return dict;
}

-(NSArray *)updateMetadataForAssetWriter:(NSArray *)metadataIn {
    NSMutableArray *metadata = [metadataIn mutableCopy];
    
    if (!metadata ) {
        metadata = [[NSMutableArray alloc] initWithCapacity:3];
    }
    
    AVMutableMetadataItem *item = nil;
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.key = AVMetadataCommonKeyCreationDate;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
    item.value = [dateFormatter stringFromDate:[NSDate date]];
    [metadata addObject:item];
    
    if ([[SettingsTool settings] useGPS] && [[SettingsTool settings] clipRecordLocation]) {
        CLLocation *location = [LocationHandler tool].location;
        NSString *locationString = [NSString stringWithFormat:@"%+08.4lf,%+09.4lf", location.coordinate.latitude, location.coordinate.longitude];
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
    
    NSString *clipTitle =  [NSString stringWithFormat:@"Audio Recording #%ld", (long)[[SettingsTool settings] nextClipSequenceNumber]];
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.locale = [NSLocale currentLocale];
    item.key = AVMetadataCommonKeyTitle;
    item.value = clipTitle;
    [metadata addObject:item];
    
    AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
    [metadata addObject:descUID];
    
    NSArray *metadataOut = [metadata copy];
    
    return metadataOut;
}

-(void)userTappedSilentTrack {
    GenerateSilentTrackViewController *vc = [[GenerateSilentTrackViewController alloc] initWithNibName:@"GenerateSilentTrackViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
