//
//  FilterTool.h
//  Capture
//
//  Created by Gary Barnett on 9/2/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@protocol FilterToolHistogramDelegate <NSObject>
-(void)didGenerateHistogram:(GPUImageOutput  *)histogram withPicture:(GPUImagePicture *)picture;
-(BOOL)isReadyForImage;
@end

@protocol FilterToolRemotePreviewDelegate <NSObject>
-(BOOL)isReadyForRemotePreviewImage;
-(void)didGenerateRemotePreview:(NSData * )data;
@end

@interface FilterTool : NSObject
@property (nonatomic, assign) BOOL readyForRemotePreviewFrame;

-(void)rebuildFilterInfo:(NSInteger)width;
-(void)updateContrast:(float)val;
-(void)updateBrightness:(float)val;
-(void)updateSaturation:(float)val;

-(CIImage *)filterImageWithSourceImage:(CIImage *)sourceImage withContext:(CIContext *)context;
-(void)updateImageEffectParameters:(NSString *)effectName withDict:(NSDictionary *)parameters;

-(void)updateTitleForBegin;
-(void)updateTitleForEnd;
-(void)updateWatermark;

@end
