//
//  VideoCaptureViewController.m
//  Cloud Capture
//
//  Created by Gary Barnett on 9/1/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//  Core Image Pipeline

#import "VideoCaptureView.h"
#import "AppDelegate.h"
#import "AudioManager.h"
#import "FocusReticleView.h"
#import "ExposureReticleView.h"
#import "GuidePane.h"
#import "UtilityBag.h"
#import "FrameRateCalculator.h"
#import "FilterTool.h"
#import <Accelerate/Accelerate.h>
#import "HistogramView.h"
#import <ImageIO/ImageIO.h>
#import <CoreVideo/CoreVideo.h>
#import <MobileCoreServices/MobileCoreServices.h>


static CGColorSpaceRef sDeviceRgbColorSpace = NULL;

@interface VideoCaptureView () {
    NSTimer *updateTimer;
    
    NSInteger elapsed;

    __strong AVAudioPlayer *beepPlayer;
    AVAudioPlayer *shutterPlayer;
    
    UIDynamicAnimator *busyAnimator;
    UIView *busyView;

    GuidePane *guidePane;
    
    NSTimer *reticleTimer;
    CGPoint lastExposureReticlePos;
    CGPoint lastFocusReticlePos;
    
    CGPoint newExposureReticlePos;
    CGPoint newFocusReticlePos;
    
    GLKView *_videoPreviewView;
    CIContext *_ciContext;
    EAGLContext *_eaglContext;
    CGRect _videoPreviewViewBounds;
    
    AVCaptureDevice *_audioDevice;
    AVCaptureDevice *_videoDevice;
    AVCaptureSession *_captureSession;
    
    AVCaptureStillImageOutput *stillImageOutput;
    
    AVCaptureVideoPreviewLayer *previewLayer;
    UIView *videoPreviewOld;
    AVCaptureMovieFileOutput *movieFile;
    
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWriterAudioInput;
    AVAssetWriterInput *_assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterInputPixelBufferAdaptor;
    
    dispatch_queue_t _captureSessionQueue;
    UIBackgroundTaskIdentifier _backgroundRecordingID;
    
    FilterTool *filterTool;
    
    BOOL _videoWritingStarted;
    CMTime _videoWritingStartTime;
    
    CMFormatDescriptionRef _currentAudioSampleBufferFormatDescription;
    
    CMTime _currentVideoTime;
    
    FrameRateCalculator *_frameRateCalculator;
    
    float zoomRate;
   
    UIImageView *testImageView;
    
    NSInteger majorStateChange;
    
    CMVideoDimensions captureResolution;
    CMVideoDimensions diskResolution;
    
    CGAffineTransform writeTransform;
 
    NSInteger titleDurationStop;
    
    CGFloat changeSettleTime;
    
    BOOL dontUpdateVideoViewAtPresent;
    
    BOOL takingStill;
}



@end

@implementation VideoCaptureView
@synthesize currentVideoTime = _currentVideoTime;

-(void)updateAudioLevel {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   
    if ( (!appD.audioRecordingAllowed) || (!_audioDevice) ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"audioLevelReport" object:@[ @[ [NSNumber numberWithFloat:-1000.0f], [NSNumber numberWithFloat:-1000.0f] ] ] ];
        return;
    }
    
    AVCaptureAudioDataOutput *audioDataOutput = nil;
    NSArray *outputs = [_captureSession outputs];
    if ([outputs count]>2) {
        audioDataOutput = [[_captureSession outputs] objectAtIndex:2];
    }
   
    if (!audioDataOutput) {
        return;
    }

    NSArray *connections = audioDataOutput.connections;
    if ([connections count] > 0) {
        // There should be only one connection to an AVCaptureAudioDataOutput.
        AVCaptureConnection *connection = [connections objectAtIndex:0];
        
        NSArray *audioChannels = connection.audioChannels;
        NSMutableArray *channels = [[NSMutableArray alloc] initWithCapacity:2];
        for (AVCaptureAudioChannel *channel in audioChannels) {
            float avg = channel.averagePowerLevel;
            float peak = channel.peakHoldLevel;
            [channels addObject:@[ [NSNumber numberWithFloat:avg], [NSNumber numberWithFloat:peak] ] ];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:@"audioLevelReport" object:[channels copy]];
    }

}

-(void)addSettleTime:(CGFloat)amount {
    changeSettleTime += amount;
}

-(void)updateFilterAttributesWithName:(NSString *)name andDict:(NSDictionary *)attribs {
    [filterTool updateImageEffectParameters:name withDict:attribs];
}

-(BOOL)isRunning {
    BOOL answer = NO;
    
    if (_captureSession && [_captureSession isRunning]) {
        answer = YES;
    }
    return answer;
}

-(BOOL)isLoaded {
    BOOL answer = NO;
    
    if (_captureSession) {
        answer = YES;
    }
    return answer;
}

-(void)updateFramingGuideOffset:(CGFloat )offset {
    [guidePane updateFramingGuideOffset:offset];
    [[SettingsTool settings] setFramingGuideXOffset:offset];
}

-(void)showGuidePaneHorizon:(BOOL)enabled {
    guidePane.displayHorizon = enabled;
    [guidePane setNeedsDisplay];
}

-(CGRect )videoPreviewFrame {
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        return videoPreviewOld.frame;
    }
    
    return _videoPreviewView.frame;
}

-(void)setVideoPreviewFrame:(CGRect )r {
    videoPreviewOld.frame = r;
    previewLayer.frame = CGRectMake(0,0,r.size.width, r.size.height);
    _videoPreviewView.frame = r;
   
    
}

-(void)showBorder:(BOOL)show {
    if (show) {
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.layer.borderWidth = 3.0f;
        self.layer.masksToBounds = NO;
    } else {
        self.layer.borderWidth = 0.0f;
    }
}


-(void)reticleUpdateProc {
    BOOL flip = [[SettingsTool settings] cameraFlipEnabled];
    
    [StatusReporter manager].lastReportedFrameRate = _frameRateCalculator.frameRate;
    
    if ([self isRunning] && ([SyncManager manager].progressContainer.superview != self )) {
        [self addSubview:[[SyncManager manager] progressContainer]];
        [[SyncManager manager] progressContainer].frame = CGRectMake(2,15,140,30);
    }

    if (![self isRunning]) {
        return;
    }
    
    if (changeSettleTime > 0.0f) {
        changeSettleTime -= 0.1f;
    }
    
    
    [self updateAudioLevel];
    
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    if (error) {
        return;
    }
    
    if (!CGPointEqualToPoint(lastExposureReticlePos, newExposureReticlePos)) {
        if ([_videoDevice isExposurePointOfInterestSupported]) {
            
            // convert to hbr 0.0 tl 1,1 = br
            
            float x = (newExposureReticlePos.x / [self videoPreviewFrame].size.width);
            float y = (newExposureReticlePos.y / [self videoPreviewFrame].size.height);
            
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                x = 1.0 - (newExposureReticlePos.x / [self videoPreviewFrame].size.width);
                y = 1.0 - (newExposureReticlePos.y / [self videoPreviewFrame].size.height);
            }
            
            if (flip) {
                if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                    y = (newExposureReticlePos.y / [self videoPreviewFrame].size.height);
                } else {
                   y = 1.0 - (newExposureReticlePos.y / [self videoPreviewFrame].size.height);
                }
            }
            
            
            [_videoDevice setExposurePointOfInterest:CGPointMake(x,y)];
            if (_videoDevice.exposureMode == AVCaptureExposureModeContinuousAutoExposure) {
                [_videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
        }
        lastExposureReticlePos = newExposureReticlePos;
    } else if (!CGPointEqualToPoint(lastFocusReticlePos, newFocusReticlePos)) {
        if ([_videoDevice isFocusPointOfInterestSupported]) {
            float x = (newFocusReticlePos.x / [self videoPreviewFrame].size.width);
            float y =(newFocusReticlePos.y / [self videoPreviewFrame].size.height);
            
           
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                x = 1.0 - (newFocusReticlePos.x / [self videoPreviewFrame].size.width);
                y = 1.0 - (newFocusReticlePos.y / [self videoPreviewFrame].size.height);
            }
            
            if (flip) {
                if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                    y = (newFocusReticlePos.y / [self videoPreviewFrame].size.height);
                } else {
                    y = 1.0 - (newFocusReticlePos.y / [self videoPreviewFrame].size.height);
                }
            }

            
            
            [_videoDevice setFocusPointOfInterest:CGPointMake(x,y)];
            
            if (_videoDevice.focusMode == AVCaptureFocusModeContinuousAutoFocus) {
                [_videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            } 
        }
        lastFocusReticlePos = newFocusReticlePos;
    }
    
    [_videoDevice unlockForConfiguration];
}


-(BOOL)isRecording {
    BOOL answer = NO;
   
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        if (movieFile.recording) {
            answer = YES;
        }
    } else {
        if (_assetWriter) {
            answer = YES;
        }
    }

    return answer;
}

-(void)updateInterfaceHidden:(BOOL)hidden { 
    [self positionVideoPreview];
    //[self showBorder:!hidden];
    [self showBorder:NO];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self appear];
    }
    
    return self;
}


