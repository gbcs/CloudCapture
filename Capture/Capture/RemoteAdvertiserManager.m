//
//  RemoteAdvertiserManager.m
//  Capture
//
//  Created by Gary Barnett on 8/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "RemoteAdvertiserManager.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation RemoteAdvertiserManager{
    
    BOOL readyForVideoFrame;
    MCPeerID *remotePeer;
    NetworkServer *server;
}

#define sessionServiceType @"cloudcapt"

-(void)dealloc {
    //NSLog(@"%s", __func__);
     [[NSNotificationCenter defaultCenter] removeObserver:self];
    [server logoutUser];
    server = nil;
}

static RemoteAdvertiserManager *sharedSettingsManager = nil;


+ (RemoteAdvertiserManager*)manager
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
        
    }
    
    return sharedSettingsManager ;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self manager];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(void)startAdvertiser {
    if (!server) {
        [self startSession];
    }
    [server allowConnection:YES];
    _advertising = YES;
}

-(void)stopAdvertiser {
    [server allowConnection:NO];
    [self stopSession];
}

-(void)stopSession {
    [server logoutUser];
    server = nil;
    _advertising = NO;
}

-(void)startSession {
    if (!server) {
        server = [[NetworkServer alloc] init];
        server.delegate = self;
    }
}

-(BOOL)isReadyForVideoFrame {
    BOOL answer = NO;
    
    if (readyForVideoFrame && remotePeer) {
        answer = YES;
    }
    
    return answer;
}

-(NSString *)generatePassword {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"word_list" ofType:@"txt"];
    NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
    
    int lineCount = (int)[lines count];
    
    NSInteger word2Index = arc4random_uniform(lineCount);
    
    NSInteger word1Index = arc4random_uniform(lineCount);
    
    NSString *word2 = [lines objectAtIndex:word2Index];
    
    NSRange r =NSMakeRange(0,1);
    NSString *firstChar = [word2 substringWithRange:r];
    
    word2 = [word2 stringByReplacingCharactersInRange:r withString:[firstChar uppercaseString]];
    
    return [NSString stringWithFormat:@"%@%d%@", [lines objectAtIndex:word1Index], arc4random_uniform(10), word2];
}


-(void)sendStatusResponse {
    if (remotePeer) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:0.05f];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *fullStatus = [[SettingsTool settings] cameraStatusForRemote];
                NSError *error = nil;
                NSData *data = [NSJSONSerialization dataWithJSONObject:@{ @"status" : fullStatus } options:NSJSONWritingPrettyPrinted error:&error];
                [server sendMessage:data preview:NO];
            });
        });
    }
}

-(BOOL)isReadyForRemotePreviewImage {
    BOOL answer = NO;
    
    answer = [self isReadyForVideoFrame];
    
    return answer;
}

-(void)didGenerateRemotePreview:(NSData * )data {
    if (![self isReadyForRemotePreviewImage]) {
        return;
    }
   
    readyForVideoFrame = NO;
    //NSLog(@"Sending preview %@ bytes", @([data length]));
    
    [server sendMessage:data preview:YES];

      
    NSDictionary *fullStatus = [[SettingsTool settings] cameraStatusForRemote];
    NSError *error = nil;
    NSData *data2 = [NSJSONSerialization dataWithJSONObject:@{ @"status" : fullStatus } options:NSJSONWritingPrettyPrinted error:&error];
    if (!error) {
        [server sendMessage:data2 preview:NO];
    }

}

-(void)networkServerDidLoginUser:(MCPeerID *)peer {
    remotePeer = peer;
}

-(void)networkServerPeerDidFailLoginWithPassword:(NSString *)password peer:(MCPeerID *)peer {
    remotePeer = nil;
    if ((password) || ([password length] > 0) ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showPasswordPage" object:nil];
    }
}

-(void)networkServerDidLogoutUser {
    remotePeer = nil;
    [server allowConnection:YES];
}

