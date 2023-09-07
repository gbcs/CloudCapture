//
//  MakeVideoFromImage.h
//  Capture
//
//  Created by Gary Barnett on 12/30/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MakeVideoFromImageDelegate <NSObject>
-(void)makeVideoComplete:(BOOL)success withPath:(NSString *)path;
@end

@interface MakeVideoFromImage : NSObject
-(void)startVideoCaptureOfDuration:(NSInteger)seconds usingImage:(UIImage *)image usingPath:(NSString *)path andDelegate:(NSObject <MakeVideoFromImageDelegate> *)delegate startRect:(CGRect)startRect endRect:(CGRect)endRect;
-(void)cancel;

@end