-(void)appear {
    [[AudioManager manager] playbackMode:NO];
    
    if (1 == 2) {
        [self reportCameraActiveFormatDetailsForBack:YES];
        [self reportCameraActiveFormatDetailsForBack:NO];
    }

    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    _captureSessionQueue = dispatch_queue_create("capture_session_queue", NULL);
    
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sDeviceRgbColorSpace = CGColorSpaceCreateDeviceRGB();
    });
    
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : (__bridge id)sDeviceRgbColorSpace } ];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    NSError *error = nil;
    NSString *audioStr = [[NSBundle mainBundle] pathForResource:@"beep-7" ofType:@"wav"];
    NSURL *audioURL = [NSURL fileURLWithPath:audioStr];
    beepPlayer = [[AVAudioPlayer alloc]  initWithContentsOfURL:audioURL error:&error];
    beepPlayer.volume = 0.5;
    [beepPlayer prepareToPlay];
    
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"camera-shutter-click-01" ofType:@"wav"];
    NSURL *shutterURL = [NSURL fileURLWithPath:path];
    shutterPlayer = [[AVAudioPlayer alloc]  initWithContentsOfURL:shutterURL error:&error];
    shutterPlayer.volume = 0.15;
    [shutterPlayer prepareToPlay];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendStatusReport:) name:@"commandSendStatus" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleCaptureSessionStartedRunning:) name:AVCaptureSessionDidStartRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flashScreenForStill:) name:@"flashScreenForStill" object:nil];
    
    filterTool = [[FilterTool alloc] init];
    
    UILongPressGestureRecognizer *longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDraggingView:)];
    longP.minimumPressDuration = 0.25f;
    [self addGestureRecognizer:longP];
    
    UIPinchGestureRecognizer *pinchG = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(userPinchingView:)];
    [self addGestureRecognizer:pinchG];
    
    if (!guidePane) {
        guidePane = [[GuidePane alloc] initWithFrame:CGRectZero];
        guidePane.backgroundColor = [UIColor clearColor];
    }
    
    [self addSubview:guidePane];
    
    [self positionVideoPreview];
    
    [self showGuidePaneHorizon:[[SettingsTool settings] horizonGuide]];
    
    [self updateFramingGuide:[[SettingsTool settings] framingGuide]];
    
    [self updateThirdsGuide:[[SettingsTool settings] thirdsGuide]];
    
    self.backgroundColor = [UIColor blackColor];
}

-(void)focusReticleTapped:(UITapGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    FocusReticleView *v = (FocusReticleView *)g.view;
    v.locked = ![self currentFocusLock];
    [v update];
    
    [self setFocusLock:v.locked];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"delayedUpdate" object:nil];
}

-(void)focusReticlePanned:(UIPanGestureRecognizer *)g {
    FocusReticleView *v = (FocusReticleView *)g.view;

    CGPoint p = CGPointZero;
    
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        p = [g locationInView:videoPreviewOld];
    } else {
        p = [g locationInView:_videoPreviewView];
    }
    
    BOOL negativeOperation = NO;

    if ([[SettingsTool settings] cameraFlipEnabled]) {
        negativeOperation = !negativeOperation;
    }
    
    if (negativeOperation) {
        p.y = [self videoPreviewFrame].size.height - p.y;
    }
    
    v.center = p;
    
    newFocusReticlePos = p;
}

-(void)exposureReticleTapped:(UITapGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateEnded) {
        return;
    }
    ExposureReticleView *v = (ExposureReticleView *)g.view;
    v.locked = ![self currentExposureLock];
    [v update];
    
    [self setExposureLock:v.locked];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"delayedUpdate" object:nil];
}

-(void)exposureReticlePanned:(UIPanGestureRecognizer *)g {
    
    ExposureReticleView *v = (ExposureReticleView *)g.view;
    CGPoint p = CGPointZero;
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        p = [g locationInView:videoPreviewOld];
    } else {
       p = [g locationInView:_videoPreviewView];
    }
    
    
    BOOL negativeOperation = NO;
    
    if ([[SettingsTool settings] cameraFlipEnabled]) {
        negativeOperation = !negativeOperation;
    }
    
    if (negativeOperation) {
        p.y = [self videoPreviewFrame].size.height - p.y;
    }
    
    v.center = p;
    
    newExposureReticlePos = p;
}

- (void)dealloc
{   //NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
   
    if (self) {
        while ([self.subviews count]>0) {
            UIView *v = [self.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    if (_currentAudioSampleBufferFormatDescription)
        CFRelease(_currentAudioSampleBufferFormatDescription);
    
    updateTimer = nil;
    beepPlayer = nil;
    shutterPlayer = nil;
    busyAnimator = nil;
    busyView = nil;
    guidePane = nil;
    reticleTimer = nil;
    _videoPreviewView = nil;
    _ciContext = nil;
    _eaglContext = nil;
    _audioDevice = nil;
    _videoDevice = nil;
    _captureSession = nil;
    stillImageOutput = nil;
    previewLayer = nil;
    videoPreviewOld = nil;
    movieFile = nil;
    _assetWriter = nil;
    _assetWriterAudioInput = nil;
    _assetWriterVideoInput = nil;
    _assetWriterInputPixelBufferAdaptor = nil;
    _captureSessionQueue = nil;
    filterTool = nil;
    _frameRateCalculator = nil;
    testImageView = nil;
}

-(void)userDraggingView:(UILongPressGestureRecognizer *)g {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *vc =[appD.navController.viewControllers lastObject];
    CGPoint loc = [g locationInView:vc.view];
    static CGPoint center;
    
    if (g.state == UIGestureRecognizerStateBegan) {
        center = g.view.center;
    } else if (g.state == UIGestureRecognizerStateEnded) {
        [[SettingsTool settings] setiiPadVideoViewRect:g.view.frame];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint offsetAmt = CGPointMake(g.view.center.x - center.x, g.view.center.y - center.y);
        CGPoint offsetPos = CGPointMake(loc.x + offsetAmt.x, loc.y + offsetAmt.y);
        
        offsetPos.x -= g.view.bounds.size.width / 2.0f;
        offsetPos.y -= g.view.bounds.size.height / 2.0f;
        
        CGRect r = CGRectMake(offsetPos.x, offsetPos.y, self.frame.size.width, self.frame.size.height);
                
        if (r.origin.x + r.size.width > 1021) {
            r.origin.x = 1024 - r.size.width;
        } else if (r.origin.x < 0.0f) {
            r.origin.x = 0.0f;
        }
        
        if (r.origin.y + r.size.height > 765) {
            r.origin.y = 768 - r.size.height;
        } else if (r.origin.y < 0.0f) {
            r.origin.y = 0.0f;
        }
        
        self.frame = r;
        center = g.view.center;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updatevcbg" object:nil];
    }
}

-(void)userPinchingView:(UIPinchGestureRecognizer *)g {

    static CGRect startRect;
    
    if (g.state == UIGestureRecognizerStateBegan) {
        startRect = g.view.frame;
        [self dontUpdateVideoView:@(YES)];
    } else if (g.state == UIGestureRecognizerStateEnded) {
        [self dontUpdateVideoView:@(NO)];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGFloat scale = g.scale;
        
        CGSize newSize = CGSizeMake(startRect.size.width * scale, startRect.size.height * scale);
        
        if (newSize.width > 800) {
            newSize.width = 800;
        }
        
        newSize.height = newSize.width / (16.0f/9.0f);
      
        
        
        
        self.frame = CGRectMake(startRect.origin.x, startRect.origin.y, newSize.width, newSize.height);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updatevcbg" object:nil];
        [self positionVideoPreview];
    }
    


}

-(void)cleanup {
    _eaglContext = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"commandSendStatus" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
}



-(void)removeBusyIndicator {
    if (busyView) {
        [busyAnimator removeAllBehaviors];
        [busyView removeFromSuperview];
        busyView = nil;
        busyAnimator = nil;
    }
}

-(void)addBusyIndicator {
    if (busyView) {
        return;
    }
    
    UIView *targetView = self;
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        targetView = videoPreviewOld;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        targetView = _videoPreviewView;
    }
    
    if (!targetView) {
        targetView = self.superview;
    }
    
    busyView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"19-gear-white"]];
    [targetView addSubview:busyView];
  
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        busyView.bounds = CGRectMake(0,0,busyView.bounds.size.width * 2.0, busyView.bounds.size.height *2.0);
    }

    busyView.center = targetView.center;
    
    busyAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:targetView];
    
    UICollisionBehavior *bounceCollision = [[UICollisionBehavior alloc] initWithItems:@[ busyView ]];
    [bounceCollision setTranslatesReferenceBoundsIntoBoundary:YES];
    [busyAnimator addBehavior:bounceCollision];
    
    UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[ busyView ] mode:UIPushBehaviorModeInstantaneous];
    NSInteger choice = arc4random_uniform(4);
    
    CGFloat angle = 45.0f;
    switch (choice) {
        case 1:
            angle = 135;
            break;
        case 2:
            angle = 225;
            break;
        case 3:
            angle = 315;
            break;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [push setAngle:DEGREES_TO_RADIANS(angle) magnitude:0.15];
    } else {
        [push setAngle:DEGREES_TO_RADIANS(angle) magnitude:0.10];
    }
    
    [busyAnimator addBehavior:push];
    
    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[ busyView ]];
    [itemBehavior setElasticity:1.01f];
    [itemBehavior setFriction:0.0f];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [itemBehavior addAngularVelocity:2.0f forItem:busyView];
    } else {
       [itemBehavior addAngularVelocity:1.0f forItem:busyView];
    }
    
    [busyAnimator addBehavior:itemBehavior];

}

-(void)restartCamera {
    [self stopCamera];
    [self addBusyIndicator];
    [self performSelector:@selector(startCamera) withObject:nil afterDelay:0.5];
}


-(void)stopCamera {
    if (!_captureSession ) {
        return;
    }
    
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }

    
    _frameRateCalculator = nil;
    
    if ([self isRecording]) {
        [self stopRecording];
    }
    
    if (_captureSession && _captureSession.running) {
        [_captureSession stopRunning];
        
        dispatch_sync(_captureSessionQueue, ^{
            NSLog(@"waiting for capture session to end");
        });
        
        _captureSession = nil;
        _videoDevice = nil;
    }
    
    [reticleTimer invalidate];
    reticleTimer = nil;
    
        //if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        [previewLayer removeFromSuperlayer];
        [videoPreviewOld removeFromSuperview];
        videoPreviewOld = nil;
        //} else {
        if (_videoPreviewView ) {
            [_videoPreviewView deleteDrawable];
            [_videoPreviewView removeFromSuperview];
            _videoPreviewView = nil;
        }

        //}
    
 
    _audioDevice = nil;
    
    _ciContext = nil;

    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    majorStateChange = 1;
}


