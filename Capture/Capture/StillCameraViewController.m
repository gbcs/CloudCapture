//
//  StillCameraViewController.m
//  Capture
//
//  Created by Gary  Barnett on 4/3/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "StillCameraViewController.h"
#import "FilterTool.h"
#import <ImageIO/ImageIO.h>
#import <CoreText/CoreText.h>
#import <GLKit/GLKit.h>
#import <Accelerate/Accelerate.h>
#import "HistogramView.h"
#import <ImageIO/ImageIO.h>
#import <CoreVideo/CoreVideo.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AppDelegate.h"
#import "StillControlBarView.h"
#import "UIImage+NegativeImage.h"

@interface StillCameraViewController ()

@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) EAGLContext *eaglContext;
@property (nonatomic, strong) GLKView *videoPreviewView;
@property (nonatomic, assign) CGRect videoPreviewViewBounds;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) FilterTool *filterTool;
@property (nonatomic, assign) BOOL shouldTakeStill;
@property (nonatomic, assign) BOOL takingStill;
@property (nonatomic, strong) dispatch_queue_t captureSessionQueue;
@property (nonatomic, assign) BOOL dontUpdateVideoViewAtPresent;
@property (nonatomic, strong) IBOutlet MotionCircle *motionCircle;
@property (nonatomic, strong) CMDeviceMotion *lastMotion;
@property (nonatomic, strong) CMAttitude *startingAttitude;
@property (nonatomic, assign) BOOL currentlyStill;
@property (nonatomic, assign) BOOL waitingOnDeviceToStopMoving;
@property (nonatomic, assign) BOOL wasNotUpdating;

@end

@implementation StillCameraViewController


static CGColorSpaceRef sDeviceRgbColorSpace = NULL;

-(void)motionCircleCenterTapped:(id)sender {
    _startingAttitude = [_lastMotion.attitude copy];
}


-(void)motionUpdate:(NSNotification *)n {
    _lastMotion = (CMDeviceMotion *)n.object;
    
    if (!_startingAttitude) {
        _startingAttitude = _lastMotion.attitude;
        return;
    }
    
    CMAttitude *delta = [_lastMotion.attitude copy];
    [delta multiplyByInverseOfAttitude:_startingAttitude];

    _startingAttitude = _lastMotion.attitude;
    
    CGFloat r = delta.roll * 57.2957795;
    CGFloat y = delta.yaw * 57.2957795;
    CGFloat p = delta.pitch * 57.2957795;
    
    dispatch_async(dispatch_get_main_queue(), ^{
         [_motionCircle setPitch:p andYaw:y andRoll:r];
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

-(StillControlBarView *)barView {
    StillControlBarView  *bv = (StillControlBarView *)[self.view viewWithTag:42];
    
    if (!bv) {
        bv = [[StillControlBarView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:bv];
    }
    
    return bv;
}

- (void)viewDidLoad
{
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(motionUpdate:) name:@"motionUpdate" object:nil];
    
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    _captureSessionQueue = dispatch_queue_create("capture_session_queue", NULL);
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];


    
    
    
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (void)dealloc
{   //NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
   
    _videoPreviewView = nil;
    _ciContext = nil;
    _eaglContext = nil;
    _videoDevice = nil;
    _captureSession = nil;
    _stillImageOutput = nil;
    _filterTool = nil;
 
}

-(void)cleanup {
    _eaglContext = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"commandSendStatus" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
}


-(void)stopCamera {
    if (!_captureSession ) {
        return;
    }
   

    if (_captureSession && _captureSession.running) {
        [_captureSession stopRunning];
          
        _captureSession = nil;
        _videoDevice = nil;
    }
    
    if (_videoPreviewView ) {
        [_videoPreviewView deleteDrawable];
        [_videoPreviewView removeFromSuperview];
        _videoPreviewView = nil;
    }
    
    _ciContext = nil;
    
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
 
}


-(void)takeStill {
    if (_takingStill) {
        return;
    }
    
    if (!_currentlyStill) {
        _waitingOnDeviceToStopMoving = YES;
        return;
    }
    
    _takingStill = YES;
    _waitingOnDeviceToStopMoving = NO;

    
    AVCaptureOutput *videoOutput = [[_captureSession outputs] firstObject];
    AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
 
    CMFormatDescriptionRef format = _videoDevice.activeFormat.formatDescription;
    CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(format);
    NSLog(@"camera resolution:%@:%@", @(dim.width), @(dim.height));
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        NSLog(@"Still image size: %@", @([data length]));
        
        
        NSString *pathStr = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"unreviewedStills"]
                             stringByAppendingPathComponent:[[UtilityBag bag] pathForNewUnreviewedStillWithExtension:@"jpeg"]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [data writeToFile:pathStr atomically:NO];
            _takingStill = NO;
            if (_shouldTakeStill) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self takeStill];
                });
            }
        });
    }];
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
    AVCaptureOutput *videoOutput = [[_captureSession outputs] objectAtIndex:1];
    AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (![videoConnection isVideoOrientationSupported]) {
        NSLog(@"Ignoring setupVideoConnectionOrientationForOrientation: not isVideoOrientationSupported");
        return;
    }
     
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIInterfaceOrientationPortrait:
            videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            videoConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
    }
    
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
}

