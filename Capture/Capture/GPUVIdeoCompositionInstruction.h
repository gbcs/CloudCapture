//
//  GPUVIdeoCompositionInstruction.h
//  Capture
//
//  Created by Gary Barnett on 12/3/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface GPUVIdeoCompositionInstruction : NSObject <AVVideoCompositionInstruction>

@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, assign) BOOL enablePostProcessing;
@property (nonatomic, assign) BOOL containsTweening;
@property (nonatomic, strong) NSArray *requiredSourceTrackIDs;
@property (nonatomic, assign) CMPersistentTrackID passthroughTrackID; // kCMPersistentTrackID_Invalid if not a passthrough instruction

- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange;
- (id)initTransitionWithSourceTrackIDs:(NSArray*)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange;

@end