-(void)startRecording {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([self isRecording]) {
        return;
    }
    
    [[UtilityBag bag] logEvent:@"record" withParameters:@{ @"res" : @([[SettingsTool settings] captureOutputResolution]) } ];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [appD allowRotation:NO];
        [beepPlayer play];
        NSLog(@"bp:%@", beepPlayer);
        if ([[SettingsTool settings] engineTitling] && (![[[SettingsTool settings] engineTitlingBeginName] isEqualToString:@"None"])) {
            [filterTool updateTitleForBegin];
        }
    });
     
    [self performSelector:@selector(startRecording2) withObject:nil afterDelay:0.5];
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
                //[NSNumber numberWithFloat:basicDescription->mSampleRate], AVSampleRateKey,
                [NSNumber numberWithFloat:[[SettingsTool settings] audioSamplerate]], AVSampleRateKey,
                channelLayoutData, AVChannelLayoutKey
                , nil];
        
    } else {
        dict = [ NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:kAudioFormatLinearPCM] , AVFormatIDKey ,
                [NSNumber numberWithInteger:basicDescription->mChannelsPerFrame], AVNumberOfChannelsKey,
                //[NSNumber numberWithFloat:basicDescription->mSampleRate], AVSampleRateKey,
                [NSNumber numberWithFloat:[[SettingsTool settings] audioSamplerate]], AVSampleRateKey,
                [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                [NSNumber numberWithBool:NO] , AVLinearPCMIsFloatKey ,
                [NSNumber numberWithBool:NO] , AVLinearPCMIsNonInterleaved ,
                [NSNumber numberWithBool:NO] , AVLinearPCMIsBigEndianKey ,
                //[NSNumber numberWithInteger:64000], AVEncoderBitRateKey,
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

    NSString *clipTitle =  [NSString stringWithFormat:@"Recorded clip #%ld", (long)[[SettingsTool settings] nextClipSequenceNumber]];
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.locale = [NSLocale currentLocale];
    item.key = AVMetadataCommonKeyTitle;
    item.value = clipTitle;
    [metadata addObject:item];
   
    AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
    [metadata addObject:descUID];
    
    NSArray *metadataOut = [metadata copy];
    
        //NSLog(@"updateMetadataForAssetWriter:out:%@", metadataOut);
    
    return metadataOut;
}


-(void)startRecording2 {
    
    self.videoPath = [[UtilityBag bag] pathForNewResourceWithExtension:@"mov"];
    
    NSURL *movieURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:self.videoPath]];
    
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        [movieFile setMetadata:[[self updateMetadataForAssetWriter:movieFile.metadata] copy]];
        [movieFile startRecordingToOutputFileURL:movieURL recordingDelegate:self];
    } else {
        if ([[SettingsTool settings] engineTitling] && (![[[SettingsTool settings] engineTitlingBeginName] isEqualToString:@"None"]))  {
            [[SettingsTool settings] setTitleFilterBeginActive:YES];
            if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
            }
            
            titleDurationStop = [[SettingsTool settings] engineTitlingBeginDuration];
        }
        
        NSInteger vidSize = [[SettingsTool settings]  captureOutputResolution];
        
        float dataRate = 0.0f;
        
        AVOutputSettingsAssistant *settingsAssistant = [AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset1280x720];
        
        if ([[SettingsTool settings] fastCaptureMode]) {
            dataRate = [[SettingsTool settings] videoCameraVideoDataRateFastCaptureMode];
            settingsAssistant =[AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset1280x720];
        } else {
            switch (vidSize) {
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
        }
        
        
        NSMutableDictionary *avOutputDict = nil;
        
        if (dataRate > 0.0f) {
            avOutputDict = [settingsAssistant.videoSettings mutableCopy];
            NSMutableDictionary *videoCompressionSettings = [[settingsAssistant.videoSettings objectForKey:AVVideoCompressionPropertiesKey] mutableCopy];
            [videoCompressionSettings setObject:[NSNumber numberWithInteger:(NSInteger)dataRate] forKey:AVVideoAverageBitRateKey];
            [avOutputDict setObject:[videoCompressionSettings copy] forKey:AVVideoCompressionPropertiesKey];
            [avOutputDict setObject:AVVideoScalingModeResizeAspect forKey:AVVideoScalingModeKey];
            [avOutputDict setObject:[NSNumber numberWithInt:diskResolution.width] forKey:AVVideoWidthKey];
            [avOutputDict setObject:[NSNumber numberWithInt:diskResolution.height] forKey:AVVideoHeightKey];
        }
        
        if ([[SettingsTool settings] fastCaptureMode]) {
            avOutputDict = [[NSMutableDictionary alloc] initWithCapacity:3];
            
            [avOutputDict setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
            [avOutputDict setObject:[NSNumber numberWithInt:diskResolution.width] forKey:AVVideoWidthKey];
            [avOutputDict setObject:[NSNumber numberWithInt:diskResolution.height] forKey:AVVideoHeightKey];
            [avOutputDict setObject:AVVideoScalingModeResizeAspect forKey:AVVideoScalingModeKey];
            
            NSMutableDictionary *videoCompressionSettings = [[NSMutableDictionary alloc] initWithCapacity:4];
            [videoCompressionSettings setObject:[NSNumber numberWithInt:60] forKey:AVVideoAverageNonDroppableFrameRateKey];
            [videoCompressionSettings setObject:[NSNumber numberWithInt:60] forKey:AVVideoExpectedSourceFrameRateKey];
            [videoCompressionSettings setObject:[NSNumber numberWithInteger:(NSInteger)dataRate] forKey:AVVideoAverageBitRateKey];
            [avOutputDict setObject:[videoCompressionSettings copy] forKey:AVVideoCompressionPropertiesKey];
        }
        
        
        
        dispatch_async(_captureSessionQueue, ^{
            NSError *error = nil;
            
            AVAssetWriter *newAssetWriter = [AVAssetWriter assetWriterWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
            if (!newAssetWriter || error) {
                NSLog(@"%@", [NSString stringWithFormat:@"Cannot create asset writer, error: %@", error]);
                return;
            }
            
            _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[avOutputDict copy]];
            _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
            
            
            _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:
                                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                                    [NSNumber numberWithUnsignedInteger:diskResolution.width], (id)kCVPixelBufferWidthKey,
                                                    [NSNumber numberWithUnsignedInteger:diskResolution.height], (id)kCVPixelBufferHeightKey,
                                                    (id)kCFBooleanTrue, (id)kCVPixelFormatOpenGLESCompatibility,
                                                    nil]];
            
            
            
            _assetWriterVideoInput.transform = writeTransform;
            
            
            BOOL canAddInput = [newAssetWriter canAddInput:_assetWriterVideoInput];
            if (!canAddInput) {
                NSLog(@"Cannot add asset writer video input");
                _assetWriterAudioInput = nil;
                _assetWriterVideoInput = nil;
                return;
            }
            
            [newAssetWriter addInput:_assetWriterVideoInput];
            
            if (_audioDevice) {
                
                NSDictionary *audioOutputSettings = [self audioDictForCurrentSetup];
                if ([newAssetWriter canApplyOutputSettings:audioOutputSettings forMediaType:AVMediaTypeAudio]) {
                    _assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
                    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
                    
                    if ([newAssetWriter canAddInput:_assetWriterAudioInput])
                        [newAssetWriter addInput:_assetWriterAudioInput];
                    else
                        NSLog(@"Couldn't add asset writer audio input");
                }
                else
                    NSLog(@"Couldn't apply audio output settings.");
            }
            
            _videoWritingStarted = NO;
            _assetWriter = newAssetWriter;
        });
        
    }
    
    if ([[UIDevice currentDevice] isMultitaskingSupported])
        _backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    
    [self addSettleTime:3.5];
    
    if (![[SettingsTool settings] engineMicrophone]) {
        NSLog(@"AUDIO DISABLED");
    }
    
    [self performSelector:@selector(startRecording3) withObject:nil afterDelay:0.25];

}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    if (error) {
        NSLog(@"didFinishRecordingToOutputFileAtURL:%@", error);
    }

    
    [self resetUIAfterRecording];
    
    if ([[SettingsTool settings] clipMoveImmediately] && (![[SettingsTool settings] clipStorageLibrary]) && ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) ) {
        [self performSelectorOnMainThread:@selector(beginMovingClipToAlbum:) withObject:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:self.videoPath] waitUntilDone:NO];
    }
    
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
        //NSLog(@"didStartRecordingToOutputFileAtURL:%@", fileURL);
}



