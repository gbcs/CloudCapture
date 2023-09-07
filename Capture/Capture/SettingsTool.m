//
//  SettingsTool.m
//  Capture
//
//  Created by Gary Barnett on 7/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "SettingsTool.h"
#import "AppDelegate.h"
#import <sys/types.h>
#import <sys/sysctl.h>

@implementation SettingsTool {
    BOOL titleFilterIsActiveForEnd;
    BOOL titleFilterIsActiveForBegin;
    NSInteger maxFrameRate;
    CGFloat framingGuideXOffset;
    CGSize currentGuidePaneSize;
    BOOL hasPaid;
    
    BOOL focusLocked;
    BOOL exposureLocked;
    BOOL whiteBalanceLocked;
    BOOL recording;
    BOOL canZoom;
    BOOL galileoConnected;
    
    BOOL shouldShowAd;
}

static SettingsTool *sharedSettingsManager = nil;

-(BOOL)titleFilterBeginActive {
    return titleFilterIsActiveForBegin;
}

-(NSArray *)masterTitlingElementList {
    return @[ @"title", @"author", @"Date+Time", @"location", @"scene", @"take", @"custom" ];
}

-(void)setGalileoConnected:(BOOL)val {
    galileoConnected = val;
}



-(void)setCurrentMaxFrameRate:(NSInteger)rate {
    maxFrameRate = rate;
}

-(NSInteger)currentMaxFrameRate {
    return maxFrameRate;
}

-(void)setTitleFilterBeginActive:(BOOL)active {
    titleFilterIsActiveForBegin = active;
}


-(BOOL)titleFilterEndActive {
    return titleFilterIsActiveForEnd;
}

-(void)setTitleFilterEndActive:(BOOL)active {
    titleFilterIsActiveForEnd = active;
}

-(void)findPlatformString {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    self.platformString = [NSString stringWithCString:machine];
    free(machine);
}

-(NSArray *)imageEffectList {
    return @[ @"Vignette", @"Noir", @"Chrome", @"Fade" , @"Instant", @"Mono", @"Process", @"Tonal", @"Transfer"];
}

-(NSArray *)titlingPageList {
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    NSError *error = nil;
    NSString *titlingPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"titlingPages"];
    
    NSArray *list = [fm contentsOfDirectoryAtPath:titlingPath error:&error];
    
    NSMutableArray *titleList = [[NSMutableArray alloc] initWithCapacity:[list count]];
    
    [titleList addObject:@"None"];
    for (NSString *f in list) {
        if ([[f pathExtension] isEqualToString:@"title"]) {
            [titleList addObject:[f stringByDeletingPathExtension]];
        }
    }
    
    return [titleList copy];
}


-(NSInteger)audioAACQuality {
    NSInteger quality = 3;
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"audioAACQuality"];
    
    if (val) {
        quality = [val integerValue];
    }
    
    return quality;
}

-(void)setAudioAACQuality:(NSInteger)quality {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:quality ] forKey:@"audioAACQuality"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(BOOL)audioMonitoring {
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"audioMonitoring"];
    
    BOOL answer = YES;
    
    if (val) {
        answer = [val boolValue];
    }
    
    return answer;
}

-(void)setAudioMonitoring:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:enabled] forKey:@"audioMonitoring"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(double)audioSamplerate {
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"audioSampleRate"];
    
    double answer = 48000.0f;
    
    if (val) {
        answer = [val doubleValue];
    }
    
    return answer;
}

-(void)setAudioSamplerate:(double)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:rate] forKey:@"audioSampleRate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(BOOL)audioOutputEncodingIsAAC {
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"audioEncodingIsAAC"];
    
    BOOL answer = YES;
    
    if (val) {
        answer = [val boolValue];
    }
    
    return answer;

}

-(void)setAudioOutputEncodingIsAAC:(BOOL)enabled {
     [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:enabled] forKey:@"audioEncodingIsAAC"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)cameraIsBack {
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"cameraBack"];
    
    BOOL answer = YES;
    
    if (val) {
        answer = [val boolValue];
    }
    
    return answer;
    
}

-(void)setCameraIsBack:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:enabled]  forKey:@"cameraBack"];

    if (enabled) {
        [self setCaptureOutputResolution:[self lastBackVideoCameraResolution]];
    } else {
        if ([[SettingsTool settings] isiPhone4] || [[SettingsTool settings] isiPhone4S] || [[SettingsTool settings] isiPad2] || [[SettingsTool settings] isiPad3]) {
            //640x480 camera; map it to 640x360
            [self setCaptureOutputResolution:360];
        } else {
           [self setCaptureOutputResolution:720];
        }
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}



-(BOOL)cameraISEnabled {
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"cameraISEnabled"];
    
    BOOL answer = NO;
    
    if (val) {
        answer = [val boolValue];
    }
    
    return answer;
    
}


-(void)setCameraISEnabled:(BOOL)enabled{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:enabled] forKey:@"cameraISEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



-(BOOL)fastCaptureMode {
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"fastCaptureMode"];
    
    BOOL answer = NO;
    
    if (val) {
        answer = [val boolValue];
    }
    
    return answer;
    
}


-(void)setFastCaptureMode:(BOOL)enabled{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:enabled] forKey:@"fastCaptureMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}




