//
//  SettingsTool.h
//  Capture
//
//  Created by Gary Barnett on 7/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSelectedAudio 0
#define kSelectedCamera 1
#define kSelectedResolution 2
#define kSelectedFrameRate 3
#define kSelectedFocus 4
#define kSelectedWhiteaBalance 5
#define kSelectedExposure 6
#define kSelectedGuide 7
#define kSelectedTorch 8
#define kSelectedZoom 9
#define kSelectedHistogram 10
#define kSelectedBrightness 11
#define kSelectedContrast 12
#define kSelectedSaturation 13


@interface SettingsTool : NSObject
@property (strong, nonatomic) NSString *platformString;

+ (SettingsTool*)settings;

#define kPreviewDataWidth 320
#define kPreviewDataHeight 180

#define kVideoFrameBufferSize kPreviewDataWidth*kPreviewDataHeight

-(BOOL)isOldDevice;

- (BOOL)isiPodTouch5;
- (BOOL)isiPhone4;
- (BOOL)isiPhone5;
- (BOOL)isiPhone5S;
- (BOOL)isiPhone4S;
- (BOOL)isiPad2;
- (BOOL)isiPad3;
- (BOOL)isIPadMini;
- (BOOL)isiPadAir;

-(BOOL)audioMonitoring;
-(void)setAudioMonitoring:(BOOL)enabled;

-(double)audioSamplerate;
-(void)setAudioSamplerate:(double)rate;

-(BOOL)audioOutputEncodingIsAAC;
-(void)setAudioOutputEncodingIsAAC:(BOOL)enabled;

-(NSInteger)audioAACQuality;
-(void)setAudioAACQuality:(NSInteger)quality;


-(BOOL)cameraIsBack;
-(void)setCameraIsBack:(BOOL)enabled;

-(BOOL)cameraISEnabled;
-(void)setCameraISEnabled:(BOOL)enabled;

-(BOOL)fastCaptureMode;
-(void)setFastCaptureMode:(BOOL)enabled;

-(BOOL)cameraFlipEnabled;
-(void)setCameraFlipEnabled:(BOOL)enabled;

-(NSInteger)captureOutputResolution;
-(void)setCaptureOutputResolution:(NSInteger)val;

//from video recorder; update

-(NSInteger)videoCameraFrameRate;
-(void)setVideoCameraFrameRate:(NSInteger)resolution;

-(NSInteger)videoCameraAutoStopDuration;
-(void)setVideoCameraAutoStopDuration:(NSInteger)duration;

-(float)videoCameraVideoDataRate1080;
-(void)setVideoCameraVideoDataRate1080:(float)rate;

-(float)videoCameraVideoDataRate720;
-(void)setVideoCameraVideoDataRate720:(float)rate;

-(float)videoCameraVideoDataRate576;
-(void)setVideoCameraVideoDataRate576:(float)rate;

-(float)videoCameraVideoDataRate540;
-(void)setVideoCameraVideoDataRate540:(float)rate;

-(float)videoCameraVideoDataRate480;
-(void)setVideoCameraVideoDataRate480:(float)rate;

-(float)videoCameraVideoDataRate360;
-(void)setVideoCameraVideoDataRate360:(float)rate;

-(float)videoCameraVideoDataRateFastCaptureMode;
-(void)setVideoCameraVideoDataRateFastCaptureMode:(float)rate;

-(NSInteger)focusMode;
-(NSInteger)focusRange;
-(BOOL)focusSpeedSmooth;

-(void)setFocusMode:(NSInteger)mode;
-(void)setFocusRange:(NSInteger)range;
-(void)setFocusSpeedSmooth:(BOOL)val;

-(NSInteger)isoLock;
-(void)setIsoLock:(NSInteger)val;

-(NSInteger)exposureMode;
-(void)setExposureMode:(NSInteger)mode;

-(float)videoContrast;
-(void)setVideoContrast:(float)val;

-(float)videoSaturation;
-(void)setVideovideoSaturation:(float)val;

-(float)videoBrightness;
-(void)setVideoBrightness:(float)val;

-(float)torchLevelRequested;
-(void)setTorchLevelRequested:(float)val;

-(BOOL)advancedFiltersAvailable;

-(BOOL)horizonGuide;
-(void)setHorizonGuide:(BOOL)enabled;

-(BOOL)thirdsGuide;
-(void)setThirdsGuide:(BOOL)enabled;

-(NSInteger)framingGuide;
-(void)setFramingGuide:(NSInteger)mode;

-(float)zoomPosition1;
-(void)setZoomPosition1:(float)pos;

-(float)zoomPosition2;
-(void)setZoomPosition2:(float)pos;

-(float)zoomPosition3;
-(void)setZoomPosition3:(float)pos;