-(void)takeStill {
    if (takingStill) {
        return;
    }
    
    AVCaptureOutput *videoOutput = [[_captureSession outputs] objectAtIndex:1];
    AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    [self flashScreenForStill:Nil];
    
   [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
       NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
       UIImage *still2 = [UIImage imageWithData:data];
       UIImage *still = [UIImage imageWithCGImage:still2.CGImage scale:1.0 orientation:UIImageOrientationUp];
       NSLog(@"Still image size: %@", [NSValue valueWithCGSize:still.size]);
       CGFloat xOffset = [[SettingsTool settings] framingGuideXOffset];
       NSInteger framingGuide = [[SettingsTool settings] framingGuide];
       CGSize guidePaneSize = [[SettingsTool settings] currentGuidePaneSize];
       
       if ((framingGuide > 0) && [[SettingsTool settings] cropStillsToGuide]) {
           CGSize imageSize = [still size];
           
           CGFloat xWidth = imageSize.width / (4.0f / 3.0f);
           
           if (framingGuide == 2) {
               xWidth = imageSize.height;
           }
           
           CGFloat leftX = (imageSize.width - xWidth ) / 2.0f;
           
           if (xOffset != 0.0f) {
               CGFloat guideScaleFactor = imageSize.width / guidePaneSize.width;
               CGFloat imageXOffset = xOffset * guideScaleFactor;
               
               leftX += imageXOffset;
           }
           
           CGRect r = CGRectMake(leftX, 0, xWidth, imageSize.height);
           
           CGImageRef imageRef = CGImageCreateWithImageInRect(still.CGImage, r);
           still = [UIImage imageWithCGImage:imageRef scale:still.scale orientation:still.imageOrientation];
           CGImageRelease(imageRef);
            NSLog(@"Cropped still from %@ to %@", [NSValue valueWithCGSize:imageSize], [NSValue valueWithCGSize:still.size]);
       }
       
       
       NSData *d = UIImagePNGRepresentation(still);
       
       NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache,
                                nil];
       
       
       CGImageSourceRef r = CGImageSourceCreateWithData((__bridge CFDataRef)(d), (__bridge CFDictionaryRef)options);
       
       CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(r, 0, (__bridge CFDictionaryRef)options);
       
       ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
       [library writeImageDataToSavedPhotosAlbum:d metadata:(__bridge NSDictionary *)(imageProperties) completionBlock:^(NSURL *assetURL, NSError *error) {
           CFRelease(r);
           takingStill = NO;
       }];
   }];
}



-(BOOL)handleStill:(CMSampleBufferRef )imageSampleBuffer  {
    CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
    
    if (!exifAttachments) {
        return NO; //this one is not suitable for our purposes
    }
    
    NSString *ext = @"tiff";
    CFStringRef ftype = kUTTypeTIFF;
    
    if (1 == 2) {
        ext = @"jpg";
        ftype = kUTTypeJPEG;
    }
    
    if (1 == 2) {
        ext = @"png";
        ftype = kUTTypePNG;
    }
    
 
    NSString *picPath = [[UtilityBag bag] pathForNewResourceWithExtension:ext];
    NSURL *picURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:picPath]];
    
    //get all the metadata in the image
    CFDictionaryRef metadata = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageSampleBuffer, kCMAttachmentMode_ShouldPropagate);
    // get image reference
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(imageSampleBuffer);
    // >>>>>>>>>> lock buffer address
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    //Get information about the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // create suitable color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //Create suitable context (suitable for camera output setting kCVPixelFormatType_32BGRA)
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // <<<<<<<<<< unlock buffer address
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    // release color space
    CGColorSpaceRelease(colorSpace);
    
    //Create a CGImageRef from the CVImageBufferRef
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    // release context
    CGContextRelease(newContext);
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)(picURL), ftype, 1, NULL);
    CGImageDestinationAddImage(destination, newImage, metadata);
    
    bool ok = CGImageDestinationFinalize(destination);
    
    CFRelease(newImage);
    CFRelease(destination);
    CFRelease(metadata);
    
    if (ok != 1) {
        return NO;
    }
    
    
    return YES;
}


-(void)startRecording3 {
    [[SettingsTool settings] setCurrentExposureLock:[self currentExposureLock]
                                          focusLock:[self currentFocusLock]
                                   whiteBalanceLock:[self currentWhiteBalanceLock]
                                       recordStatus:[self isRecording]
                                            canZoom:[self zoomSupported]
     ];

    [[RemoteAdvertiserManager manager] sendStatusResponse];
    [self performSelector:@selector(startRecording3b) withObject:nil afterDelay:0.1];
}

-(void)startRecording3b {
    elapsed = 0;
    NSLog(@"Recording");
   
    NSInteger take = [[SettingsTool settings] engineTitlingTake];
    take++;
    [[SettingsTool settings] setEngineTitlingTake:take];
}

-(void)updateTimerEvent {
    if ([self isRecording]) {
        elapsed++;
        if ((titleDurationStop !=0) && (elapsed >= titleDurationStop)) {
            titleDurationStop = 0;
            [[SettingsTool settings] setTitleFilterBeginActive:NO];
            if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }
        }
    }
    
    if ([[SettingsTool settings] engineOverlay] && ([[[SettingsTool settings] engineOverlayType] integerValue] == 3)) {
        [filterTool updateWatermark];
    }
    
    [[SettingsTool settings] setCurrentExposureLock:[self currentExposureLock]
                                          focusLock:[self currentFocusLock]
                                   whiteBalanceLock:[self currentWhiteBalanceLock]
                                       recordStatus:[self isRecording]
                                            canZoom:[self zoomSupported]
     ];

    
}

-(void)_handleCaptureSessionStartedRunning:(NSNotification *)n {
    
  
}

-(void)updateVideoOrientation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupVideoConnectionOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    });
}

-(void)setupVideoConnectionOrientationForOrientation:(NSInteger)orientation {
   if (!_captureSession ) {
        return;
    }
    NSArray *outputs = [_captureSession outputs];
    if ( (!outputs) || ([outputs count] <1)) {
        return;
    }
    AVCaptureOutput *videoOutput = [[_captureSession outputs] objectAtIndex:0];
    AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];

    if (![videoConnection isVideoOrientationSupported]) {
        NSLog(@"Ignoring setupVideoConnectionOrientationForOrientation: not isVideoOrientationSupported");
        return;
    }
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        NSLog(@"Ignoring setupVideoConnectionOrientationForOrientation: not landscape");
        return;
    }
    
    
   
        // NSLog(@"setupVideoConnectionOrientationForOrientation_start:%ld:%ld:%d", (long)orientation, (long)videoConnection.videoOrientation, flip) ;
    
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    } else {
        videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    
    

    
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        CATransform3D t = CATransform3DMakeScale(2.0, 2.0, 1.0);
        
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
             t = CATransform3DRotate(t, M_PI/2, 0, 0, 1);
        } else {
             t = CATransform3DRotate(t, -M_PI/2, 0, 0, 1);
        }
        previewLayer.transform = t;

     } else {
         BOOL mirrored = ![[SettingsTool settings] cameraIsBack];
         BOOL flip = [[SettingsTool settings] cameraFlipEnabled];
         
         CGAffineTransform result = CGAffineTransformIdentity;
         
         if (flip) {
             CGAffineTransform t3 = CGAffineTransformMakeScale(1,     -1);
             result = CGAffineTransformConcat(result, t3);
         }
         
         if (mirrored) {
             CGAffineTransform t2 = CGAffineTransformMakeScale(-1,     1);
             result = CGAffineTransformConcat(result, t2);
         }

         _videoPreviewView.transform = result;
        writeTransform   = result;
             //NSLog(@"setupVideoConnectionOrientationForOrientation_end:%ld:%ld:%d:%@", (long)orientation, (long)videoConnection.videoOrientation, flip, [NSValue valueWithCGAffineTransform:result]);
     }
}

-(BOOL)zoomSupported {
    BOOL answer = NO;
    
    if ([self maxZoomLevel] > 1.0f) {
        answer = YES;
    }
    
    return answer;
}

-(float)maxZoomLevel {
    float maxZoom = _videoDevice.activeFormat.videoMaxZoomFactor;
    
    if (maxZoom > 20) {
        maxZoom = 20;
    }
    
    return maxZoom;
}

-(void)stopZoomingImmediately {
    float currentZoom = [self currentZoomLevel];
    
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    if (error) {
        NSLog(@"Unable to get lock; unable to stopZoomingImmediately");
        return;
    }
    
    _videoDevice.videoZoomFactor = currentZoom;
    [_videoDevice unlockForConfiguration];
    
}

-(void)resetUIAfterRecording {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   
    void (^resetUI)(void) = ^(void) {
        if ([[UIDevice currentDevice] isMultitaskingSupported])
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundRecordingID];
        
        if (![[SettingsTool settings] lockRotation]) {
            [appD allowRotation:YES];
        }
        
        [[UtilityBag bag] performSelector:@selector(makeThumbnail:) withObject:self.videoPath afterDelay:0.1];
    };
    
    dispatch_async(dispatch_get_main_queue(), resetUI);
}

-(void)stopRecording {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (![self isRecording]) {
       return;
    }
    
    [[UtilityBag bag] logEventEnd:@"record" withParameters:nil ];
    
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        [movieFile stopRecording];
        return;
    }
    
    if (!appD.wasInterrupted) {
        if ([[SettingsTool settings] titleFilterEndActive]) {
            [[SettingsTool settings] setTitleFilterEndActive:NO];
            if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }
        } else if ([[SettingsTool settings] engineTitling] && (![[[SettingsTool settings] engineTitlingEndName] isEqualToString:@"None"]))  {
            [filterTool updateTitleForEnd];
            [[SettingsTool settings] setTitleFilterEndActive:YES];
            if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
            }
            [self performSelector:@selector(stopRecording) withObject:nil afterDelay:[[SettingsTool settings] engineTitlingEndDuration]];
            return;
        }
    }
    
 
    
    AVAssetWriter *writer = _assetWriter;
    
    _assetWriterAudioInput = nil;
    _assetWriterVideoInput = nil;
    _assetWriterInputPixelBufferAdaptor = nil;
    _assetWriter = nil;
    
    [[SettingsTool settings] setCurrentExposureLock:[self currentExposureLock]
                                          focusLock:[self currentFocusLock]
                                   whiteBalanceLock:[self currentWhiteBalanceLock]
                                       recordStatus:[self isRecording]
                                            canZoom:[self zoomSupported]
     ];

    [[RemoteAdvertiserManager manager] sendStatusResponse];
    
    dispatch_async(_captureSessionQueue, ^(void){

        [writer finishWritingWithCompletionHandler:^(void){
            if (writer.status == AVAssetWriterStatusFailed)
            {
                [self resetUIAfterRecording];
                NSLog(@"Cannot complete writing the video, the output could be corrupt.");
            }
            else if (writer.status == AVAssetWriterStatusCompleted)
            {
                NSLog(@"recording completed");
                
                if ( (!appD.wasInterrupted) && [[SettingsTool settings] clipMoveImmediately] && (![[SettingsTool settings] clipStorageLibrary]) && ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) ) {
                    [self performSelectorOnMainThread:@selector(beginMovingClipToAlbum:) withObject:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:self.videoPath] waitUntilDone:NO];
                }
                
            }
            
            if (!appD.wasInterrupted) {
                [self resetUIAfterRecording];
            }
        }];
        
    });
}