-(void)setVideoPreviewFrame:(CGRect )r {
    _videoPreviewView.frame = r;
}

-(void)positionVideoPreview {

    CGSize motionCircleSize = _motionCircle.frame.size;
    
    CGRect previewFrame = CGRectZero;
    CGRect barFrame = CGRectZero;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (self.view.frame.size.width == 1024) {
            CGFloat x = 20;
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                x = 1024 - 820;
                _controlBar.frame = CGRectMake(0,(768.0/2.0)-(320.0/2.0),50,320);
                _controlBar2.frame = CGRectMake(50,(768.0/2.0)-(320.0/2.0),50,320);
                _motionCircle.frame = CGRectMake(950,700, motionCircleSize.width, motionCircleSize.height);
            } else {
                _controlBar.frame = CGRectMake(924,(768.0/2.0)-(320.0/2.0),50,320);
                _controlBar2.frame = CGRectMake(924 + 50,(768.0/2.0)-(320.0/2.0),50,320);
                _motionCircle.frame = CGRectMake(10,10, motionCircleSize.width, motionCircleSize.height);
            }
            previewFrame = CGRectMake(x,84,800,600);
        } else {
            CGFloat y = 20;
            _controlBar.frame = CGRectMake(0,(1024.0/2.0)-(320.0/2.0),50,320);
            _controlBar2.frame = CGRectMake(668 + 50,(1024.0/2.0)-(320.0/2.0),50,320);
            
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) {
                _motionCircle.frame = CGRectMake(10,950, motionCircleSize.width, motionCircleSize.height);
                y = 1024 - 820;
            } else {
                _motionCircle.frame = CGRectMake(700,10, motionCircleSize.width, motionCircleSize.height);
            }
            previewFrame = CGRectMake(84,y,600,800);
            
        }
    } else {
        if (self.view.frame.size.width == 320) {
            if (self.view.frame.size.height > 480) {
                CGFloat yR = self.view.frame.size.height - 427;
                CGFloat y = 0;
                if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) {
                    y = yR;
                    _controlBar.frame = CGRectMake(0,0, 320, (yR / 2.0f));
                    _controlBar2.frame = CGRectMake(0,0 + (yR / 2.0f), 320, (yR / 2.0f));
                } else {
                    _controlBar.frame = CGRectMake(0,self.view.frame.size.height - yR, 320, (yR / 2.0f));
                    _controlBar2.frame = CGRectMake(0,self.view.frame.size.height - yR +(yR / 2.0f), 320, (yR / 2.0f));
                }
                previewFrame = CGRectMake(0,y,320,427);
            } else {
                CGFloat yR = self.view.frame.size.height - 400;
                CGFloat y = 0;
                if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) {
                    y = yR;
                    _controlBar.frame = CGRectMake(0,0, 320, (yR / 2.0f));
                    _controlBar2.frame = CGRectMake(0,0 + (yR / 2.0f), 320, (yR / 2.0f));
                } else {
                    _controlBar.frame = CGRectMake(0,self.view.frame.size.height - yR, 320, (yR / 2.0f));
                    _controlBar2.frame = CGRectMake(0,self.view.frame.size.height - yR + (yR / 2.0f), 320, (yR / 2.0f));
                }
                previewFrame = CGRectMake(10,y,300,400);
            }
            
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) {
                _motionCircle.frame = CGRectMake(10,self.view.frame.size.height - 60, motionCircleSize.width, motionCircleSize.height);
            } else {
                _motionCircle.frame = CGRectMake(270,10, motionCircleSize.width, motionCircleSize.height);
            }
        } else if (self.view.frame.size.width == 480) {
            CGFloat x = 0;
            CGFloat xR = self.view.frame.size.width - 427;
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                x = xR;
                _controlBar.frame = CGRectMake(0,0,(xR / 2.0f),320);
                _controlBar2.frame = CGRectMake((xR / 2.0f),0,(xR / 2.0f),320);
            } else {
                _controlBar.frame = CGRectMake(self.view.frame.size.width - xR,0,(xR / 2.0f),320);
                _controlBar2.frame = CGRectMake(self.view.frame.size.width - xR + (xR / 2.0f),0,(xR / 2.0f),320);
            }
            previewFrame = CGRectMake(x, 0, 400, 300);
            
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                _motionCircle.frame = CGRectMake(420,250, motionCircleSize.width, motionCircleSize.height);
            } else {
                _motionCircle.frame = CGRectMake(10,10, motionCircleSize.width, motionCircleSize.height);
            }
        } else {
            CGFloat w = self.view.frame.size.height * (4.0 / 3.0);
            CGFloat bw = self.view.frame.size.width - w;
            CGFloat x = 0;
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                x = self.view.frame.size.width - w;
                _controlBar.frame = CGRectMake(0,0,bw / 2.0f,320);
                _controlBar2.frame = CGRectMake(bw / 2.0f,0,bw / 2.0f,320);
            } else {
                _controlBar.frame = CGRectMake(self.view.frame.size.width - bw,0,bw / 2.0f,320);
                _controlBar2.frame = CGRectMake(self.view.frame.size.width - bw + (bw / 2.0f),0,bw / 2.0f,320);
            }
            previewFrame = CGRectMake(x, 0, w, self.view.frame.size.height);
            
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
                _motionCircle.frame = CGRectMake(self.view.frame.size.width - 70,250, motionCircleSize.width, motionCircleSize.height);
            } else {
                _motionCircle.frame = CGRectMake(10,10, motionCircleSize.width, motionCircleSize.height);
            }
        }
    }
    
    [self setVideoPreviewFrame:previewFrame];
    
    float scale = [UIScreen mainScreen].scale;
    _videoPreviewView.alpha = 1.0f;
    _videoPreviewViewBounds = CGRectZero;
    _videoPreviewViewBounds.size.width =  previewFrame.size.width * scale;
    _videoPreviewViewBounds.size.height = previewFrame.size.height * scale;
    
    [self.view sendSubviewToBack:_videoPreviewView];
    
    [self barView].frame = barFrame;
    
    [_videoPreviewView bindDrawable];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self performSelector:@selector(startCamera) withObject:nil afterDelay:0.1f];
}