-(float)zoomRate;
-(void)setZoomRate:(float)rate;

-(BOOL)useGPS;
-(void)setUseGPS:(BOOL)enabled;

-(BOOL)lockRotation;
-(void)setLockRotation:(BOOL)enabled;

-(NSInteger)nextClipSequenceNumber;
-(NSArray *)engineChromaKeyValues;
-(void)setEngineChromaKeyValues:(NSArray *)val;

-(BOOL)engineOverlay;
-(BOOL)engineTitling;
-(BOOL)engineRemote;
-(BOOL)engineHistogram;

-(NSInteger)engineHistogramType;
-(void)setEngineHistogramType:(NSInteger )t;

-(NSNumber *)engineOverlayType;
-(BOOL)engineMicrophone;

-(BOOL)engineRemoteShowPassword;
-(void)setEngineRemoteShowPassword:(BOOL)enabled;
-(NSString *)engineRemotePassword;
-(void)setEngineRemotePassword:(NSString *)password ;

-(BOOL)engineChromaKey;
-(BOOL)engineColorControl;
-(BOOL)engineImageEffect;
-(NSString *)chromaKeyImage;
-(void)setChromaKeyImage:(NSString *)path;

-(NSString *)imageEffectStr;
-(void)setImageEffectStr:(NSString *)str;

-(void)setEngineOverlay:(BOOL)enabled;
-(void)setEngineTitling:(BOOL)enabled;
-(void)setEngineRemote:(BOOL)enabled;
-(void)setEngineHistogram:(BOOL)enabled;
-(void)setEngineOverlayType:(NSNumber *)val;
-(void)setEngineMicrophone:(BOOL)enabled;

-(void)setEngineTitlingBeginName:(NSString *)name;
-(void)setEngineTitlingBeginDuration:(NSInteger)duration;
-(void)setEngineTitlingEndName:(NSString *)name;
-(void)setEngineTitlingEndDuration:(NSInteger)duration;

-(NSString *)engineTitlingBeginName;
-(NSInteger)engineTitlingBeginDuration;
-(NSString *)engineTitlingEndName;
-(NSInteger)engineTitlingEndDuration;


-(void)setEngineChromaKey:(BOOL)enabled;
-(void)setEngineColorControl:(BOOL)enabled;
-(void)setEngineImageEffect:(BOOL)enabled;

-(float)defaultBitRateForResolution:(NSInteger)res;
-(float)maxBitRateForResolution:(NSInteger)res;

-(NSString *)textForOutputResolution:(NSInteger)res;

-(CGSize)currentGuidePaneSize;
-(void)setCurrentGuidePaneSize:(CGSize)s;

-(NSDictionary *)generateFullDictForRemote;
-(NSArray *)imageEffectList;

-(NSDictionary *)imageEffectParameters:(NSString *)effectName;

-(BOOL)titleFilterBeginActive;
-(void)setTitleFilterBeginActive:(BOOL)active;

-(BOOL)titleFilterEndActive;
-(void)setTitleFilterEndActive:(BOOL)active;

-(NSArray *)titlingPageList;
-(NSArray *)masterTitlingElementList;

-(NSString *)engineTitlingTitle;
-(NSString *)engineTitlingAuthor;
-(NSString *)engineTitlingScene;
-(NSInteger)engineTitlingTake;

-(void)setEngineTitlingTitle:(NSString *)name;
-(void)setEngineTitlingAuthor:(NSString *)name;
-(void)setEngineTitlingScene:(NSString *)name;
-(void)setEngineTitlingTake:(NSInteger)duration;

-(void)setLastBackVideoCameraResolution:(NSInteger)val;
-(NSInteger)lastBackVideoCameraResolution;

-(void)setCurrentMaxFrameRate:(NSInteger)rate;
-(NSInteger)currentMaxFrameRate;


-(void)setClipStorageLibrary:(BOOL)enabled;
-(void)setClipPhotoLibraryName:(NSString *)libraryName;
-(void)setClipRecordLocation:(BOOL)enabled;

-(BOOL)clipStorageLibrary;
-(NSString *)clipPhotoLibraryName;
-(BOOL)clipRecordLocation;
-(void)setCropStillsToGuide:(BOOL)enabled;
-(BOOL)cropStillsToGuide;
-(CGFloat)framingGuideXOffset;
-(void)setFramingGuideXOffset:(CGFloat)offset;

-(BOOL)clipMoveImmediately;
-(void)setClipMoveImmediately:(BOOL)enabled;


-(NSInteger)hideUserInterface;
-(NSInteger)hidePreview;
-(NSInteger)zoomBarLocation;

-(void)setHideUserInterface:(NSInteger)length;
-(void)setHidePreview:(NSInteger)length;
-(void)setZoomBarLocation:(NSInteger)which;

