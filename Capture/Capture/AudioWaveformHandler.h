//
//  AudioWaveformHandler.h
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioSampleDelegate <NSObject>
-(void)sampleIsReady:(NSNumber *)index;
@end

@interface AudioWaveformHandler : NSObject
-(void)processSamplesForAudioTrack:(AVURLAsset *)asset samplesPerSecond:(NSInteger)samplesPerSecond forIndex:(NSInteger)index withDelegate:(NSObject <AudioSampleDelegate> *)responseDelegate;
-(void)cleanup;
@end