-(BOOL)cameraFlipEnabled {
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"cameraFlipEnabled"];
    
    BOOL answer = NO;
    
    if (val) {
        answer = [val boolValue];
    }
    
    return answer;
    
}


-(void)setCameraFlipEnabled:(BOOL)enabled{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:enabled]  forKey:@"cameraFlipEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)captureOutputResolution {
    NSInteger rate = 720;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureOutputResolution"];
    
    if (val) {
        rate = [val intValue];
    }
    
    if (rate == 768) {
        rate = 720; //fix for removing 1366x768
    } else if (rate == 900) {
        rate = 1080; //fix for removing 1600x900
    }
    
    if ([self fastCaptureMode]) {
        rate = 720;
    }
    
    return rate;

}

-(void)setCaptureOutputResolution:(NSInteger)val {
    if ([[SettingsTool settings] cameraIsBack]) {
        [[SettingsTool settings] setLastBackVideoCameraResolution:val];
    }

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:val] forKey:@"captureOutputResolution"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setVideoCameraFrameRate:(NSInteger)val {
    if ([self fastCaptureMode]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:val] forKey:@"captureFrameRateFastCapture"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:val] forKey:@"captureFrameRate"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setLastBackVideoCameraResolution:(NSInteger)val {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:val] forKey:@"lastBackCaptureFrameRate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)lastBackVideoCameraResolution {
    NSInteger rate = 1080;
    
    if ([self isiPhone4S] || [self isiPad2]) {
        rate = 720;
    }
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"lastBackCaptureFrameRate"];
    
    if (val) {
        rate = [val intValue];
    }
    
    return rate;
}



-(NSInteger)videoCameraFrameRate {
    NSInteger rate = 24;
    
    NSNumber *val = nil;
    
    if ([self fastCaptureMode]) {
        rate = 60;
        if ([self isiPhone5S]) {
            rate = 120;
        }
        val = [[NSUserDefaults standardUserDefaults] objectForKey:@"captureFrameRateFastCapture"];
    } else {
        val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureFrameRate"];
    }
    
    if (val) {
        rate = [val intValue];
    }
    
    return rate;
    
}

-(float)maxBitRateForResolution:(NSInteger)res {
    float rate = 14.0f;
    
    switch (res) {
        case 1080:
            rate = 62.5;
            break;
        case 720:
            rate = 17.5;
            break;
        case 576:
            rate = 14.5;
            break;
        case 540:
            rate = 12.5;
            break;
        case 480:
            rate = 8.0;
            break;
        case 360:
            rate = 5.0;
            break;
    }
    
    return rate * 1000000.0f;
}

-(float)defaultBitRateForResolution:(NSInteger)res {
    float rate = 14.0f;
    
    switch (res) {
        case 1080:
            rate = 40.0;
            break;
        case 720:
            rate = 14.0;
            break;
        case 576:
            rate = 12.5;
            break;
        case 540:
            rate = 10.5;
            break;
        case 480:
            rate = 5.0;
            break;
        case 360:
            rate = 3.0;
            break;
    }
    
    return rate * 1000000.0f;
}

-(float)videoCameraVideoDataRateFastCaptureMode {
    float rate = 14.0f * 1000000.0f;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRateFastCapture"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;

}

-(void)setVideoCameraVideoDataRateFastCaptureMode:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRateFastCapture"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}




-(float)videoCameraVideoDataRate1080{
    float rate = [[SettingsTool settings] defaultBitRateForResolution:1080];
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRate1080"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;
    
}

-(void)setVideoCameraVideoDataRate1080:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRate1080"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)videoCameraVideoDataRate900 {
    float rate = [[SettingsTool settings] defaultBitRateForResolution:900];
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRate900"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;
    
}

-(void)setVideoCameraVideoDataRate900:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRate900"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}




-(float)videoCameraVideoDataRate720{
    float rate = [[SettingsTool settings] defaultBitRateForResolution:720];
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRate720"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;
    
}

-(void)setVideoCameraVideoDataRate720:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRate720"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)videoCameraVideoDataRate576{
    float rate =  [[SettingsTool settings] defaultBitRateForResolution:576];
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRate576"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;
    
}

-(void)setVideoCameraVideoDataRate576:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRate576"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)videoCameraVideoDataRate540 {
    float rate = [[SettingsTool settings] defaultBitRateForResolution:540];
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRate540"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;
    
}

-(void)setVideoCameraVideoDataRate540:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRate540"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)videoCameraVideoDataRate480{
    float rate = [[SettingsTool settings] defaultBitRateForResolution:480];
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRate480"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;
    
}

-(void)setVideoCameraVideoDataRate480:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRate480"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)videoCameraVideoDataRate360{
    float rate = [[SettingsTool settings] defaultBitRateForResolution:360];
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"captureVideoDataRate360"];
    
    if (val) {
        rate = [val floatValue];
    }
    
    return rate;
    
}

-(void)setVideoCameraVideoDataRate360:(float)rate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:rate] forKey:@"captureVideoDataRate360"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(NSString *)textForOutputResolution:(NSInteger)res {
    NSString *val = @"Unknown";
    
    switch (res) {
        case 1080:
            val = @"1920x1080";
            break;
        case 720:
            val = @"1280x720";
            break;
        case 576:
            val = @"1024x576";
            break;
        case 540:
            val = @"960x540";
            break;
        case 480:
            val = @"854x480";
            break;
        case 360:
            val = @"640x360";
            break;
    }
    
    return val;
}