-(NSInteger)youtubePrivacy;
-(void)setYoutubePrivacy:(NSInteger)which;

-(void)setYoutubeTags:(NSString *)tags;
-(void)setYoutubeCategory:(NSString *)category;

-(NSString *)youtubeTags;
-(NSString *)youtubeCategory;

-(BOOL)hasPaid;
-(void)setHasPaid:(BOOL)hasPaid;


-(CGPoint)iPadDetailButtonTray;
-(void)setiPadDetailButtonTray:(CGPoint)which;

-(CGPoint)iPadMainButtonTray;
-(void)setiPadMainButtonTray:(CGPoint)which;

-(CGPoint)iPadDetailTray;
-(void)setiPadDetailTray:(CGPoint)which;

-(CGRect)iPadVideoViewRect;
-(void)setiiPadVideoViewRect:(CGRect)which;

-(CGPoint)iPadHistogramTray;
-(void)setiPadHistogramTray:(CGPoint)which;

-(NSInteger)currentHelpVersion;
-(void)setCurrentHelpVersion:(NSInteger)v;
-(void)setCurrentExposureLock:(BOOL)expLock focusLock:(BOOL)focLock whiteBalanceLock:(BOOL)wbLock recordStatus:(BOOL)recording canZoom:(BOOL)zoom;
-(NSDictionary *)cameraStatusForRemote;
-(NSArray *)remoteSettingsForVideoPreviewframe;

-(NSInteger)defaultMoviePhotoTime;
-(void)setDefaultMoviePhotoTime:(NSInteger )seconds;

-(NSInteger)defaultMovieCreationSize;
-(void)setDefaultMovieCreationSize:(NSInteger )t;


-(void)setDailyMotionTags:(NSString *)tags;
-(void)setDailyMotionChannel:(NSString *)category;
-(NSString *)dailyMotionTags;
-(NSString *)dailyMotionChannel;
-(void)setDailyMotionPublicSwitch:(NSNumber *)public;
-(BOOL)dailyMotionPublicSwitch;
    
-(NSString *)S3Region;
-(void)setS3Region:(NSString *)s;

-(NSString *)S3Bucket;
-(void)setS3Bucket:(NSString *)s;

-(NSString *)S3Key;
-(void)setS3Key:(NSString *)s;

-(NSNumber *)S3GetURL;
-(void)setS3GetURL:(NSNumber *)s;

-(NSNumber *)S3PostUploadAction;
-(void)setS3PostUploadAction:(NSNumber *)s;

-(CGRect)defaultMoviePhotoTransitionStartRect;
-(void)setDefaultMoviePhotoTransitionStartRect:(CGRect)rect;

-(CGRect)defaultMoviePhotoTransitionEndRect;
-(void)setDefaultMoviePhotoTransitionEndRect:(CGRect)rect;

-(NSInteger)defaultRetimeFreezeDuration;
-(void)setDefaultRetimeFreezeDuration:(NSInteger )duration;

-(NSString *)azureAccount;
-(void)setAzureAccount:(NSString *)s;
-(NSString *)azureContainer;
-(void)setAzureContainer:(NSString *)s;
-(NSNumber *)azurePostUploadAction;
-(void)setAzurePostUploadAction:(NSNumber *)s;
-(NSNumber *)audioEditRampDuration;
-(void)setAudioEditRampDuration:(NSNumber *)s;
-(NSNumber *)audioEditTransitionIn;
-(void)setAudioEditTransitionIn:(NSNumber *)s;
-(NSNumber *)audioEditTransitionOut;
-(void)setAudioEditTransitionOut:(NSNumber *)s;
-(NSNumber *)audioEditVolume;
-(void)setAudioEditVolume:(NSNumber *)s;

-(BOOL)hasDoneSomethingAdWorthy;
-(void)setHasDoneSomethingAdWorthy:(BOOL)should;
-(void)incrementInterestingActions;
-(BOOL)hasBeggedForReview;
-(void)setHasBeggedForReview;
-(BOOL)shouldBegForReview;

-(NSString *)restUploadURL;
-(NSString *)restHeaders;
-(NSString *)restResponseParameter ;
-(NSInteger )restRequestType;
-(NSInteger )restResponseType;
-(void)setRestUploadURL:(NSString *)str;
-(void)setRestHeaders:(NSString *)str;
-(void)setRestResponseParameter:(NSString *)str;
-(void)setRestRequestType:(NSInteger )type;
-(void)setRestResponseType:(NSInteger )type;
-(void)setGalileoConnected:(BOOL)val;

-(NSString *)stillDefaultAlbum;
-(void)setStillDefaultAlbum:(NSString *)str;

@end
