//
//  SpriteTitlingTool.h
//  Capture
//
//  Created by Gary Barnett on 1/23/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol SpriteTitlingImageDelegate
-(void)copyImage:(CGImageRef )image;
@end

@interface SpriteTitlingTool : NSObject
@property (nonatomic, readonly) CADisplayLink *displayLink;
-(void)setupWithDict:(NSDictionary *)instructions;
-(void)presentInView:(UIView *)v;
-(void)imageDelegate:(NSObject <SpriteTitlingImageDelegate> *)d;
-(void)cleanup;
-(void)recordToPath:(NSString *)moviePath forLength:(NSInteger)seconds;

@end
