//
//  PresetHandler.m
//  Capture
//
//  Created by Gary Barnett on 11/25/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "PresetHandler.h"

@implementation PresetHandler

static PresetHandler  *sharedSettingsManager = nil;

+ (PresetHandler *)tool
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
        
    }
    
    return sharedSettingsManager ;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self tool];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(NSString *)presetBasePath {
    return [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"presetFiles"];
}

-(NSArray *)presetKeyList {
    
    NSArray *list = @[
                      
                      @"ifDictNoir",
                      @"ifDictVignette",
                      @"ifDictChrome",
                      @"ifDictFade",
                      @"ifDictInstant",
                      @"ifDictMono",
                      @"ifDictProcess",
                      @"ifDictTonal",
                      @"ifDictTransfer",
                      @"audioAACQuality",
                      @"audioMonitoring",
                      @"audioSampleRate",
                      @"audioEncodingIsAAC",
                      @"cameraBack",
                      @"cameraISEnabled",
                      @"fastCaptureMode",
                      @"cameraFlipEnabled",
                      @"captureOutputResolution",
                      @"captureFrameRateFastCapture",
                      @"captureFrameRate",
                      @"lastBackCaptureFrameRate",
                      @"captureVideoDataRateFastCapture",
                      @"captureVideoDataRate1080",
                      @"captureVideoDataRate900",
                      @"captureVideoDataRate720",
                      @"captureVideoDataRate576",
                      @"captureVideoDataRate540",
                      @"captureVideoDataRate480",
                      @"captureVideoDataRate360",
                      @"videoCameraAutoStopDuration",
                      @"focusMode",
                      @"focusRange",
                      @"isoLock",
                      @"exposureMode",
                      @"videoContrast",
                      @"videoSaturation",
                      @"videoBrightness",
                      @"torchLevelRequested",
                      @"focusSpeed",
                      @"horizonGuide",
                      @"thirdsGuide",
                      @"framingGuide",
                      @"zoomPosition1",
                      @"zoomPosition2",
                      @"zoomPosition3",
                      @"zoomRate",
                      @"clipRecordLocation",
                      @"lockRotation",
                      @"currentClipSequenceNumber",
                      @"engineImageEffectStr",
                      @"engineChromaKeyImage",
                      @"engineChromaKeyValues",
                      @"engineChromaKey",
                      @"engineColorControl",
                      @"engineImageEffect",
                      @"engineOverlay",
                      @"engineTitling",
                      @"engineRemote",
                      @"engineHistogram",
                      @"engineOverlayType",
                      @"engineMicrophone",
                      @"cropStillsToGuide",
                      @"engineTitlingBeginName",
                      @"engineTitlingBeginDuration",
                      @"engineTitlingEndName",
                      @"engineTitlingEndDuration",
                      @"engineTitlingTake",
                      @"engineTitlingTitle",
                      @"engineTitlingAuthor",
                      @"engineTitlingScene",
                      @"clipStorageLibrary",
                      @"clipRecordLocation",
                      @"clipMoveImmediately",
                      @"hideUserInterface",
                      @"hidePreview",
                      @"zoomBarLocation"
                      
                      ];
    
    return list;
}

-(NSArray *)presetList {
    NSError *error = nil;
    NSArray *presetList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self presetBasePath] error:&error];

    if (presetList) {
        NSMutableArray *p = [presetList mutableCopy];
        [p removeObject:[self currentPreset]];
        presetList = [p copy];
    }
    
    return  presetList ? presetList : [NSArray array];
}

-(void)setCurrentPreset:(NSString *)name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"currentPreset"];
    [defaults synchronize];
}

-(void)loadPresetWithName:(NSString *)name {
    NSString *filePath = [[self presetBasePath] stringByAppendingPathComponent:name];
    NSDictionary *presetDict = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        //NSLog(@"preset: %@ = %@", name, presetDict);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (NSString *key in [presetDict allKeys]) {
        NSObject *val =[presetDict objectForKey:key];
        
        if ([key isEqualToString:@"captureOutputResolution"]) {
            NSNumber *n = (NSNumber *)val;
            if ([n integerValue] == 768) {
                val = @(720);
                //fix for removing 1366x768
            } else if ([n integerValue] == 900) {
                val = @(1080);
                    //fix for removing 1600x900
            }
        }
        
        [defaults setObject:val forKey:key];
        if (1 == 1) {
            
        } else {
            
        }
      /*
        @"captureFrameRate",
        @"focusMode",
        @"focusRange",
       @"exposureMode",
       @"horizonGuide",
        @"useGPS",
        @"lockRotation",
              @"zoomBarLocation"
        */
    
    }
    
    [defaults synchronize];
    
    if (presetDict) {
        [self setCurrentPreset:name];
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadAfterPresetChange" object:nil];
    
}

-(NSString *)currentPreset {
    NSString *presetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentPreset"];
    
    if (!presetName ) {
        presetName = @"1280x720@24fps";
        [self saveCurrentSettingsAsPreset:presetName];
    }
    
    return presetName;
}

-(NSDictionary *)dictForCurrentSettings {

    NSMutableDictionary *keys = [[NSMutableDictionary alloc] initWithCapacity:[[self presetKeyList] count]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (NSString *key in [self presetKeyList]) {
        if ([defaults objectForKey:key]) {
            [keys setObject:[defaults objectForKey:key] forKey:key];
        }
    }
    
    return [keys copy];
}


-(void)saveCurrentPreset {
    [self saveCurrentSettingsAsPreset:[self currentPreset]];
}

-(void)deletePresetWithName:(NSString *)name {
    NSError *error = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:[[self presetBasePath] stringByAppendingPathComponent:name] error:&error];
}

-(void)addPresetWithName:(NSString *)name {
    [self saveCurrentSettingsAsPreset:name];
    [self setCurrentPreset:name];
}

-(void)saveCurrentSettingsAsPreset:(NSString *)name {
    NSDictionary *presetDict = [self dictForCurrentSettings];
    
    NSString *filePath = [[self presetBasePath] stringByAppendingPathComponent:name];
    
    [NSKeyedArchiver archiveRootObject:presetDict toFile:filePath];
}



@end