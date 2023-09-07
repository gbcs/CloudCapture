//
//  AudioManager.m
//  Capture
//
//  Created by Gary Barnett on 7/19/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioManager {
    BOOL running;
    BOOL playbackMode;
    NSInteger microphoneIndex;
    BOOL allowHeadphones;
    BOOL audioUnitRunning;
}

static AudioManager  *sharedSettingsManager = nil;
AudioUnit *audioUnit = NULL;
float *convertedSampleBuffer = NULL;


-(BOOL)headphonesAvailable {
    return allowHeadphones;
}

OSStatus renderCallback(void *userData, AudioUnitRenderActionFlags *actionFlags,
                        const AudioTimeStamp *audioTimeStamp, UInt32 busNumber,
                        UInt32 numFrames, AudioBufferList *buffers) {
    OSStatus status = AudioUnitRender(*audioUnit, actionFlags, audioTimeStamp,
                                      1, numFrames, buffers);
    if(status != noErr) {
        return status;
    }
    
    if(convertedSampleBuffer == NULL) {
        // Lazy initialization of this buffer is necessary because we don't
        // know the frame count until the first callback
        convertedSampleBuffer = (float*)malloc(sizeof(float) * numFrames);
    }
    
        //SInt16 *inputFrames = (SInt16*)(buffers->mBuffers->mData);
    /*
    // If your DSP code can use integers, then don't bother converting to
    // floats here, as it just wastes CPU. However, most DSP algorithms rely
    // on floating point, and this is especially true if you are porting a
    // VST/AU to iOS.
    for(int i = 0; i < numFrames; i++) {
        convertedSampleBuffer[i] = (float)inputFrames[i] / 32768.0f;
    }
    
    // Now we have floating point sample data from the render callback! We
    // can send it along for further processing, for example:
    // plugin->processReplacing(convertedSampleBuffer, NULL, sampleFrames);
    
    // Assuming that you have processed in place, we can now write the
    // floating point data back to the input buffer.
    for(int i = 0; i < numFrames; i++) {
        // Note that we multiply by 32767 here, NOT 32768. This is to avoid
        // overflow errors (and thus clipping).
        inputFrames[i] = (SInt16)(convertedSampleBuffer[i] * 32767.0f);
    }
    */
    
    return noErr;
}

+ (AudioManager *)manager
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

-(void)updateSampleRate:(double)sampleRate {
    Float64 hardwareSampleRate = sampleRate ;
    NSLog(@"setting sample rate:%f", sampleRate);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setPreferredSampleRate:hardwareSampleRate error:&err];

    if (err) {
        NSLog(@"Error setting sample rate:%f", sampleRate);
    }
    
    if (audioUnitRunning) {
        [self updateAudioUnit];
    }
}


-(void)startup {
    if (running) {
        return;
    }
    
    running = YES;

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSessionSetPlayAndRecord: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err){
        NSLog(@"audioSessionSetActive: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionMediaServicesLostNotification:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionMediaServicesResetNotification:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    
}

-(void)shutdown {
    if (!running) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionMediaServicesWereLostNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setActive:NO error:&err];

    running = NO;
 
    [self updateAudioUnit];
}

