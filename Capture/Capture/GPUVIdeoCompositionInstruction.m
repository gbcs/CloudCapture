//
//  GPUVIdeoCompositionInstruction.m
//  Capture
//
//  Created by Gary Barnett on 12/3/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "GPUVIdeoCompositionInstruction.h"

@implementation GPUVIdeoCompositionInstruction

@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;

-(void)dealloc {
        // //NSLog(@"%s", __func__);
}



- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange
{
	self = [super init];
	if (self) {
		_passthroughTrackID = passthroughTrackID;
		_requiredSourceTrackIDs = nil;
		_timeRange = timeRange;
		_containsTweening = FALSE;
		_enablePostProcessing = FALSE;
	}
	
	return self;
}

- (id)initTransitionWithSourceTrackIDs:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange
{
	self = [super init];
	if (self) {
		_requiredSourceTrackIDs = sourceTrackIDs;
		_passthroughTrackID = kCMPersistentTrackID_Invalid;
		_timeRange = timeRange;
		_containsTweening = TRUE;
		_enablePostProcessing = FALSE;
	}
	
	return self;
}

@end
