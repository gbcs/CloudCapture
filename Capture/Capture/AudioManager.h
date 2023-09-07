//
//  AudioManager.h
//  Capture
//
//  Created by Gary Barnett on 7/19/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioManager : NSObject

+(AudioManager *)manager;

-(void)updateAudioUnit;

-(void)updateSampleRate:(double)rate;

-(void)startup;

-(void)shutdown;

-(void)playbackMode:(BOOL)enabled;

-(NSInteger)microphoneIndex;

-(void)setMicrophoneIndex:(NSInteger)idx;

-(BOOL)headphonesAvailable;
-(void)setupForMoviePlayer;
-(void)resetForCaptureAfterMoviePlayer;

@end