- (BOOL)isiPodTouch5 {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPod5,"];
        answered = YES;
    }
    
    return answer;
    
}

-(BOOL)isOldDevice {
    if ([self isiPhone4] || [self isiPad2]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isiPhone4 {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPhone3,"];
        answered = YES;
    }
    
    return answer;
    
}

- (BOOL)isiPhone5 {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPhone5,"];
        answered = YES;
    }
    
    return answer;
    
}

- (BOOL)isiPhone5S {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPhone6,"];
        answered = YES;
    }
    
    return answer;
    
}

- (BOOL)isiPhone4S {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPhone4,"];
        answered = YES;
    }
    
    return answer;
}

- (BOOL)isiPad2 {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPad2,1"]
        || [self.platformString hasPrefix:@"iPad2,2"]
        || [self.platformString hasPrefix:@"iPad2,3"]
        || [self.platformString hasPrefix:@"iPad2,4"];
        answered = YES;
    }
    
    return answer;
}

- (BOOL)isiPad3 {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPad3,1"] || [self.platformString hasPrefix:@"iPad3,2"] || [self.platformString hasPrefix:@"iPad3,3"];
        answered = YES;
    }
    
    return answer;
}


- (BOOL)isIPadMini {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPad2,5"]
        || [self.platformString hasPrefix:@"iPad2,6"]
        || [self.platformString hasPrefix:@"iPad2,7"]
        || [self.platformString hasPrefix:@"iPad2,8"]
        || [self.platformString hasPrefix:@"iPad2,9"];
        answered = YES;
    }
    
    return answer;
    
}

- (BOOL)isiPadAir {
    static BOOL answer;
    static BOOL answered;
    
    if (!answered) {
        answer = [self.platformString hasPrefix:@"iPad4,"];
        answered = YES;
    }
    
    return answer;
    
}

-(NSInteger)videoCameraAutoStopDuration {
    NSInteger duration = 0;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"videoCameraAutoStopDuration"]) {
        duration = [[defaults objectForKey:@"videoCameraAutoStopDuration"] intValue];
    }
    
    return duration;
}

-(void)setVideoCameraAutoStopDuration:(NSInteger)duration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:duration] forKey:@"videoCameraAutoStopDuration"];
     [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)focusMode {
    NSInteger mode = 1;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"focusMode"];
    
    if (val) {
        mode = [val floatValue];
    }
    
    return mode;
    
}

-(NSInteger)focusRange {
    NSInteger mode = 0;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"focusRange"];
    
    if (val) {
        mode = [val floatValue];
    }
    
    return mode;
    
}

-(void)setFocusMode:(NSInteger)mode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:mode] forKey:@"focusMode"];
     [[NSUserDefaults standardUserDefaults] synchronize];

}

-(void)setFocusRange:(NSInteger)range {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:range] forKey:@"focusRange"];
     [[NSUserDefaults standardUserDefaults] synchronize];
 
}



-(NSInteger)isoLock {
    NSInteger mode = 0;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"isoLock"];
    
    if (val) {
        mode = [val floatValue];
    }
    
    return mode;
}

-(void)setIsoLock:(NSInteger)val {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:val] forKey:@"isoLock"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)exposureMode {
    NSInteger mode = 1;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"exposureMode"];
    
    if (val) {
        mode = [val floatValue];
    }
    
    return mode;
}

-(void)setExposureMode:(NSInteger)mode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:mode] forKey:@"exposureMode"];
     [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (SettingsTool*)settings
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
        
        
        [sharedSettingsManager findPlatformString];

        
    }

    return sharedSettingsManager ;
}



-(float)videoContrast {
    float setting = 1.0;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"videoContrast"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;
}

-(void)setVideoContrast:(float)val {
    
    if (val < 0.0f) {
        val = 0.0f;
    } else if (val > 4.0f) {
        val = 4.0f;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:val] forKey:@"videoContrast"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(float)videoSaturation {
    float setting = 1.0;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"videoSaturation"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;

}

-(void)setVideovideoSaturation:(float)val {
    if (val < 0.0f) {
        val = 0.0f;
    } else if (val > 2.0f) {
        val = 2.0f;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:val] forKey:@"videoSaturation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(float)videoBrightness {
    float setting = 0.0;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"videoBrightness"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;

}




-(void)setVideoBrightness:(float)val {
    if (val < -1.0f) {
        val = -1.0f;
    } else if (val > 1.0f) {
        val = 1.0f;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:val] forKey:@"videoBrightness"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)torchLevelRequested {
    float setting = 0.5;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"torchLevelRequested"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;
}

-(void)setTorchLevelRequested:(float)val {
    if (val < 0.0f) {
        val = 0.0f;
    } else if (val > 1.0f) {
        val = 1.0f;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:val] forKey:@"torchLevelRequested"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}

-(void)setFocusSpeedSmooth:(BOOL)val {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:val] forKey:@"focusSpeed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)focusSpeedSmooth {
    BOOL enabled = YES;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"focusSpeed"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}


-(BOOL)advancedFiltersAvailable {
    BOOL enabled = YES;
    
    if ([self isOldDevice]) {
        enabled = NO;
    }
    
    if ([[SettingsTool settings] fastCaptureMode]) {
        enabled = NO;
    }
    
    return enabled;
}


