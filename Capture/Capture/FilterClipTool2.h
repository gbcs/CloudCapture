//
//  FilterClipTool2.h
//  Capture
//
//  Created by Gary Barnett on 1/12/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilterClipTool2 : NSObject
@property (nonatomic, copy) NSArray *cutList;
@property (nonatomic, copy) AVURLAsset *clip;

-(void)filterSampleBuffer:(CMSampleBufferRef)sampleBuffer frameSize:(CGSize)frameSize timestamp:(CMTime)timestamp;

-(void)setup;
-(void)shutdown;

@end