-(void)captureResolutionSelector {
    AVCaptureDeviceFormat *largest = nil;
    CMFormatDescriptionRef largestFormat = nil;
    
    for (AVCaptureDeviceFormat * currdf in _videoDevice.formats)
    {
        CMFormatDescriptionRef myCMFormatDescriptionRef= currdf.formatDescription;
        FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(myCMFormatDescriptionRef);
        
        if (mediaSubType != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            continue;
        }
        
        if (currdf.videoBinned) {
            continue;
        }
        
        if (!largest) {
            largest = currdf;
            largestFormat = myCMFormatDescriptionRef;
        }
        
        if (mediaSubType==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            CMVideoDimensions largestDim = CMVideoFormatDescriptionGetDimensions(largestFormat);
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(myCMFormatDescriptionRef);
            if (dimensions.width > largestDim.width) {
                largest = currdf;
                largestFormat = myCMFormatDescriptionRef;
            }
        }
    }
    
    NSError *error = nil;
    [_videoDevice lockForConfiguration:&error];
    if (!error) {
        [_videoDevice setActiveFormat:largest];
        [_videoDevice unlockForConfiguration];
        CMFormatDescriptionRef format = _videoDevice.activeFormat.formatDescription;
        CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(format);
        NSLog(@"camera resolution:%@:%@", @(dim.width), @(dim.height));
    } else {
        NSLog(@"unable to lock for captureResolutionSelector");
    }
    
    
}


