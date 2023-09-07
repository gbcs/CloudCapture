//
//  VideoCaptureViewController.h
//  iArchiver
//
//  Created by Gary Barnett on 5/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>
#import <GLKit/GLKit.h>

@interface VideoCaptureView: UIView <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) NSString *videoPath;
@property (assign, atomic) CMTime currentVideoTime;

-(BOOL)isLoaded;
-(BOOL)isRunning;
-(BOOL)isRecording;

-(void)stopRecording;
-(void)startRecording;
-(void)restartCamera;
-(void)startCamera;
-(void)stopCamera;

-(void)updateFrameRate;
-(void)updateStabilization;
-(void)updateAudioCaptureSampleRate;

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

-(BOOL)currentFocusLock;
-(NSInteger)currentFocusRange;

-(void)setFocusRange:(NSInteger)which;
-(void)setFocusLock:(BOOL)enabled;
-(void)setFocusSpeedSmooth:(BOOL)which;

-(BOOL)currentWhiteBalanceLock;
-(void)setWhiteBalanceLock:(BOOL)enabled;

-(BOOL)currentExposureLock;
-(void)setExposureLock:(BOOL)enabled;
-(void)updateInterfaceHidden:(BOOL)hidden;

-(void)updateBrightness:(float)val;
-(void)updateContrast:(float)val;
-(void)updateSaturation:(float)val;

-(void)lightTorch:(float)level;
-(void)extinguishTorch;
-(float)torchSetting;

-(NSInteger)currentISO;

-(void)updateThirdsGuide:(BOOL)enabled;
-(void)updateFramingGuide:(NSInteger)mode;

-(void)updateZoomUI;

-(float)currentZoomLevel;
-(void)zoomToLevel:(float)level withSpeed:(float)rate;
-(void)setZoomRate:(float)rate;
-(void)stopZoomingImmediately;
-(float)maxZoomLevel;
-(void)showGuidePaneHorizon:(BOOL)enabled;
-(void)updateReticlePositions;
-(BOOL)zoomSupported;

-(void)takeStill;

-(NSDictionary *)generateCameraStatusDictForRemote;

-(void)updateFilterAttributesWithName:(NSString *)name andDict:(NSDictionary *)attribs;

-(void)updateFramingGuideOffset:(CGFloat )offset;

-(void)addSettleTime:(CGFloat)amount;

-(void)dontUpdateVideoView:(NSNumber *)update;

-(void)positionVideoPreview;
-(BOOL)frontCameraSupported;

@end