-(BOOL)horizonGuide {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"horizonGuide"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(void)setHorizonGuide:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"horizonGuide"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(BOOL)thirdsGuide {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"thirdsGuide"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(void)setThirdsGuide:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"thirdsGuide"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}

-(CGSize)currentGuidePaneSize {
    return currentGuidePaneSize;
}

-(void)setCurrentGuidePaneSize:(CGSize)s {
    currentGuidePaneSize = s;
}

-(CGFloat)framingGuideXOffset {
    return framingGuideXOffset;
}

-(void)setFramingGuideXOffset:(CGFloat)offset {
    framingGuideXOffset = offset;
}

-(NSInteger)framingGuide {
    NSInteger mode = 0;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"framingGuide"];
    
    if (val) {
        mode = [val intValue];
    }
    
    return mode;
}

-(void)setFramingGuide:(NSInteger)mode {
    
    NSInteger currentMode = [self framingGuide];
    
    if (currentMode != mode) {
        [self setFramingGuideXOffset:0];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:mode] forKey:@"framingGuide"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}


-(float)zoomPosition1 {
    float setting = 0.0f;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"zoomPosition1"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;
}

-(void)setZoomPosition1:(float)pos {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:pos] forKey:@"zoomPosition1"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)zoomPosition2 {
    float setting = 0.20f;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"zoomPosition2"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;
}

-(void)setZoomPosition2:(float)pos {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:pos] forKey:@"zoomPosition2"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(float)zoomPosition3 {
    float setting = 0.50f;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"zoomPosition3"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;
}

-(void)setZoomPosition3:(float)pos {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:pos] forKey:@"zoomPosition3"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(float)zoomRate {
    float setting = 1.0f;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"zoomRate"];
    
    if (val) {
        setting = [val floatValue];
    }
    
    return setting;

}

-(void)setZoomRate:(float)rate {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:rate] forKey:@"zoomRate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  
}

-(BOOL)useGPS {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"useGPS"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(void)setUseGPS:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"useGPS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


-(BOOL)lockRotation {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"lockRotation"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(void)setLockRotation:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"lockRotation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)nextClipSequenceNumber {
    NSInteger answer = 1;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *currentClipSequenceNumber = [defaults objectForKey:@"currentClipSequenceNumber"];
    
    if (currentClipSequenceNumber) {
        answer = [currentClipSequenceNumber intValue] + 1;
    }
    
    [defaults setObject:[NSNumber numberWithInteger:answer] forKey:@"currentClipSequenceNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    return answer;
}

-(NSString *)imageEffectStr {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults objectForKey:@"engineImageEffectStr"];
    
    return  str ? str : @"None";

}

-(void)setImageEffectStr:(NSString *)str {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:str forKey:@"engineImageEffectStr"];
    [defaults synchronize];
}

-(NSString *)chromaKeyImage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults objectForKey:@"engineChromaKeyImage"];
    
    return  str ? str : @"";
}

-(void)setChromaKeyImage:(NSString *)path {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:path forKey:@"engineChromaKeyImage"];
    [defaults synchronize];
}


-(NSArray *)engineChromaKeyValues {
    NSArray *values = @[ @(0.25f), @(0.45f) ];
   
    NSArray *val = [[NSUserDefaults standardUserDefaults] objectForKey:@"engineChromaKeyValues"];

    if (val) {
        values = val;
    }
    
    return values;
}

-(void)setEngineChromaKeyValues:(NSArray *)val {
    [[NSUserDefaults standardUserDefaults] setObject:val forKey:@"engineChromaKeyValues"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)engineChromaKey {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineChromaKey"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(BOOL)engineColorControl {
    BOOL enabled = YES;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineColorControl"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(BOOL)engineImageEffect {
    BOOL enabled = YES;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineImageEffect"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(void)setHasPaid:(BOOL)paid {
    hasPaid = paid;
}

-(BOOL)hasPaid {
#ifdef CCPRO
    return YES;
#endif
    
    
    if (1 == 2) {
        return YES;
            // #warning set haspaid to yes
    }
    
    return hasPaid;
}


-(BOOL)engineOverlay {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineOverlay"];
    
    if (val) {
        enabled = [val boolValue];
    }

    return enabled;
}

-(BOOL)engineTitling {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineTitling"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(BOOL)engineRemote {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineRemote"];

    if (val) {
        enabled = [val boolValue];
    }

    return enabled;
}

-(BOOL)engineRemoteShowPassword {
    BOOL enabled = YES;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineRemoteShowPassword"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(void)setEngineRemoteShowPassword:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineRemoteShowPassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



-(NSString *)engineRemotePassword {
    NSString *password = @"";
    
    NSString *val = [[NSUserDefaults standardUserDefaults] objectForKey:@"engineRemotePassword"];
    
    if (val) {
        password = val;
    } else {
        password = [[RemoteAdvertiserManager manager] generatePassword];
        [self setEngineRemotePassword:password];
    }
    
    return password;
}

-(void)setEngineRemotePassword:(NSString *)password {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:password forKey:@"engineRemotePassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(BOOL)engineHistogram {
    BOOL enabled = NO;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineHistogram"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(NSNumber *)engineOverlayType {
    NSNumber *setting = @3;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineOverlayType"];
    
    if (val) {
        setting = val;
    }
    
    return setting;
}

-(BOOL)engineMicrophone {
    BOOL enabled = YES;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"engineMicrophone"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}

-(void)setEngineChromaKey:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineChromaKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineColorControl:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineColorControl"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineImageEffect:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineImageEffect"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setEngineOverlay:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineOverlay"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineTitling:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineTitling"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineRemote:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineRemote"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (enabled) {
        [appD handleRemoteSessionSetup];
    } else {
        [appD stopRemoteSessions];
    }
}


