//
//  GPUFilterTool.h
//  Capture
//
//  Created by Gary Barnett on 12/2/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@protocol GPUFilterToolDelegate <NSObject>
-(void)hasGeneratedFilterThumbnailsForImage:(UIImage *)image;
@end

@interface GPUFilterTool : NSObject
@property (nonatomic, weak) NSObject <GPUFilterToolDelegate> *delegate;
+(GPUFilterTool *)bag;

-(void)generateFilterThumbnailsForUIImage:(UIImage *)image;
-(NSArray *)filterNames;
-(NSInteger)filterCount;
-(UIImage *)thumbnailForFilterAtIndex:(NSInteger)index;
-(UIImage *)generateImageForCGImage:(CGImageRef )image withFilterAtIndex:(NSInteger)index usingAttributes:(NSDictionary *)attributes;
-(NSDictionary *)attributesForFilterAtIndex:(NSInteger )index;

@end