-(void)startCamera {
    if (_captureSession) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sDeviceRgbColorSpace = CGColorSpaceCreateDeviceRGB();
    });
    
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : (__bridge id)sDeviceRgbColorSpace } ];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  
    if (!_videoPreviewView ) {
        _videoPreviewView = [[GLKView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height) context:_eaglContext];
        _videoPreviewView.enableSetNeedsDisplay = NO;
        _videoPreviewView.backgroundColor = [UIColor clearColor];
        [self positionVideoPreview];
        
        [self.view addSubview:_videoPreviewView];
    }
    
    _videoPreviewViewBounds = CGRectZero;
    _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;
    
    dispatch_async(_captureSessionQueue, ^(void) {
        [_videoPreviewView bindDrawable];
    });
    
    NSError *error = nil;
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    BOOL backCamera = YES;
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
        });
        return;
    }
    
   
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession beginConfiguration];
    
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]};
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [videoDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
    
    
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    
    [_stillImageOutput setOutputSettings:@{ AVVideoCodecJPEG : AVVideoCodecKey }];
    
    
    if ([_captureSession canAddOutput:_stillImageOutput]) {
        [_captureSession addOutput:_stillImageOutput];
    } else {
        _stillImageOutput = nil;
    }

    
    if (![_captureSession canAddOutput:videoDataOutput])
    {
        NSLog(@"Cannot add video data output");
        _captureSession = nil;
        return;
    }
    
    [_captureSession addInput:videoDeviceInput];
    
    [_captureSession addOutput:videoDataOutput];
   
    
    [_captureSession commitConfiguration];
    
    [_captureSession startRunning];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self performSelector:@selector(captureResolutionSelector) withObject:nil afterDelay:0.1];
    
    _dontUpdateVideoViewAtPresent = YES;
    
    StillControlBarView *bv = [self barView];
    bv.hidden = NO;
    
    _controlBar.hidden = NO;
    
    [self updateVideoOrientation];
   
    [self.view bringSubviewToFront:_motionCircle];
    
    [self performSelector:@selector(allowPreview) withObject:nil afterDelay:0.2];
    
}

-(void)allowPreview {
    _dontUpdateVideoViewAtPresent = NO;
}

- (BOOL)shouldAutorotate  {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appD.allowRotation;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (NSUInteger)supportedInterfaceOrientations  {
    NSInteger supported = UIInterfaceOrientationMaskLandscape;
    return supported;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self didRotateFromInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _wasNotUpdating = _dontUpdateVideoViewAtPresent;
    _dontUpdateVideoViewAtPresent = YES;
    _videoPreviewView.alpha = 0.0f;
    _controlBar.alpha = 0.0f;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (_captureSession) {
        [self setupVideoConnectionOrientationForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    }
    
    [self positionVideoPreview];
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        if (!_captureSession) {
            [self performSelector:@selector(startCamera) withObject:nil afterDelay:0.1];
        }
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        _dontUpdateVideoViewAtPresent = _wasNotUpdating;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5f animations:^{
                _videoPreviewView.alpha = 1.0f;
                _controlBar.alpha = 1.0f;
            }];
        });
    });
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
    reporter.currentZoomLevel = 1;
    

}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (_dontUpdateVideoViewAtPresent) {
        return;
    }
    
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
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *sourceImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
    
    CIImage *filteredImage = sourceImage;
    
    CGRect sourceExtent = filteredImage.extent;
    
    CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    CGFloat previewAspect = _videoPreviewViewBounds.size.width  / _videoPreviewViewBounds.size.height;
    
    // we want to maintain the aspect radio of the screen size, so we clip the video image
    CGRect drawRect = sourceExtent;
    if (sourceAspect < previewAspect)
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
    
    if (!_dontUpdateVideoViewAtPresent)   {
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

-(BOOL)frontCameraSupported {
    BOOL answer = NO;
    
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        if (device.position == position) {
            if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPresetPhoto]) {
                answer = YES;
            }
            break;
        }
    }
    
    return answer;
}

-(void)deviceMotionStatusIsStill:(BOOL)still {
    _currentlyStill = still;
    if (_waitingOnDeviceToStopMoving && still && (!_takingStill)) {
        _waitingOnDeviceToStopMoving = NO;
        [self takeStill];
    }
}

-(void)userStartedPressingRecordButton {
    _shouldTakeStill = YES;
    [self takeStill];
}

-(void)userStoppedPressingRecordButton {
    _shouldTakeStill = NO;
}

-(void)userTappedExitButton {
    [self stopCamera];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)userTappedOptionsButton {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"popAndLoadPhotoLibrary" object:nil];
}

-(void)userTappedPhotoButton {
    
}

-(void)userTappedFrontBackButton {
    
}

-(void)userTappedWhiteBalanceButton {
    
}

-(void)userTappedExposureButton {
    
}

-(void)userTappedFocusButton {
    
}

-(void)usertappedFlashButton {
    
}

@end