-(void)beginMovingClipToAlbum:(NSString *)filePath {
    NSLog(@"beginMovingClipToAlbum:%@", filePath);

    if ([[SettingsTool settings] isiPhone4S]) {
        [self stopCamera];
    } else {
        [self dontUpdateVideoView:@(YES)];
    }
    [self addSettleTime:3.5];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"moveClipToCameraRoll" object:filePath];
    
}

-(BOOL)currentWhiteBalanceLock {
    return  (_videoDevice.whiteBalanceMode != AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance);
}

-(void)setWhiteBalanceLock:(BOOL)enabled {
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    if (!error) {
         if (enabled) {
            if ([_videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [_videoDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
                    //NSLog(@"wb-AVCaptureWhiteBalanceModeAutoWhiteBalance");
            } else if ([_videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
                [_videoDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
                    // NSLog(@"wb-AVCaptureWhiteBalanceModeLocked");
            }
        } else {
            if ([_videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                [_videoDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
        }
        
        [_videoDevice unlockForConfiguration];
    }

}

-(BOOL)currentExposureLock {
     return  (_videoDevice.exposureMode != AVCaptureExposureModeContinuousAutoExposure);
}

-(void)setExposureLock:(BOOL)enabled {
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    
    if (!error) {
        if (enabled) {
            if ([_videoDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                [_videoDevice setExposureMode:AVCaptureExposureModeAutoExpose];
                    // NSLog(@"exp-AVCaptureExposureModeAutoExpose");
            } else if ( ([_videoDevice isExposureModeSupported:AVCaptureExposureModeLocked]) && (_videoDevice.exposureMode != AVCaptureExposureModeLocked) ){
                [_videoDevice setExposureMode:AVCaptureExposureModeLocked];
                    //NSLog(@"exp-AVCaptureExposureModeLocked");
            }
        } else {
            if ([_videoDevice  isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [_videoDevice  setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
        }
        
        [_videoDevice unlockForConfiguration];
    }
}

-(void)positionVideoPreview {
    
    CGRect f = self.frame;
    [self setVideoPreviewFrame:CGRectMake(0,0,f.size.width,f.size.height)];
    guidePane.frame = [self videoPreviewFrame];
   
    [[SettingsTool settings] setCurrentGuidePaneSize:guidePane.frame.size];
    
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        videoPreviewOld.alpha = 1.0f;
        [self sendSubviewToBack:videoPreviewOld];
    } else {
        float scale = [UIScreen mainScreen].scale;
         _videoPreviewView.alpha = 1.0f;
        _videoPreviewViewBounds = CGRectZero;
        _videoPreviewViewBounds.size.width =  f.size.width * scale;
        _videoPreviewViewBounds.size.height = f.size.height * scale;
        
        [self sendSubviewToBack:_videoPreviewView];
        
        dispatch_async(_captureSessionQueue, ^(void) {
            [_videoPreviewView bindDrawable];
        });

    }
}

-(BOOL)currentFocusLock {
    return  (_videoDevice.focusMode != AVCaptureFocusModeContinuousAutoFocus);
}

-(NSInteger)currentFocusRange {
    return _videoDevice.autoFocusRangeRestriction;
}

-(void)setFocusLock:(BOOL)enabled {
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    if (!error) {
        if (enabled) {
            if ([_videoDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [_videoDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            }
        } else {
            if ([_videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [_videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
        }
        [_videoDevice  unlockForConfiguration];
    }
}

-(void)setFocusRange:(NSInteger)which {
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    if (!error) {

        if ([_videoDevice isAutoFocusRangeRestrictionSupported]) {
            [_videoDevice setAutoFocusRangeRestriction:which];
        }
        [_videoDevice  unlockForConfiguration];
    }
}

-(void)setFocusSpeedSmooth:(BOOL)which {
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    if (!error) {
        
        if ([_videoDevice isSmoothAutoFocusSupported]) {
            [_videoDevice setSmoothAutoFocusEnabled:which];
        }
        [_videoDevice  unlockForConfiguration];
    }
}


-(void)updateFrameRate {
    NSError *error;
    NSInteger frameRate = [[SettingsTool settings]  videoCameraFrameRate];

    NSInteger cameraRate = _videoDevice.activeVideoMaxFrameDuration.timescale;
    
    NSArray *rateRanges = _videoDevice.activeFormat.videoSupportedFrameRateRanges;

    BOOL allowed = NO;
    
    NSInteger maxRate = 30;
    
    for (AVFrameRateRange *r in rateRanges) {
        if ( (r.minFrameDuration.timescale >= frameRate) && (r.maxFrameDuration.timescale <= frameRate) ) {
            allowed = YES;
            if (maxRate < r.minFrameDuration.timescale) {
                maxRate = r.minFrameDuration.timescale;
            }
            break;
        }
        //NSLog(@"%d:%d", r.minFrameDuration.timescale, r.maxFrameDuration.timescale);
        
    }
    
    [[SettingsTool settings] setCurrentMaxFrameRate:maxRate];
    
    if (allowed) {
        [_videoDevice lockForConfiguration:&error];
        
        if (!error) {
             [_videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1,(int)frameRate)];
             [_videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1,(int)frameRate)];
             [_videoDevice  unlockForConfiguration];
        }
        
       
       // NSLog(@"valid time; using %d", frameRate);
    } else if (cameraRate > 0) {
       [[SettingsTool settings]  setVideoCameraFrameRate:cameraRate];
       // NSLog(@"Invalid time; using %d", cameraRate);
    }
}

-(void)updateStabilization {
    BOOL enableIS = [[SettingsTool settings]  cameraISEnabled];
    if (!_captureSession ) {
        return;
    }
    
    NSArray *outputs = [_captureSession outputs];
    if ( (!outputs) || ([outputs count] <1)) {
        return;
    }
    AVCaptureOutput *videoOutput = [[_captureSession outputs] objectAtIndex:0];
    AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];

    
    if ([videoConnection isVideoStabilizationSupported]) {
        [videoConnection setEnablesVideoStabilizationWhenAvailable:enableIS];
    }
}

-(void)updateAudioCaptureSampleRate {
    
    double rate = [[SettingsTool settings]  audioSamplerate];
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setPreferredSampleRate:rate error:&error];
    
    double examinedRate =  [[AVAudioSession sharedInstance] sampleRate];
    
    
    if (error || (rate != examinedRate) ) {
        NSLog(@"Problem in updateAudioCaptureSampleRate:%f != %f err:%@", rate, examinedRate, error);
    }
        
    [[AudioManager manager] updateSampleRate:examinedRate];

}

-(void)reportCameraActiveFormatDetailsForBack:(BOOL)backCamera {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevicePosition position = backCamera ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    AVCaptureDevice  *vd = nil;
    for (AVCaptureDevice *v in videoDevices)
    {
        if (v.position == position) {
            vd = v;
            break;
        }
    }
    if (vd) {
        NSString *details = [NSString stringWithFormat:@"Model:%@ Name:%@\n", [[UIDevice currentDevice] model], [[UIDevice currentDevice] name]];
        
        for (AVCaptureDeviceFormat* currdf in vd.formats)
        {
            NSString* compoundString = @"";
            compoundString = [compoundString stringByAppendingString:[NSString stringWithFormat:@"'%@'", currdf.mediaType]];
            CMFormatDescriptionRef myCMFormatDescriptionRef= currdf.formatDescription;
            FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(myCMFormatDescriptionRef);

            if (mediaSubType==kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                compoundString = [compoundString stringByAppendingString:@"/'420v'"];
            else if (mediaSubType==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            {
                compoundString = [compoundString stringByAppendingString:@"/'420f'"];
            }
            else [compoundString stringByAppendingString:@"'UNKNOWN'"];
            
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(myCMFormatDescriptionRef);
            compoundString = [compoundString stringByAppendingString:[NSString stringWithFormat:@" %ix %i", dimensions.width, dimensions.height]];
            
            float maxFramerate = ((AVFrameRateRange*)[currdf.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
            compoundString = [compoundString stringByAppendingString:[NSString stringWithFormat:@", { %.0f- %.0f fps}", ((AVFrameRateRange*)[currdf.videoSupportedFrameRateRanges objectAtIndex:0]).minFrameRate,
                                                                      maxFramerate]];
            
            compoundString = [compoundString stringByAppendingString:[NSString stringWithFormat:@", fov: %.3f", currdf.videoFieldOfView]];
            compoundString = [compoundString stringByAppendingString:
                              (currdf.videoBinned ? @", binned" : @"")];
            
            compoundString = [compoundString stringByAppendingString:
                              (currdf.videoStabilizationSupported ? @", supports vis" : @"")];
            
            compoundString = [compoundString stringByAppendingString:[NSString stringWithFormat:@", max zoom: %.2f", currdf.videoMaxZoomFactor]];
            
            compoundString = [compoundString stringByAppendingString:[NSString stringWithFormat:@" (upscales @%.2f)", currdf.videoZoomFactorUpscaleThreshold]];
            
            details = [details stringByAppendingFormat:@"%@\n", compoundString];
        }
        
        details  = [details stringByAppendingFormat:@"------------------------------------\n\n"];
        
        NSLog(@"%@", details);
        
    }
    
}

-(void)captureResolutionSelector {
    AVCaptureDeviceFormat *fps120 = nil;
    AVCaptureDeviceFormat *fps60 = nil;
    
    for (AVCaptureDeviceFormat* currdf in _videoDevice.formats)
    {
        CMFormatDescriptionRef myCMFormatDescriptionRef= currdf.formatDescription;
        FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(myCMFormatDescriptionRef);
        BOOL fullRange = NO;
        if (mediaSubType==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        {
            fullRange = YES;
        }
        
        float maxFramerate = ((AVFrameRateRange*)[currdf.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
        
        if ([[SettingsTool settings] fastCaptureMode]) {
            if ((!fps120) && fullRange && (maxFramerate>119)) {
                fps120 = currdf;
            } else if ((!fps60) && fullRange && (maxFramerate>59) ) {
                fps60 = currdf;
            }
            
            if (fps60 && fps120) {
                break;
            }
        }
    }

    if (fps120) {
        NSLog(@"Selected 120 fps mode");
        [_videoDevice lockForConfiguration:nil];
        _videoDevice.activeFormat = fps120;
        _videoDevice.activeVideoMinFrameDuration = CMTimeMake(1,120);
        _videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1,120);
        [_videoDevice unlockForConfiguration];
        [[SettingsTool settings] setCurrentMaxFrameRate:120];
        
    } else if (fps60) {
        NSLog(@"Selected 60 fps mode");
        [_videoDevice lockForConfiguration:nil];
        _videoDevice.activeFormat = fps60;
        _videoDevice.activeVideoMinFrameDuration = CMTimeMake(1,60);
        _videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1,60);
        [_videoDevice unlockForConfiguration];
        [[SettingsTool settings] setCurrentMaxFrameRate:60];
        
    }
}


-(void)updateBrightness:(float)val {
    [filterTool updateBrightness:val];
}

-(void)updateContrast:(float)val {
    [filterTool updateContrast:val];
}

-(void)updateSaturation:(float)val {
    [filterTool updateSaturation:val];
}

-(void)lightTorch:(float)level {
    if (!_videoDevice.hasTorch) {
        return;
    }
    
    NSError *error = nil;
    
    [_videoDevice lockForConfiguration:&error];
    
    if (error) {
        return;
    }
    
    
    BOOL result = [_videoDevice setTorchModeOnWithLevel:level error:&error];
    
    if (error) {
        NSLog(@"Unable to set torch level to %f : %@", level, error);
    } else if (!result) {
        NSLog(@"Torch too hot for that level %f : %@", level, error);
    }
    
    [_videoDevice unlockForConfiguration];
}

-(void)extinguishTorch {
    
    NSError *error = nil;
    
    [_videoDevice lockForConfiguration:&error];
    
    if (error) {
        return;
    }
    
    if ([_videoDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
        [_videoDevice setTorchMode:AVCaptureTorchModeOff];
    }
    
    [_videoDevice unlockForConfiguration];
}

-(float)torchSetting {
    if (!_videoDevice.hasTorch) {
        NSLog(@"torchSetting:NoTorch");
        return -1.0f;
    }
    
    if (![_videoDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
        NSLog(@"torchSetting:NoAVCaptureTorchModeOn");
        return -1.0f;
    }
    
    NSError *error = nil;
    
    [_videoDevice lockForConfiguration:&error];
    
    if (error) {
        NSLog(@"torchSetting:NoLock");
        return -1.0f;
    }
    
    float val = 0.0f;

    if (_videoDevice.torchAvailable) {
        val = _videoDevice.torchLevel;
    }
    
    [_videoDevice unlockForConfiguration];
        //NSLog(@"torchSetting:%f", val);
    return val;
}


-(void)startCamera {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   
    NSString *model = [[UIDevice currentDevice] model];
    if (YES == [model isEqualToString:@"iPhone Simulator"]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [appD askForMicrophone];
        return;
    }
    
    
    if ([self isRunning]) {
        return;
    } else if ([self isLoaded]) {
        [self stopCamera];
    }
    
    if (!updateTimer) {
         updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimerEvent) userInfo:nil repeats:YES];
    }
    
    [appD askForMicrophone];
    
    [[AudioManager manager] playbackMode:NO];
    
    [[AudioManager manager] updateSampleRate:[[SettingsTool settings] audioSamplerate]];
    
    changeSettleTime = 7.0f;
    
    if (!reticleTimer) {
        reticleTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reticleUpdateProc) userInfo:nil repeats:YES];
    }

    zoomRate = [[SettingsTool settings] zoomRate];
    NSInteger diskRes = [[SettingsTool settings]  captureOutputResolution];
    
    BOOL backCamera = [[SettingsTool settings]  cameraIsBack];
    
    //look at disk res; figure appropriate capture res
    
    NSString *avResolution = AVCaptureSessionPreset1280x720;
    
    if (!backCamera) {
        if (![self frontCameraSupported]) {
             [[SettingsTool settings] setCameraIsBack:YES];
            backCamera = YES;
        } else if (diskRes > 720) {
            diskRes = 720;
        }
    }
    
    if ([[SettingsTool settings] fastCaptureMode]) {
        diskRes = 720;
    }

    switch (diskRes) {
        case 1080:
            avResolution = AVCaptureSessionPreset1920x1080;
            captureResolution.width = 1920;
            captureResolution.height = 1080;
            diskResolution.width = 1920;
            diskResolution.height = 1080;
            break;
        case 720:
            avResolution = AVCaptureSessionPreset1280x720;
            captureResolution.width = 1280;
            captureResolution.height = 720;
            diskResolution.width = 1280;
            diskResolution.height = 720;
            break;
        case 576:
            avResolution = AVCaptureSessionPreset1280x720;
            captureResolution.width = 1280;
            captureResolution.height = 720;
            diskResolution.width = 1024;
            diskResolution.height = 576;
            break;
        case 540:
            avResolution = AVCaptureSessionPresetiFrame960x540;
            captureResolution.width = 960;
            captureResolution.height = 540;
            diskResolution.width = 960;
            diskResolution.height = 540;
            break;
        case 480:
             avResolution = AVCaptureSessionPresetiFrame960x540;
            captureResolution.width = 960;
            captureResolution.height = 540;
            diskResolution.width = 854;
            diskResolution.height = 480;
            break;
        case 360:
             avResolution = AVCaptureSessionPresetiFrame960x540;
            captureResolution.width = 960;
            captureResolution.height = 540;
            diskResolution.width = 640;
            diskResolution.height = 360;
            break;
    }

    [appD handleRemoteSessionSetup];
    
    if ( (![[SettingsTool settings] isOldDevice]) && (![[SettingsTool settings] fastCaptureMode]) ) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        
        [filterTool rebuildFilterInfo:diskResolution.height];
        
        if ([[SettingsTool settings] advancedFiltersAvailable]) {
            if ([[SettingsTool settings] engineColorControl]) {
                [filterTool updateBrightness:[[SettingsTool settings] videoBrightness]];
                [filterTool updateContrast:[[SettingsTool settings] videoContrast]];
                [filterTool updateSaturation:[[SettingsTool settings] videoSaturation]];
            }
        }
        
        if (!_videoPreviewView ) {
            _videoPreviewView = [[GLKView alloc] initWithFrame:CGRectMake(0,0,self.frame.size.width, self.frame.size.height) context:_eaglContext];
            _videoPreviewView.enableSetNeedsDisplay = NO;
            _videoPreviewView.backgroundColor = [UIColor clearColor];
            [self positionVideoPreview];
            
            [self addSubview:_videoPreviewView];
        }
        
        _videoPreviewViewBounds = CGRectZero;
        _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
        _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;
        
        
        
        dispatch_async(_captureSessionQueue, ^(void) {
            NSError *error = nil;
            
            
            NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
            
            AVCaptureDevicePosition position = backCamera ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
            
            _videoDevice = nil;
            for (AVCaptureDevice *device in videoDevices)
            {
                if (device.position == position) {
                    _videoDevice = device;
                    break;
                }
            }
            
            if ( (!_videoDevice) && ([videoDevices count]>0) )
            {
                _videoDevice = [videoDevices objectAtIndex:0];
            }
            
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
            if (!videoDeviceInput)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"%@", [NSString stringWithFormat:@"Unable to obtain video device input, error: %@", error]);
                    [self stopCamera];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NoCameraFound" object:nil];
                });
                return;
            }
            
            AVCaptureDeviceInput *audioDeviceInput = nil;
            
            if (appD.audioRecordingAllowed) {
                NSLog(@"audioDevices:%@", [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]);
                if ( (!_audioDevice) && ([[SettingsTool settings] engineMicrophone]) ) {
                    _audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
                }
                
                if (_audioDevice)
                {
                    audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_audioDevice error:&error];
                    if (!audioDeviceInput)
                    {
                        NSLog(@"%@", [NSString stringWithFormat:@"Unable to obtain audio device input, error: %@", error]);
                        return;
                    }
                }
            }
            
            if (![_videoDevice supportsAVCaptureSessionPreset:avResolution])
            {
                NSLog(@"%@", [NSString stringWithFormat:@"Capture session preset not supported by video device: %@", avResolution]);
                return;
            }
            
                // CoreImage wants sd pixel format
            NSDictionary *outputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
            
            _captureSession = [[AVCaptureSession alloc] init];
            _captureSession.sessionPreset = avResolution;
            
            AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            videoDataOutput.videoSettings = outputSettings;
            videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
            [videoDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
            
            AVCaptureAudioDataOutput *audioDataOutput = nil;
            if (appD.audioRecordingAllowed && _audioDevice) {
                audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
                [audioDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
            }
            
            [_captureSession beginConfiguration];
            
            if (![_captureSession canAddOutput:videoDataOutput])
            {
                NSLog(@"Cannot add video data output");
                _captureSession = nil;
                return;
            }
            
            if (audioDataOutput)
            {
                if (![_captureSession canAddOutput:audioDataOutput])
                {
                    NSLog(@"Cannot add audio data output");
                    _captureSession = nil;
                    return;
                }
            }
            
            [_captureSession addInput:videoDeviceInput];
            
            [_captureSession addOutput:videoDataOutput];
            
            stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            [stillImageOutput setOutputSettings:@{ AVVideoCodecJPEG : AVVideoCodecKey }];
            if ([_captureSession canAddOutput:stillImageOutput]) {
                [_captureSession addOutput:stillImageOutput];
            } else {
                stillImageOutput = nil;
            }

            
            
            if (_audioDevice && audioDeviceInput)
            {
                [_captureSession addInput:audioDeviceInput];
                [_captureSession addOutput:audioDataOutput];
            }
            
            [self captureResolutionSelector];
            
            
            [_captureSession commitConfiguration];
            
            [_captureSession startRunning];
            
            [self updateFrameRate];
            [self updateStabilization];
            
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            
            if (appD.audioRecordingAllowed) {
                [self updateAudioCaptureSampleRate];
            }
            
            if ([[SettingsTool settings] focusMode] == 0) {
                newFocusReticlePos = CGPointMake(0.5,0.5);
            }
            
            if ([[SettingsTool settings] exposureMode] == 0) {
                newExposureReticlePos = CGPointMake(0.5,0.5);
            }
            
            [_videoDevice lockForConfiguration:&error];
            
            if (!error) {
                if ([_videoDevice isSmoothAutoFocusSupported]) {
                    [_videoDevice setSmoothAutoFocusEnabled:[[SettingsTool settings] focusSpeedSmooth]];
                }
                [_videoDevice unlockForConfiguration];
            }
            
            majorStateChange = 1;
            
            [self performSelectorOnMainThread:@selector(removeBusyIndicator) withObject:NO waitUntilDone:NO];
            
            [self performSelectorOnMainThread:@selector(updateVideoOrientation) withObject:nil waitUntilDone:YES];
            
            [self performSelectorOnMainThread:@selector(positionVideoPreview) withObject:nil waitUntilDone:YES];
            
            [self updateFrameRate];
            
        });
    } else {
        NSError *error = nil;
        
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        AVCaptureDevicePosition position = backCamera ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
        
        _videoDevice = nil;
        for (AVCaptureDevice *device in videoDevices)
        {
            if (device.position == position) {
                _videoDevice = device;
                break;
            }
        }
        
        if ( (!_videoDevice) && ([videoDevices count]>0) )
        {
            _videoDevice = [videoDevices objectAtIndex:0];
        }
        
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
        if (!videoDeviceInput)
        {
            NSLog(@"%@", [NSString stringWithFormat:@"Unable to obtain video device input, error: %@", error]);
            return;
        }
        
        AVCaptureDeviceInput *audioDeviceInput = nil;
        
        if (appD.audioRecordingAllowed) {
            NSLog(@"audioDevices:%@", [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]);
            if ( (!_audioDevice) && ([[SettingsTool settings] engineMicrophone]) ) {
                _audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            }
            
            if (_audioDevice)
            {
                audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_audioDevice error:&error];
                if (!audioDeviceInput)
                {
                    NSLog(@"%@", [NSString stringWithFormat:@"Unable to obtain audio device input, error: %@", error]);
                    return;
                }
            }
        }
        
        if (![_videoDevice supportsAVCaptureSessionPreset:avResolution])
        {
            NSLog(@"%@", [NSString stringWithFormat:@"Capture session preset not supported by video device: %@", avResolution]);
            return;
        }
   
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = avResolution;
        [_captureSession beginConfiguration];
        
        [_captureSession addInput:videoDeviceInput];
        
        if (_audioDevice && audioDeviceInput)
        {
            [_captureSession addInput:audioDeviceInput];
        }
        
        previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        movieFile = [[AVCaptureMovieFileOutput alloc ] init];
        movieFile.movieFragmentInterval = CMTimeMake(300,30);
        movieFile.minFreeDiskSpaceLimit = 80000000;
        
        if (![_captureSession canAddOutput:movieFile])
        {
            NSLog(@"Cannot add movie file output");
            _captureSession = nil;
            return;
        }
        
        [_captureSession addOutput:movieFile];
        
        previewLayer.frame =CGRectMake(0,0,self.frame.size.width, self.frame.size.height);
        videoPreviewOld = [[UIView alloc] init];
        videoPreviewOld.backgroundColor = [UIColor clearColor];
        videoPreviewOld.frame = previewLayer.frame;
        [self addSubview:videoPreviewOld];
        [videoPreviewOld.layer addSublayer:previewLayer];
        [self positionVideoPreview];
        
        if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
            videoPreviewOld.alpha = 0.0f;
            [self performSelector:@selector(positionVideoPreview) withObject:nil afterDelay:1.0f];
        }
        
   

        [self captureResolutionSelector];
        
        
        stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        [stillImageOutput setOutputSettings:@{ AVVideoCodecJPEG : AVVideoCodecKey }];
        if ([_captureSession canAddOutput:stillImageOutput]) {
            [_captureSession addOutput:stillImageOutput];
        } else {
            stillImageOutput = nil;
        }

        
        if (appD.audioRecordingAllowed) {
            [self updateAudioCaptureSampleRate];
        }
        
        AVCaptureAudioDataOutput *audioDataOutput = nil;
        if (appD.audioRecordingAllowed && _audioDevice) {
            audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        }
        if ([_captureSession canAddOutput:audioDataOutput]) {
            [_captureSession addOutput:audioDataOutput];
        }
        
        
        [_captureSession commitConfiguration];
        
        [_captureSession startRunning];
        
        [self updateFrameRate];
        [self updateStabilization];
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
   
        
        if ([[SettingsTool settings] focusMode] == 0) {
            newFocusReticlePos = CGPointMake(0.5,0.5);
        }
        
        if ([[SettingsTool settings] exposureMode] == 0) {
            newExposureReticlePos = CGPointMake(0.5,0.5);
        }
        
        [_videoDevice lockForConfiguration:&error];
        
        if (!error) {
            if ([_videoDevice isSmoothAutoFocusSupported]) {
                [_videoDevice setSmoothAutoFocusEnabled:[[SettingsTool settings] focusSpeedSmooth]];
            }
            [_videoDevice unlockForConfiguration];
        }
        
        majorStateChange = 1;
        
        [self performSelectorOnMainThread:@selector(removeBusyIndicator) withObject:NO waitUntilDone:NO];
        
        [self performSelectorOnMainThread:@selector(updateVideoOrientation) withObject:nil waitUntilDone:YES];
        
        [self performSelectorOnMainThread:@selector(positionVideoPreview) withObject:nil waitUntilDone:YES];
        
        [self updateFrameRate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [NSThread sleepForTimeInterval:0.1];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setupVideoConnectionOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
                });
            });
        });
    }
    
    [self positionVideoPreview];

    _frameRateCalculator = [[FrameRateCalculator alloc] init];


}


-(void)updateReticlePositions {
    if ([[SettingsTool settings] focusMode] == 0) {
        newFocusReticlePos = CGPointMake(0.5,0.5);
    }
    
    if ([[SettingsTool settings] exposureMode] == 0) {
        newExposureReticlePos = CGPointMake(0.5,0.5);
    }
}

-(void)zoomToLevel:(float)level withSpeed:(float)rate {
    
    float maxZoom = _videoDevice.activeFormat.videoMaxZoomFactor;
    
    if (maxZoom <= 1.0f) {
        return;
    }
    
    if (level <= 1.0f) {
        level = 1.0f;
    }
    
    if (level > maxZoom) {
        level = maxZoom;
    }
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    
    if (error) {
        return;
    }

    [_videoDevice rampToVideoZoomFactor:level withRate:rate];
    [_videoDevice unlockForConfiguration];
}



-(float)currentZoomLevel {
    float level = 1.0f;
   
    level = _videoDevice.videoZoomFactor;
    
    return level;
}

-(void)setZoomRate:(float)rate {
    [[SettingsTool settings] setZoomRate:rate];
    zoomRate = rate;
}


-(void)updateThirdsGuide:(BOOL)enabled {
    guidePane.thirdsEnabled = enabled;
    [guidePane setNeedsDisplay];
    
}

-(void)updateFramingGuide:(NSInteger)mode {
    guidePane.framingMode = (int)mode;
    [guidePane setNeedsDisplay];
    
}

-(void)updateZoomUI {
    
}

- (BOOL)shouldAutorotate  {
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations  {
    NSInteger supported = UIInterfaceOrientationMaskLandscape;
    return supported;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
        // NSLog(@"videoVC:didRotateFromInterfaceOrientation "); // is actually to orientation
    if ([self isLoaded]) {
        [filterTool rebuildFilterInfo:[[SettingsTool settings] captureOutputResolution]];
        [self setupVideoConnectionOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    }
    
    [self positionVideoPreview];
    [self bringSubviewToFront:[[SyncManager manager] progressContainer]];
    
    if (videoPreviewOld) {
        videoPreviewOld.alpha = 0.0f;
        [self performSelector:@selector(positionVideoPreview) withObject:nil afterDelay:1.0f];
    }
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        if (![self isRunning]) {
            [self performSelector:@selector(startCamera) withObject:nil afterDelay:0.1];
        }
    }
}


-(NSNumber *)majorChangeChangeReportAndClear {
    NSNumber *s = [NSNumber numberWithBool:(majorStateChange == 1)];
    majorStateChange = 0;
    return s;
}

-(NSDictionary *)generateCameraStatusDictForRemote {
    NSDictionary *dict = @{
                           @"recording" : [NSNumber numberWithBool:[self isRecording]],
                           @"recordTime" : [NSNumber numberWithInteger:elapsed],
                           @"zoomRate" : [NSNumber numberWithFloat:zoomRate],
                           @"zoomScale" : [NSNumber numberWithFloat:_videoDevice.videoZoomFactor],
                           @"majorStateChange" : [self majorChangeChangeReportAndClear],
                           @"cameraLoaded" : [NSNumber numberWithBool:[self isLoaded]],
                           @"focusReticlePos" : [NSValue valueWithCGPoint:lastFocusReticlePos],
                           @"exposureReticlePos" : [NSValue valueWithCGPoint:lastExposureReticlePos],
                           };
    
    
    
    return dict;
 
}

-(void)sendStatusReport:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"responseWithStatusReport" object:[self generateCameraStatusDictForRemote]];
}

-(void)abortRecording {
    [self stopRecording];
}

-(NSInteger )currentISO {
    StatusReporter *reporter = [StatusReporter manager];
    return reporter.isoRating;
}


-(void)updateStatusInfo:(NSDictionary *)exifDict {
    
    StatusReporter *reporter = [StatusReporter manager];
    reporter.FNumber = [[exifDict objectForKey:@"FNumber"] floatValue];
    reporter.focalLength = [[exifDict objectForKey:@"FocalLength"] floatValue];
    reporter.isoRating = [[[exifDict objectForKey:@"ISOSpeedRatings"] objectAtIndex:0] intValue];
    reporter.shutterSpeedRational = [exifDict objectForKey:@"ShutterSpeedValue"];
    reporter.aperture = [exifDict objectForKey:@"ApertureValue"];
    reporter.currentZoomLevel = [self currentZoomLevel];
    
    NSInteger isoLock = [[SettingsTool settings] isoLock];
    
    if (isoLock > 0) {
        if (reporter.isoRating == isoLock) {
            reporter.huntingISO = NO;
            [self performSelectorOnMainThread:@selector(lockExposureForISO) withObject:nil waitUntilDone:YES];
        } else if ([self currentExposureLock]) {
            [self performSelectorOnMainThread:@selector(unlockExposureForISO) withObject:nil waitUntilDone:YES];
            reporter.huntingISO = YES;
        } else {
            reporter.huntingISO = YES;
        }
    } else {
        reporter.huntingISO = NO;
    }

    if (changeSettleTime <= 0.0f) {
        reporter.badFrameRate = reporter.lastReportedFrameRate   < _videoDevice.activeVideoMaxFrameDuration.timescale;
    } else {
        reporter.badFrameRate = NO;
    }
    
}

-(void)lockExposureForISO {
    [self setExposureLock:YES];
}

-(void)unlockExposureForISO {
    [self setExposureLock:NO];
}


-(void)flashScreenForStill:(NSNotification *)n {
    UIView *flashView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [[self window] addSubview:flashView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                     }
     ];
    if (!self.isRecording) {
        [shutterPlayer play];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
    });
    
    
    CFDictionaryRef exifAttachments = CMGetAttachment( sampleBuffer, kCGImagePropertyExifDictionary, NULL);
    if (exifAttachments) {
        NSDictionary *exifDict = (__bridge NSDictionary *)(exifAttachments);
        [self performSelectorOnMainThread:@selector(updateStatusInfo:) withObject:[exifDict copy] waitUntilDone:NO];
    }

    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    // write the audio data if it's from the audio connection
    if (mediaType == kCMMediaType_Audio)
    {
    
        CMFormatDescriptionRef tmpDesc = _currentAudioSampleBufferFormatDescription;
        _currentAudioSampleBufferFormatDescription = formatDesc;
        CFRetain(_currentAudioSampleBufferFormatDescription);
        
        if (tmpDesc)
            CFRelease(tmpDesc);
        
        
        // we need to retain the sample buffer to keep it alive across the different queues (threads)
        if (_assetWriter &&
            _assetWriterAudioInput.readyForMoreMediaData &&
            ![_assetWriterAudioInput appendSampleBuffer:sampleBuffer])
        {
            NSLog(@"Cannot write audio data, recording aborted");
            [self abortRecording];
        }
        
        return;
    }

    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [_frameRateCalculator calculateFramerateAtTimestamp:timestamp];
    
        //CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
   
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *sourceImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
    

    
    CIImage *filteredImage = [filterTool filterImageWithSourceImage:sourceImage withContext:_ciContext];
    
    CGRect sourceExtent = filteredImage.extent;
    
    if (filteredImage.extent.size.width != diskResolution.width) {
            // NSLog(@"Converting from %@ to %d,%d", [NSValue valueWithCGRect:sourceExtent ], diskResolution.width, diskResolution.height);
       filteredImage = [filteredImage imageByCroppingToRect:CGRectInset(sourceExtent, (sourceExtent.size.width - diskResolution.width)/2.0f , (sourceExtent.size.height - diskResolution.height) /2.0f)];
        sourceExtent = filteredImage.extent;
    }
    
    if (sourceExtent.size.width != diskResolution.width) {
           NSLog(@"width mismatch still!");
    }
    
    
    CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    CGFloat previewAspect = _videoPreviewViewBounds.size.width  / _videoPreviewViewBounds.size.height;
    
    // we want to maintain the aspect radio of the screen size, so we clip the video image
    CGRect drawRect = sourceExtent;
    if (sourceAspect > previewAspect)
    {
        // use full height of the video image, and center crop the width
        drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
        drawRect.size.width = drawRect.size.height * previewAspect;
    }
    else
    {
        // use full width of the video image, and center crop the height
        drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
        drawRect.size.height = drawRect.size.width / previewAspect;
    }
    
    if (_assetWriter == nil)
    {
        if (!dontUpdateVideoViewAtPresent)   {
            [_videoPreviewView bindDrawable];
            
            if (_eaglContext != [EAGLContext currentContext])
                [EAGLContext setCurrentContext:_eaglContext];
            
                // clear eagl view to grey
            glClearColor(0.5, 0.5, 0.5, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);
            
                // set the blend mode to "source over" so that CI will use that
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            
            if (filteredImage) {
                [_ciContext drawImage:filteredImage inRect:_videoPreviewViewBounds fromRect:drawRect];
                [_videoPreviewView display];
            }
        }
    }
    else
    {
        // if we need to write video and haven't started yet, start writing
        if (!_videoWritingStarted)
        {
            _videoWritingStarted = YES;
            
            _assetWriter.metadata = [self updateMetadataForAssetWriter:_assetWriter.metadata];
            
            BOOL success = [_assetWriter startWriting];
            if (!success)
            {
                NSLog(@"Cannot write video data, recording aborted");
                [self abortRecording];
                return;
            }
            CMTime futureOneHalfSecond = CMTimeAdd(timestamp, CMTimeMake(timestamp.timescale / 2, timestamp.timescale));
            [_assetWriter startSessionAtSourceTime:futureOneHalfSecond];
            _videoWritingStartTime = timestamp;
            self.currentVideoTime = _videoWritingStartTime;
        }
        
        CVPixelBufferRef renderedOutputPixelBuffer = NULL;
        
        OSStatus err = CVPixelBufferPoolCreatePixelBuffer(nil, _assetWriterInputPixelBufferAdaptor.pixelBufferPool, &renderedOutputPixelBuffer);
        if (err)
        {
            NSLog(@"Cannot obtain a pixel buffer from the buffer pool");
            return;
        }
        
        // render the filtered image back to the pixel buffer (no locking needed as CIContext's render method will do that
        if (filteredImage)
            [_ciContext render:filteredImage toCVPixelBuffer:renderedOutputPixelBuffer bounds:[filteredImage extent] colorSpace:sDeviceRgbColorSpace];
        
        // pass option nil to enable color matching at the output, otherwise the color will be off
        CIImage *drawImage = [CIImage imageWithCVPixelBuffer:renderedOutputPixelBuffer options:nil];
       
        CGRect sourceExtent = drawImage.extent;
        
        if (sourceExtent.size.width != diskResolution.width) {
            NSLog(@"width mismatch still!");
        }
        
        CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
        CGFloat previewAspect = _videoPreviewViewBounds.size.width  / _videoPreviewViewBounds.size.height;
        
        if (sourceAspect > previewAspect)
        {
            // use full height of the video image, and center crop the width
            drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
            drawRect.size.width = drawRect.size.height * previewAspect;
        }
        else
        {
            // use full width of the video image, and center crop the height
            drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
            drawRect.size.height = drawRect.size.width / previewAspect;
        }

        [_videoPreviewView bindDrawable];
        [_ciContext drawImage:drawImage inRect:_videoPreviewViewBounds fromRect:CGRectMake(0,0, diskResolution.width, diskResolution.height)];
        
        [_videoPreviewView display];
        
        
        self.currentVideoTime = timestamp;
        
        // write the video data
        if (_assetWriterVideoInput.readyForMoreMediaData)
            [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:renderedOutputPixelBuffer withPresentationTime:timestamp];
        
        CVPixelBufferRelease(renderedOutputPixelBuffer);
    }
}

-(void)dontUpdateVideoView:(NSNumber *)update {
        //NSLog(@"%@updating video view", [update boolValue] ? @"" : @"Not ");
    dontUpdateVideoViewAtPresent  = [update boolValue];
}

-(BOOL)frontCameraSupported {
    BOOL answer = NO;
    
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        if (device.position == position) {
            if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
                answer = YES;
            }
            break;
        }
    }

    return answer;
}


@end