-(void)setEngineHistogram:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineHistogram"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineOverlayType:(NSNumber *)type {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:type forKey:@"engineOverlayType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineMicrophone:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"engineMicrophone"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setCropStillsToGuide:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"cropStillsToGuide"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)cropStillsToGuide {
    BOOL enabled = YES;
    
    NSNumber *val =[[NSUserDefaults standardUserDefaults] objectForKey:@"cropStillsToGuide"];
    
    if (val) {
        enabled = [val boolValue];
    }
    
    return enabled;
}


-(NSDictionary *)generateFullDictForRemote {
    NSDictionary *dict = @{
                           @"cameraPlatformString" : self.platformString,
                           @"audioMonitoring" : [NSNumber numberWithBool:[self audioMonitoring]],
                           @"audioSamplerate" : [NSNumber numberWithDouble:[self audioSamplerate]],
                           @"audioOutputEncodingIsAAC" : [NSNumber numberWithBool:[self audioOutputEncodingIsAAC]],
                           @"cameraIsBack" : [NSNumber numberWithBool:[self cameraIsBack]],
                           @"cameraISEnabled" : [NSNumber numberWithBool:[self cameraISEnabled]],
                         
                           @"fastCaptureMode" : [NSNumber numberWithBool:[self fastCaptureMode]],
                         
                           @"cameraFlipEnabled" : [NSNumber numberWithBool:[self cameraFlipEnabled]],
                         
                           @"captureOutputResolution" : [NSNumber numberWithInteger:[self captureOutputResolution]],
                         
                           @"videoCameraFrameRate" : [NSNumber numberWithInt:[self cameraISEnabled]],
                         
                           @"videoCameraAutoStopDuration" : [NSNumber numberWithInt:[self cameraISEnabled]],
                         
                           @"videoCameraVideoDataRate1080" : [NSNumber numberWithFloat:[self videoCameraVideoDataRate1080]],
                           @"videoCameraVideoDataRate900" : [NSNumber numberWithFloat:[self videoCameraVideoDataRate900]],
                           @"videoCameraVideoDataRate720" : [NSNumber numberWithFloat:[self videoCameraVideoDataRate720]],
                           @"videoCameraVideoDataRate576" : [NSNumber numberWithFloat:[self videoCameraVideoDataRate576]],
                           @"videoCameraVideoDataRate540" : [NSNumber numberWithFloat:[self videoCameraVideoDataRate540]],
                           @"videoCameraVideoDataRate480" : [NSNumber numberWithFloat:[self videoCameraVideoDataRate480]],
                           @"videoCameraVideoDataRate360" : [NSNumber numberWithFloat:[self videoCameraVideoDataRate360]],
                          
        
                           @"videoCameraVideoDataRateFastCaptureMode" : [NSNumber numberWithFloat:[self videoCameraVideoDataRateFastCaptureMode]],

                           @"focusMode" : [NSNumber numberWithInteger:[self focusMode]],
                         
                           @"focusRange" : [NSNumber numberWithInteger:[self focusRange]],
                         
                           @"exposureMode" : [NSNumber numberWithInteger:[self exposureMode]],
                         
                           @"videoContrast" : [NSNumber numberWithFloat:[self videoContrast]],
                         
                           @"videoSaturation" : [NSNumber numberWithFloat:[self videoSaturation]],
                         
                           @"videoBrightness" : [NSNumber numberWithFloat:[self videoBrightness]],
                         
                           @"torchLevelRequested" : [NSNumber numberWithFloat:[self torchLevelRequested]],
                           
                           @"histogramEnabled" : [NSNumber numberWithBool:[self engineHistogram]],
                         
                           @"fastCaptureMode" : [NSNumber numberWithBool:[self fastCaptureMode]],
                           @"advancedFiltersAvailable" : [NSNumber numberWithBool:[self advancedFiltersAvailable]],
                           
                          
                           @"horizonGuide" : [NSNumber numberWithBool:[self horizonGuide]],
                           @"thirdsGuide" : [NSNumber numberWithBool:[self thirdsGuide]],
                           
                           @"framingGuide" : [NSNumber numberWithInteger:[self framingGuide]],
                           
                           @"zoomPosition1" : [NSNumber numberWithFloat:[self zoomPosition1]],
                         
                           @"zoomPosition2" : [NSNumber numberWithFloat:[self zoomPosition2]],
                         
                           @"zoomPosition3" : [NSNumber numberWithFloat:[self zoomPosition3]],
                           
                           @"zoomRate" : [NSNumber numberWithFloat:[self zoomRate]],
                           
                           @"useGPS" : [NSNumber numberWithBool:[self useGPS]],
                        
                           @"engineChromaKey" : [NSNumber numberWithBool:[self engineChromaKey]],
                        
                           @"engineColorControl" : [NSNumber numberWithBool:[self engineColorControl]],
                        
                           @"engineImageEffect" : [NSNumber numberWithBool:[self engineImageEffect]],
                        
                           @"engineOverlay" : [NSNumber numberWithBool:[self engineOverlay]],
                        
                           @"engineTitling" : [NSNumber numberWithBool:[self engineTitling]],
                        
                           @"engineRemote" : [NSNumber numberWithBool:[self engineRemote]],
                        
                           @"engineOverlayType" : [self engineOverlayType],
                           
                           @"engineMicrophone" : [NSNumber numberWithBool:[self engineMicrophone]],
                           
                           };
    return dict;
}