-(void)networkServerReceivedMessage:(NSData *)msg {
    NSError *error = nil;
    NSDictionary *dict =[NSJSONSerialization JSONObjectWithData:msg options:NSJSONReadingAllowFragments error:&error];
    if (dict) {
        [self processCommand:dict];
    }
}


-(void)sendPresetResponse {
    if (!remotePeer) {
        return;
    }
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{ @"preset" : [[PresetHandler tool] presetList] } options:NSJSONWritingPrettyPrinted error:&error];
   [server sendMessage:data preview:NO];
}


-(void)sendLibraryVideoResponse {
    NSDictionary *dict = [[AssetManager manager] videoDictForRemote];
    NSData *data =  [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    [server sendMessage:[NSJSONSerialization dataWithJSONObject:@{ @"cmd" : @"libraryVideo", @"attr" : data }
                                                        options:NSJSONWritingPrettyPrinted error:nil]  preview:NO];
}

-(void)sendLibraryAudioResponse {
    NSDictionary *dict = [[AudioBrowser manager] audioDictForRemote];
    NSData *data =  [NSKeyedArchiver archivedDataWithRootObject:dict];
    [server sendMessage:[NSJSONSerialization dataWithJSONObject:@{ @"cmd" : @"libraryPhoto", @"attr" : data }
                                                        options:NSJSONWritingPrettyPrinted error:nil]  preview:NO];
}

-(void)sendLibraryPhotoResponse {
    NSDictionary *dict = [[PhotoManager manager] photoDictForRemote];
    NSData *data =  [NSKeyedArchiver archivedDataWithRootObject:dict];
    [server sendMessage:[NSJSONSerialization dataWithJSONObject:@{ @"cmd" : @"libraryAudio", @"attr" : data }
                                                        options:NSJSONWritingPrettyPrinted error:nil]  preview:NO];
}

-(void)processCommand:(NSDictionary *)dict {
    //NSLog(@"command:%@", dict);
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSString *cmd = [dict objectForKey:@"cmd"];
        if (!cmd) {
            NSLog(@"remoteDictError_No_CMD:%@", dict);
        } else {
            if ([cmd isEqualToString:@"prv"]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [NSThread sleepForTimeInterval:0.03];
                    readyForVideoFrame = YES;
                });
            } else if ([cmd isEqualToString:@"record"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleRecording" object:nil];
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"stop"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"stopRecording" object:nil];
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"start"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"startRecording" object:nil];
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"picture"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"handleStillImageRequest" object:nil];
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"focus"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleFocusLock" object:nil];
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"exposure"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleExposureLock" object:nil];
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"whiteBalance"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleWhiteBalanceLock" object:nil];
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"preset"]) {
                [self sendPresetResponse];
            } else if ([cmd isEqualToString:@"zoomButton1"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"userTappedZoomButton1" object:nil];
            } else if ([cmd isEqualToString:@"zoomButton2"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"userTappedZoomButton2" object:nil];
            } else if ([cmd isEqualToString:@"zoomButton3"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"userTappedZoomButton3" object:nil];
            } else if ([cmd isEqualToString:@"loadPreset"]) {
                NSString *presetName = [dict objectForKey:@"attr"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];
                [[PresetHandler tool] loadPresetWithName:presetName];
            } else if ([cmd isEqualToString:@"status"]) {
                [self sendStatusResponse];
            } else if ([cmd isEqualToString:@"galileoStop"]) {
                [[GalileoHandler tool] stopMoving];
            } else if ([cmd isEqualToString:@"galileoVelocity"]) {
                [[GalileoHandler tool] handleVelocityDict:[dict objectForKey:@"attr"]];
            } else if ([cmd isEqualToString:@"galileoPosition"]) {
                [[GalileoHandler tool] handlePositionDict:[dict objectForKey:@"attr"]];
            } else if ([cmd isEqualToString:@"libraryVideo"]) {
                [self sendLibraryVideoResponse];
            } else if ([cmd isEqualToString:@"libraryAudio"]) {
                [self sendLibraryAudioResponse];
            } else if ([cmd isEqualToString:@"libraryPhoto"]) {
                [self sendLibraryPhotoResponse];
            }
        }

    });
}


@end