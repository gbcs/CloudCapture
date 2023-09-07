//
//  GPUMakeVideoFromImage.h
//  Capture
//
//  Created by Gary Barnett on 2/14/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FilterClipTool2.h"

@protocol GPUMakeVideoFromImageDelegate <NSObject>
-(void)makeVideoComplete:(BOOL)success withPath:(NSString *)path;
@end

@interface GPUMakeVideoFromImage : NSObject

-(void)startVideoCaptureOfDuration:(NSInteger)seconds usingImage:(UIImage *)image usingPath:(NSString *)path andDelegate:(NSObject <GPUMakeVideoFromImageDelegate> *)delegate startRect:(CGRect)startRect endRect:(CGRect)endRect;
-(void)cancel;

@end