-(NSDictionary *)imageEffectParameters:(NSString *)effectName {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"ifDict%@", effectName]];
    
    if (!dict) {
        if ([effectName isEqualToString:@"Vignette"]) {
            dict = @{ @"inputIntensity" : [NSNumber numberWithFloat:0.0f],
                      @"inputRadius" : [NSNumber numberWithFloat:1.0f]
                      };
        } else {
            dict = @{ };
        }
    }
    
    return dict;
}



-(void)setEngineTitlingBeginName:(NSString *)name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"engineTitlingBeginName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setEngineTitlingBeginDuration:(NSInteger)duration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:duration] forKey:@"engineTitlingBeginDuration"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineTitlingEndName:(NSString *)name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"engineTitlingEndName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineTitlingEndDuration:(NSInteger)duration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:duration] forKey:@"engineTitlingEndDuration"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



-(NSString *)engineTitlingBeginName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults objectForKey:@"engineTitlingBeginName"];
    return str ? str : @"None";
}


-(NSInteger)engineTitlingBeginDuration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"engineTitlingBeginDuration"];
    return val ? [val integerValue] : 5;
}


-(NSString *)engineTitlingEndName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults objectForKey:@"engineTitlingEndName"];
    return str ? str : @"None";
}


-(NSInteger)engineTitlingEndDuration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"engineTitlingEndDuration"];
    return val ? [val integerValue] : 5;
}

-(NSInteger)engineTitlingTake {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"engineTitlingTake"];
    return val ? [val integerValue] : 1;
}


-(NSString *)engineTitlingTitle {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults objectForKey:@"engineTitlingTitle"];
    return str ? str : @"";
}

-(NSString *)engineTitlingAuthor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults objectForKey:@"engineTitlingAuthor"];
    return str ? str : @"";
}

-(NSString *)engineTitlingScene {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults objectForKey:@"engineTitlingScene"];
    return str ? str : @"";
}


-(void)setEngineTitlingTitle:(NSString *)name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"engineTitlingTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineTitlingAuthor:(NSString *)name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"engineTitlingAuthor"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineTitlingScene:(NSString *)name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"engineTitlingScene"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setEngineTitlingTake:(NSInteger)duration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:duration] forKey:@"engineTitlingTake"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setClipStorageLibrary:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"clipStorageLibrary"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setClipPhotoLibraryName:(NSString *)libraryName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:libraryName forKey:@"clipPhotoLibraryName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setClipRecordLocation:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"clipRecordLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)clipStorageLibrary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"clipStorageLibrary"];
    
    if (!val) {
        val = @(NO);
        if ([self isiPhone4S] || [self isOldDevice]) {
            val = @(YES);
        }
    }
    
    return [val boolValue];
}

-(NSString *)clipPhotoLibraryName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"clipPhotoLibraryName"];
    return val ? val: @"Camera Roll";
}

-(BOOL)clipRecordLocation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"clipRecordLocation"];
    return val ? [val boolValue] : NO;
}

-(BOOL)clipMoveImmediately {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"clipMoveImmediately"];
    return val ? [val boolValue] : YES;
}

-(void)setClipMoveImmediately:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:enabled] forKey:@"clipMoveImmediately"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)hideUserInterface {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"hideUserInterface"];
    return val ? [val integerValue] : 0;
}

-(NSInteger)hidePreview {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"hidePreview"];
    return val ? [val integerValue] : 0;
}

-(NSInteger)zoomBarLocation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"zoomBarLocation"];
    return val ? [val integerValue] : 2;
}

-(void)setHideUserInterface:(NSInteger)length {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:length] forKey:@"hideUserInterface"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setHidePreview:(NSInteger)length {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:length] forKey:@"hidePreview"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setZoomBarLocation:(NSInteger)which {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:which] forKey:@"zoomBarLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self settings];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(NSInteger)youtubePrivacy {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"youtubePrivacy"];
    return val ? [val integerValue] : 0;
}

-(void)setYoutubePrivacy:(NSInteger)which {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:which] forKey:@"youtubePrivacy"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



-(void)setYoutubeTags:(NSString *)tags {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:tags forKey:@"youtubeTags"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setYoutubeCategory:(NSString *)category {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:category forKey:@"youtubeCategory"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)youtubeTags {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"youtubeTags"];
    return val ? val : @"";
}

-(NSString *)youtubeCategory {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"youtubeCategory"];
    return val ? val: @"1";
}

-(void)setDailyMotionTags:(NSString *)tags {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:tags forKey:@"dailyMotionTags"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setDailyMotionChannel:(NSString *)category {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:category forKey:@"dailyMotionChannel"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)dailyMotionTags {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"dailyMotionTags"];
    return val ? val : @"";
}