-(void)setupSpeakerOverride {
    if (!running) {
        return;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    
    BOOL status = [audioSession overrideOutputAudioPort:  playbackMode ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone error:&error];
    if (!status) {
        NSLog(@"setupSpeakerOverride error:%@", error);
    }
}

-(void)playbackMode:(BOOL)enabled {
   
    playbackMode = enabled;
    
    if (running) {
        [self setupSpeakerOverride];
    }
}

-(void)setupForMoviePlayer {
    [self shutdown];
    NSError *err = nil;
    [[AVAudioSession sharedInstance] setCategory :AVAudioSessionCategoryPlayback error:&err];
}

-(void)resetForCaptureAfterMoviePlayer {
    [self startup];
}


-(void)audioSessionInterruptionNotification:(NSNotification *)n {
    NSNumber *info = [n.userInfo objectForKey:AVAudioSessionInterruptionTypeKey];
    
    if ([info intValue] == AVAudioSessionInterruptionTypeBegan) {
        NSLog(@"Audio Interruption began");
    } else {
        NSLog(@"Audio Interruption ended");
    }

}

-(NSInteger)microphoneIndex {
    NSInteger count = [[[AVAudioSession sharedInstance] availableInputs] count];
    if (microphoneIndex >= count) {
        microphoneIndex = count -1;
    }
    return microphoneIndex;
}

-(void)setMicrophoneIndex:(NSInteger)index {
    NSInteger count = [[[AVAudioSession sharedInstance] availableInputs] count];
    if (index >= count) {
        index = count - 1;
    }
    microphoneIndex = index;
}


-(void)audioSessionRouteChangeNotification:(NSNotification *)n {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
   
    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];
    
    NSLog(@"AudioRouteChange:%@", currentRoute);
    
    AVAudioSessionPortDescription *outputPort =[currentRoute.outputs objectAtIndex:0];
    
    if ( ([outputPort.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) ||  ([outputPort.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) ) {
        allowHeadphones = NO;
    } else {
        allowHeadphones = YES;
    }
    
    [self updateAudioUnit];
    
}

-(void)updateAudioUnit {
    if (audioUnitRunning) {
        NSLog(@"Shutdown Audio Unit");
        OSStatus result = AudioOutputUnitStop(*audioUnit);
        
        if( result != noErr) {
            NSLog(@"stopProcessingAudio: error AudioOutputUnitStop:%@", [[UtilityBag bag] strForOSSStatus:result]);
        }
        
        
        OSStatus result2 = AudioUnitUninitialize(*audioUnit);
        
        if(result2 != noErr) {
            NSLog(@"stopProcessingAudio: error AudioUnitUninitialize:%@", [[UtilityBag bag] strForOSSStatus:result2]);
        }
        
        AudioComponentInstanceDispose(*audioUnit);
        
        *audioUnit = NULL;
         audioUnitRunning = NO;
       
    }

    if (!running) {
        return; //shutdown
    }

    if (allowHeadphones && [[SettingsTool settings] audioMonitoring]) {
        NSLog(@"Start Audio Unit");
        audioUnitRunning = YES;
        audioUnit = (AudioUnit*)malloc(sizeof(AudioUnit));
        
        AudioComponentDescription componentDescription;
        componentDescription.componentType = kAudioUnitType_Output;
        componentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
        componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        componentDescription.componentFlags = 0;
        componentDescription.componentFlagsMask = 0;
        AudioComponent component = AudioComponentFindNext(NULL, &componentDescription);
        OSStatus r;
        
        r = AudioComponentInstanceNew(component, audioUnit);
        if(r != noErr) {
            NSLog(@"AudioComponentInstanceNew:%@", [[UtilityBag bag] strForOSSStatus:r]);
        }
        UInt32 enable = 1;
        r = AudioUnitSetProperty(*audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enable, sizeof(UInt32));
        if(r != noErr) {
            NSLog(@"kAudioOutputUnitProperty_EnableIO:%@", [[UtilityBag bag] strForOSSStatus:r]);
        }
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = renderCallback; // Render function
        callbackStruct.inputProcRefCon = NULL;
        r = AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(AURenderCallbackStruct));
        if(r != noErr) {
            NSLog(@"kAudioUnitProperty_SetRenderCallback:%@", [[UtilityBag bag] strForOSSStatus:r]);
        }
        AudioStreamBasicDescription streamDescription;
            // You might want to replace this with a different value, but keep in mind that the
            // iPhone does not support all sample rates. 8kHz, 22kHz, and 44.1kHz should all work.
        streamDescription.mSampleRate = [[SettingsTool settings] audioSamplerate];
            // Yes, I know you probably want floating point samples, but the iPhone isn't going
            // to give you floating point data. You'll need to make the conversion by hand from
            // linear PCM <-> float.
        streamDescription.mFormatID = kAudioFormatLinearPCM;
            // This part is important!
        streamDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger |  kAudioFormatFlagsNativeEndian |  kAudioFormatFlagIsPacked;
            // Not sure if the iPhone supports recording >16-bit audio, but I doubt it.
        streamDescription.mBitsPerChannel = 16;
            // 1 sample per frame, will always be 2 as long as 16-bit samples are being used
        streamDescription.mBytesPerFrame = 2;
            // Record in mono. Use 2 for stereo, though I don't think the iPhone does true stereo recording
        streamDescription.mChannelsPerFrame = 1;
        streamDescription.mBytesPerPacket = streamDescription.mBytesPerFrame * streamDescription.mChannelsPerFrame;
            // Always should be set to 1
        streamDescription.mFramesPerPacket = 1;
            // Always set to 0, just to be sure
        streamDescription.mReserved = 0;

            // Set up input stream with above properties
        r = AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Input, 0, &streamDescription, sizeof(streamDescription));
        if(r != noErr) {
            NSLog(@"kAudioUnitProperty_StreamFormat:input:%@", [[UtilityBag bag] strForOSSStatus:r]);
        }
            // Ditto for the output stream, which we will be sending the processed audio to
        r = AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_StreamFormat,   kAudioUnitScope_Output, 1, &streamDescription, sizeof(streamDescription)) ;
        if(r != noErr) {
            NSLog(@"kAudioUnitProperty_StreamFormat:output:%@", [[UtilityBag bag] strForOSSStatus:r]);
        }
        OSStatus result =AudioUnitInitialize(*audioUnit);
        if(result != noErr) {
            NSLog(@"startAudioUnit: error AudioUnitInitialize:%@", [[UtilityBag bag] strForOSSStatus:result]);
        }
        
        OSStatus result2 =AudioOutputUnitStart(*audioUnit);
        if(result2 != noErr) {
            NSLog(@"startAudioUnit: error AudioOutputUnitStart%@", [[UtilityBag bag] strForOSSStatus:result2]);
        }
        
        NSLog(@"startAudioUnit:success");

       
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadEngine" object:nil];
    });
}

-(void)audioSessionMediaServicesLostNotification:(NSNotification *)n {
    NSLog(@"audioSessionMediaServicesLostNotification");
}

-(void)audioSessionMediaServicesResetNotification:(NSNotification *)n {
     NSLog(@"audioSessionMediaServicesResetNotification");
}

-(void)reportStatus {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadEngine" object:nil];

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
   
    if (1 == 1) {
        NSLog(@"audio status report: igs:%d ig:%f mode:%@ pi:%@", audioSession.inputGainSettable, audioSession.inputGain, audioSession.mode, audioSession.preferredInput);
        for (AVAudioSessionDataSourceDescription *i in audioSession.inputDataSources) {
             NSLog(@"%@:%@", i,i.supportedPolarPatterns );
        }
    }
}

@end
