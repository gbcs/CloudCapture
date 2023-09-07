//
//  AudioWaveformHandler.m
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioWaveformHandler.h"
#import "AudioWaveformView.h"

@implementation AudioWaveformHandler {
    NSInteger index;
    NSObject <AudioSampleDelegate> *delegate;
    AVAssetReader *reader;
    AVAssetReaderTrackOutput *output;

}

-(void)dealloc {
    [self cleanup];
}

-(void)cleanup {
    output = nil;
    reader = nil;
    delegate = nil;
    index = 0;
}


-(void)finishedWithSample {
    [delegate performSelectorOnMainThread:@selector(sampleIsReady:) withObject:@(index) waitUntilDone:NO];
}

-(void)processSamplesForAudioTrack:(AVURLAsset *)asset
                  samplesPerSecond:(NSInteger)samplesPerSecond
                          forIndex:(NSInteger)atIndex
                      withDelegate:(NSObject <AudioSampleDelegate> *)responseDelegate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        index = atIndex;
        delegate = responseDelegate;
        
        NSLog(@"duration:%@", [NSValue valueWithCMTime:asset.duration]);
        
        NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count]<1) {
            return ;
        }
        
        AVAssetTrack *audioTrack = [audioTracks objectAtIndex:0];
        
        AudioChannelLayout channelLayout;
        memset(&channelLayout, 0, sizeof(AudioChannelLayout));
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
        NSDictionary *audioReadSettings =  [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                            [NSNumber numberWithFloat:48000.0], AVSampleRateKey,
                                            [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                            [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],
                                            AVChannelLayoutKey,
                                            [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                            [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                            [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                            [NSNumber numberWithBool:YES], AVLinearPCMIsBigEndianKey,
                                            nil];
        
        
        output = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:audioReadSettings];
        
        reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
        
        [reader addOutput:output];
        [reader startReading];
        
        
        CGFloat maxValL = 0.0f;
        CGFloat maxValR = 0.0f;
        
        NSInteger samplesPerPixel = 48000 / samplesPerSecond;
        
        NSLog(@"samplesPerPixel:%ld", (long)samplesPerPixel);
        
        NSLog(@"Expected:%f", 48000.0f * (asset.duration.value / asset.duration.timescale) );
        NSInteger samplesPerFile = 5000;
        NSMutableArray *sampleList = [[NSMutableArray alloc] initWithCapacity:samplesPerFile];
        
        NSInteger currentFile = 0;
        
            //CGFloat factor = 12.0f / 128.0f;
        
        BOOL keepReading = YES;
       
        NSInteger sampleIndex = 1;
        NSInteger sampleOffset = 0;
        NSInteger sampleCount = 0;
        while (keepReading) {
            CMSampleBufferRef sample = [output copyNextSampleBuffer];
            keepReading = !(sample == NULL);
            if (keepReading) {
                CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer( sample );
                CMItemCount numSamples = CMSampleBufferGetNumSamples(sample);
                    //CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sample);
                    //NSLog(@"%@", [NSValue valueWithCMTime:timestamp]);
                size_t lengthAtOffset;
                size_t totalLength;
                char* data;
                
                if( CMBlockBufferGetDataPointer( buffer, 0, &lengthAtOffset, &totalLength, &data ) != noErr ) {
                    NSLog( @"error!" );
                    break;
                }
                
                for (NSInteger i=0; i<numSamples; i++) {
                    sampleOffset += 1;
                    sampleCount++;
                    SInt16 l = (SInt16) *data;
                    data+=2;
                    
                    SInt16 r = (SInt16) *data;
                    data+=2;
                    
                    if (maxValL < l) {
                        maxValL = l;
                    }
                    
                    if (maxValR < r) {
                        maxValR = r;
                    }
                    
                    if (sampleOffset >= samplesPerPixel) {
                        sampleOffset = 0;
                        sampleIndex++;
                        
                        [sampleList addObject:@[ @(maxValL) , @(maxValR)]];
                        
                        maxValL = 0.0f;
                        maxValR = 0.0f;
                        
                        if (sampleIndex % samplesPerFile == 0) {
                            [self writeImageWithSamples:sampleList withIndex:index andFile:currentFile];
                            sampleList = [@[ ] mutableCopy];
                            currentFile++;
                        }
                    } 
                }
            }
            
            if(sample) {
                CFRelease(sample);
            }
        }
        
        if ([sampleList count]>0) {
            [self writeImageWithSamples:sampleList withIndex:index andFile:currentFile];
        }
        NSLog(@"Got %ld samples", (long)sampleCount);
        
        [self finishedWithSample];
    });
}

-(void)writeImageWithSamples:(NSMutableArray *)samples withIndex:(NSInteger)idx andFile:(NSInteger)file {
    dispatch_semaphore_t semaphore =  dispatch_semaphore_create(1);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            AudioWaveformView *v = [[AudioWaveformView alloc] initWithFrame:CGRectMake(0,0,1,48)];
            v.entryList = samples;
            [v update];
            
            NSString *filename = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld_%ld.sampleView", (long)idx, (long)file]];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filename error:&error];
            
            UIGraphicsBeginImageContext(v.bounds.size);
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            [v.layer renderInContext:context];
            
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            
            NSData *data = UIImageJPEGRepresentation(image, 0.6);
            [data writeToFile:filename atomically:NO];
            [v cleanup];
             
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
}


@end