-(NSString *)dailyMotionChannel {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"dailyMotionChannel"];
    return val ? val: @"creation";
}

-(void)setDailyMotionPublicSwitch:(NSNumber *)public {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:public forKey:@"dailyMotionPublicSwitch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)dailyMotionPublicSwitch {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"dailyMotionPublicSwitch"];
    if (!val) {
        val = @YES;
    }

    return [val boolValue];
}

-(CGPoint)iPadDetailButtonTray {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = [defaults objectForKey:@"iPadDetailButtonTray"];
    return val ? CGPointMake([val[0] floatValue], [val[1] floatValue]) : CGPointMake(0, 184);
}

-(void)setiPadDetailButtonTray:(CGPoint)which {
    NSArray *val = @[ @(which.x) , @(which.y)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:val forKey:@"iPadDetailButtonTray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(CGPoint)iPadMainButtonTray {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = [defaults objectForKey:@"iPadMainButtonTray"];
    return val ? CGPointMake([val[0] floatValue], [val[1] floatValue]) : CGPointMake(262, 600);
}

-(void)setiPadMainButtonTray:(CGPoint)which{
    NSArray *val = @[ @(which.x) , @(which.y)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:val forKey:@"iPadMainButtonTray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(CGPoint)iPadHistogramTray {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = [defaults objectForKey:@"iPadHistogramTray"];
    return val ? CGPointMake([val[0] floatValue], [val[1] floatValue]) : CGPointMake(700, 20);
}

-(void)setiPadHistogramTray:(CGPoint)which{
    NSArray *val = @[ @(which.x) , @(which.y)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:val forKey:@"iPadHistogramTray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(CGPoint)iPadDetailTray {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = [defaults objectForKey:@"iPadDetailTray"];
    return val ? CGPointMake([val[0] floatValue], [val[1] floatValue]) : CGPointMake(1024 - 308, 234);
}

-(void)setiPadDetailTray:(CGPoint)which{
   NSArray *val = @[ @(which.x) , @(which.y)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:val forKey:@"iPadDetailTray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(CGRect)iPadVideoViewRect {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = [defaults objectForKey:@"iPadVideoViewRect"];
    return val ? CGRectMake([val[0] floatValue], [val[1] floatValue], [val[2] floatValue], [val[3] floatValue]) : CGRectMake(110, 221, 580,326);
}
                                      

-(void)setiiPadVideoViewRect:(CGRect)which{
    NSArray *val = @[ @(which.origin.x) , @(which.origin.y),@(which.size.width), @(which.size.height) ];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:val forKey:@"iPadVideoViewRect"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(NSInteger)currentHelpVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"currentHelpVersion"];
 
    return val ? [val integerValue] : 1;
}


-(void)setCurrentHelpVersion:(NSInteger)v {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(v) forKey:@"currentHelpVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSDictionary *)cameraStatusForRemote {
    return @{ @"f" : @(focusLocked) ,
              @"e" : @(exposureLocked),
              @"w" : @(whiteBalanceLocked),
              @"r" : @(recording),
              @"z" : @(canZoom),
              @"g" : @(galileoConnected),
              @"p" : [PresetHandler tool].currentPreset
              };
}

-(NSArray *)remoteSettingsForVideoPreviewframe {
    return @[ @(focusLocked), @(exposureLocked) , @(whiteBalanceLocked), @(recording), @(canZoom) ];
}


-(void)setCurrentExposureLock:(BOOL)expLock focusLock:(BOOL)focLock whiteBalanceLock:(BOOL)wbLock recordStatus:(BOOL)rec canZoom:(BOOL)zoom {
    focusLocked = focLock;
    exposureLocked = expLock;
    whiteBalanceLocked = wbLock;
    recording = rec;
    canZoom = zoom;
}

-(NSInteger)defaultMoviePhotoTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"defaultMoviePhotoTime"];
    
    return val ? [val integerValue] : 3;

}

-(void)setDefaultMoviePhotoTime:(NSInteger )seconds {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(seconds) forKey:@"defaultMoviePhotoTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}

-(NSInteger)engineHistogramType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"engineHistogramType"];
    
    return val ? [val integerValue] : 4;

}

-(void)setEngineHistogramType:(NSInteger )t {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(t) forKey:@"engineHistogramType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)defaultMovieCreationSize {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"defaultMovieCreationSize"];
    
    return val ? [val integerValue] : 1;
    
}

-(void)setDefaultMovieCreationSize:(NSInteger )t {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(t) forKey:@"defaultMovieCreationSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)restUploadURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"restUploadURL"];
    
    return val ? val : @"http://";
}

-(NSString *)restHeaders {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"restHeaders"];
    
    return val ? val : @"";
}

-(NSString *)restResponseParameter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"restResponseParameter"];
    
    return val ? val : @"movieURL";
}

-(NSInteger )restRequestType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"restRequestType"];
    
    return val ? [val integerValue] : 0;
}

-(NSInteger )restResponseType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"restResponseType"];
    
    return val ? [val integerValue] : 0;
}

-(void)setRestUploadURL:(NSString *)str {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:str forKey:@"restUploadURL"];
    [defaults synchronize];
}

-(void)setRestHeaders:(NSString *)str {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:str forKey:@"restHeaders"];
    [defaults synchronize];
}

-(void)setRestResponseParameter:(NSString *)str {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:str forKey:@"restResponseParameter"];
    [defaults synchronize];
}

-(void)setRestRequestType:(NSInteger )type {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(type) forKey:@"restRequestType"];
    [defaults synchronize];
}

-(void)setRestResponseType:(NSInteger )type {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(type) forKey:@"restResponseType"];
    [defaults synchronize];
}

-(NSString *)S3Region {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"S3Region"];
    
    return val ? val : @"us-west-2";
}

-(void)setS3Region:(NSString *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"S3Region"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)S3Bucket {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"S3Bucket"];
    
    return val ? val : @"";
}

-(void)setS3Bucket:(NSString *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"S3Bucket"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(NSString *)S3Key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"S3Key"];
    
    return val ? val : @"";
}

-(void)setS3Key:(NSString *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"S3Key"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber *)S3GetURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"S3GetURL"];
    
    return val ? val : @(YES);
}

-(void)setS3GetURL:(NSNumber *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"S3GetURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber *)S3PostUploadAction {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"S3PostUploadAction"];
    
    return val ? val : @(0);
}

-(void)setS3PostUploadAction:(NSNumber *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"S3PostUploadAction"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)defaultRetimeFreezeDuration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"defaultRetimeFreezeDuration"];
    
    return val ? [val integerValue] : 3;
}

-(void)setDefaultRetimeFreezeDuration:(NSInteger )t {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(t) forKey:@"defaultRetimeFreezeDuration"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(CGRect)defaultMoviePhotoTransitionStartRect {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = [defaults objectForKey:@"defaultMoviePhotoTransitionStartRect"];
    return val ? CGRectMake([val[0] floatValue], [val[1] floatValue], [val[2] floatValue], [val[3] floatValue]) :  CGRectMake(0, 45, 230, 129);
}

-(void)setDefaultMoviePhotoTransitionStartRect:(CGRect)r {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = @[ @(r.origin.x) , @(r.origin.y), @(r.size.width) , @(r.size.height)];
    [defaults setObject:val forKey:@"defaultMoviePhotoTransitionStartRect"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(CGRect)defaultMoviePhotoTransitionEndRect {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = [defaults objectForKey:@"defaultMoviePhotoTransitionEndRect"];
    return val ? CGRectMake([val[0] floatValue], [val[1] floatValue], [val[2] floatValue], [val[3] floatValue]) :  CGRectMake(0, 45, 230, 129);
}

-(void)setDefaultMoviePhotoTransitionEndRect:(CGRect)r {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *val = @[ @(r.origin.x) , @(r.origin.y), @(r.size.width) , @(r.size.height)];
    [defaults setObject:val forKey:@"defaultMoviePhotoTransitionEndRect"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)azureAccount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"azureAccount"];
    
    return val ? val : @"";
}

-(void)setAzureAccount:(NSString *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"azureAccount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)azureContainer {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"azureContainer"];
    
    return val ? val : @"";
}

-(void)setAzureContainer:(NSString *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"azureContainer"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber *)azurePostUploadAction {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"azurePostUploadAction"];
    
    return val ? val : @(0);
}

-(void)setAzurePostUploadAction:(NSNumber *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"azurePostUploadAction"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber *)audioEditRampDuration {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"audioEditRampDuration"];
    
    return val ? val : @(1.0f);
}

-(void)setAudioEditRampDuration:(NSNumber *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"audioEditRampDuration"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber *)audioEditTransitionIn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"audioEditTransitionIn"];
    
    return val ? val : @(0);
}

-(void)setAudioEditTransitionIn:(NSNumber *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"audioEditTransitionIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber *)audioEditTransitionOut {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"audioEditTransitionOut"];
    
    return val ? val : @(0);
}

-(void)setAudioEditTransitionOut:(NSNumber *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"audioEditTransitionOut"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber *)audioEditVolume {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"audioEditVolume"];
    
    return val ? val : @(1.0f);
}

-(void)setAudioEditVolume:(NSNumber *)s {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:s forKey:@"audioEditVolume"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)hasDoneSomethingAdWorthy {
    return shouldShowAd;
}

-(void)incrementInterestingActions {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"interestingActions"];
    NSNumber *inc = @([val integerValue] + 1);
    [defaults setObject:inc forKey:@"interestingActions"];
    [defaults synchronize];
}

-(void)setHasDoneSomethingAdWorthy:(BOOL)should {
    shouldShowAd = should;
}

-(BOOL)shouldBegForReview {
    BOOL answer = NO;
    
    if (![self hasBeggedForReview]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *val = [defaults objectForKey:@"interestingActions"];
        if ([val integerValue] > 100) {
            answer = YES;
        }
    }
    
    if (1 == 2) {
        answer = YES;
    }
    
    return answer;
}

-(BOOL)hasBeggedForReview {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *val = [defaults objectForKey:@"hasBeggedForReview"];
    
    if (1 == 2) {
        val = @(NO);
    }
    
    return [val boolValue];
}

-(NSString *)stillDefaultAlbum {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:@"stillDefaultAlbum"];
    
    if (!val) {
        val = @"Camera Roll";
    }
    
    return val;
}

-(void)setStillDefaultAlbum:(NSString *)str {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:str forKey:@"stillDefaultAlbum"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}




-(void)setHasBeggedForReview {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:@"hasBeggedForReview"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end