//
//  FilterClipTool2.m
//  Capture
//
//  Created by Gary Barnett on 1/12/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "FilterClipTool2.h"

@implementation FilterClipTool2 {
    __block GPUImageOutput<GPUImageInput> *filter;
    __block GPUImageRawDataInput *rawDataInput;
    __block GPUImageRawDataOutput *rawDataOutput;
    
    __block NSInteger currentCut;
    __block NSInteger cutCount;
    
    __block BOOL isInCut;
    __block BOOL setupCut;
    __block BOOL blockReady;
    __block BOOL firstFilterPass;
    __block NSArray *rangeList;
    dispatch_semaphore_t dataUpdateSemaphore;
    dispatch_semaphore_t readDataSemaphore;
    __block GLubyte *outputBytes;
    CIContext *ciContext;
}

-(void)setup {
    
    isInCut = NO;
    setupCut = YES;
    currentCut = 0;
    cutCount = [self.cutList count];
    firstFilterPass = YES;
    
    
    if (cutCount < 1) {
        rangeList = [NSArray array];
        return;
    }
    
    ciContext = [CIContext contextWithEAGLContext:[EAGLContext currentContext]];
    
    NSMutableArray *ranges = [[NSMutableArray alloc] initWithCapacity:cutCount];
    
    for (NSArray *cut in self.cutList) {
        CMTime begin = [[cut objectAtIndex:0] CMTimeValue];
        CMTime end = [[cut objectAtIndex:1] CMTimeValue];
        
        [ranges addObject:[NSValue valueWithCMTimeRange:CMTimeRangeFromTimeToTime(begin, end)]];
    }
    
    rangeList = [ranges copy];
    dataUpdateSemaphore = dispatch_semaphore_create(1);
    readDataSemaphore = dispatch_semaphore_create(1);
}


-(void)filterSampleBuffer:(CMSampleBufferRef)sampleBuffer frameSize:(CGSize)frameSize timestamp:(CMTime)timestamp {
    @autoreleasepool {
        if (cutCount < 1) {
            return; // no cuts
        }
        
        if (currentCut >= cutCount) {
            return; //last cut ended
        }
        
        __weak FilterClipTool2* weakSelf = self;
        CIFilter *ciFilter = nil;
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer,0);
        
        NSInteger bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
        NSInteger bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
        CGSize bufferSize = CGSizeMake(bufferWidth, bufferHeight);
        GLubyte *pixel = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
        
        if (isInCut) {
            CMTimeRange r = [[rangeList objectAtIndex:currentCut] CMTimeRangeValue];
            if (!CMTimeRangeContainsTime(r, timestamp)) {
                isInCut = NO;
                currentCut++;
            }
            
            [rawDataInput removeTarget:filter];
            [filter removeTarget:rawDataOutput];
            
            rawDataInput = nil;
            rawDataOutput = nil;
            filter = nil;
            
            firstFilterPass = YES;
        }
        
        for (NSInteger x=currentCut;x<cutCount;x++) {
            CMTimeRange r = [[rangeList objectAtIndex:x] CMTimeRangeValue];
            if (CMTimeRangeContainsTime(r, timestamp)) {
                isInCut = YES;
                currentCut = x;
                //    filtersBuiltThisPass = YES;
                // build filter array for this cut
                NSInteger filterIndex = [[[self.cutList objectAtIndex:currentCut] objectAtIndex:2][0] integerValue];
                NSDictionary *attributes = [[self.cutList objectAtIndex:currentCut] objectAtIndex:2][1];
                NSString *name = [[[GPUFilterTool bag] filterNames] objectAtIndex:filterIndex];
                
                //NSLog(@"setup cut:%@:%@",name, attributes);
                
                if ([name isEqualToString:@"Toon"]) {
                    GPUImageToonFilter *stillImageFilter = [[GPUImageToonFilter alloc] init];
                    if ([attributes objectForKey:@"threshold"]) {
                        stillImageFilter.threshold = [[attributes objectForKey:@"threshold"] floatValue];
                    }
                    if ([attributes objectForKey:@"quantizationLevels"]) {
                        stillImageFilter.quantizationLevels = [[attributes objectForKey:@"quantizationLevels"] floatValue];
                    }
                    filter = stillImageFilter;
                } else if ([name isEqualToString:@"Sepia"]) {
                    GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];
                    if ([attributes objectForKey:@"intensity"]) {
                        stillImageFilter.intensity = [[attributes objectForKey:@"intensity"] floatValue];
                    }
                    filter = stillImageFilter;
                } else if ([name isEqualToString:@"Smooth Toon"]) {
                    GPUImageSmoothToonFilter *stillImageFilter = [[GPUImageSmoothToonFilter alloc] init];
                    if ([attributes objectForKey:@"blurRadiusInPixels"]) {
                        stillImageFilter.blurRadiusInPixels = [[attributes objectForKey:@"blurRadiusInPixels"] floatValue];
                    }
                    
                    if ([attributes objectForKey:@"threshold"]) {
                        stillImageFilter.threshold = [[attributes objectForKey:@"threshold"] floatValue];
                    }
                    if ([attributes objectForKey:@"quantizationLevels"]) {
                        stillImageFilter.quantizationLevels = [[attributes objectForKey:@"quantizationLevels"] floatValue];
                    }
                    filter = stillImageFilter;
                } else if ([name isEqualToString:@"Threshold Sketch"]) {
                    GPUImageThresholdSketchFilter *f = [[GPUImageThresholdSketchFilter alloc] init];
                    f.threshold =[[attributes objectForKey:@"threshold"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Tilt Shift"]) {
                    GPUImageTiltShiftFilter *f = [[GPUImageTiltShiftFilter alloc] init];
                    
                    CGFloat midpoint = [[attributes objectForKey:@"midpoint"] floatValue];
                    [f setTopFocusLevel:midpoint - 0.1f];
                    [f setBottomFocusLevel:midpoint + 0.1f];
                    [f setFocusFallOffRate:0.2];
                    filter = f;
                    
                } else if ([name isEqualToString:@"Gaussian Blur"]) {
                    GPUImageGaussianBlurFilter *f = [[GPUImageGaussianBlurFilter alloc] init];
                    f.blurRadiusInPixels =[[attributes objectForKey:@"blurRadiusInPixels"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Saturation"]) {
                    GPUImageSaturationFilter *f = [[GPUImageSaturationFilter alloc] init];
                    f.saturation = [[attributes objectForKey:@"saturation"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Contrast"]) {
                    GPUImageContrastFilter *f = [[GPUImageContrastFilter alloc] init];
                    f.contrast = [[attributes objectForKey:@"contrast"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Brightness"]) {
                    GPUImageBrightnessFilter *f = [[GPUImageBrightnessFilter alloc] init];
                    f.brightness = [[attributes objectForKey:@"brightness"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Exposure"]) {
                    GPUImageExposureFilter *f = [[GPUImageExposureFilter alloc] init];
                    f.exposure = [[attributes objectForKey:@"exposure"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"WhiteBalance"]) {
                    GPUImageWhiteBalanceFilter *f = [[GPUImageWhiteBalanceFilter alloc] init];
                    f.temperature = [[attributes objectForKey:@"temperature"] intValue];
                    filter = f;
                } else if ([name isEqualToString:@"Tone Curve"]) {
                    GPUImageToneCurveFilter *f = [[GPUImageToneCurveFilter alloc] init];
                    
                    [f setBlueControlPoints:@[ [NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)],
                                               [NSValue valueWithCGPoint:CGPointMake(0.5, [[attributes objectForKey:@"value"] floatValue])],
                                               [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)]
                                               ] ];
                    filter = f;
                } else if ([name isEqualToString:@"Luminance Threshold"]) {
                    GPUImageLuminanceThresholdFilter *f = [[GPUImageLuminanceThresholdFilter alloc] init];
                    f.threshold = [[attributes objectForKey:@"threshold"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Grayscale"]) {
                    GPUImageGrayscaleFilter *f = [[GPUImageGrayscaleFilter alloc] init];
                    filter =f;
                } else if ([name isEqualToString:@"Color Invert"]) {
                    GPUImageColorInvertFilter *f = [[GPUImageColorInvertFilter alloc] init];
                    filter = f;
                } else if ([name isEqualToString:@"Low Pass"]) {
                    GPUImageLowPassFilter *f = [[GPUImageLowPassFilter alloc] init];
                    f.filterStrength = [[attributes objectForKey:@"filterStrength"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Sketch"]) {
                    GPUImageSketchFilter *f = [[GPUImageSketchFilter alloc] init];
                    f.edgeStrength = [[attributes objectForKey:@"edgeStrength"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Posterize"]) {
                    GPUImagePosterizeFilter *f = [[GPUImagePosterizeFilter alloc] init];
                    f.colorLevels = [[attributes objectForKey:@"colorLevels"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Emboss"]) {
                    GPUImageEmbossFilter *f = [[GPUImageEmbossFilter alloc] init];
                    f.intensity = [[attributes objectForKey:@"intensity"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Vignette"]) {
                    GPUImageVignetteFilter *f = [[GPUImageVignetteFilter alloc] init];
                    f.vignetteEnd = [[attributes objectForKey:@"vignetteEnd"] floatValue];
                    filter = f;
                } else if ([name isEqualToString:@"Stretch"]) {
                    GPUImageStretchDistortionFilter *f = [[GPUImageStretchDistortionFilter alloc] init];
                    f.center = CGPointMake(0.5f, 0.5f);
                    filter = f;
                } else if ([name isEqualToString:@"Noir"]) {
                    ciFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
                } else if ([name isEqualToString:@"Chrome"]) {
                    ciFilter = [CIFilter filterWithName:@"CIPhotoEffectChrome"];
                } else if ([name isEqualToString:@"Fade"]) {
                    ciFilter = [CIFilter filterWithName:@"CIPhotoEffectFade"];
                } else if ([name isEqualToString:@"Instant"]) {
                    ciFilter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];;
                } else if ([name isEqualToString:@"Process"]) {
                    ciFilter = [CIFilter filterWithName:@"CIPhotoEffectProcess"];
                } else if ([name isEqualToString:@"Tonal"]) {
                    ciFilter = [CIFilter filterWithName:@"CIPhotoEffectTonal"];
                } else if ([name isEqualToString:@"Transfer"]) {
                    ciFilter = [CIFilter filterWithName:@"CIPhotoEffectTransfer"];
                }
                break;
            }
        }
        
        if (isInCut && filter)  {
           rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:pixel size:bufferSize pixelFormat:GPUPixelFormatBGRA type:GPUPixelTypeUByte];
             rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:bufferSize resultsInBGRAFormat:YES];
            [rawDataOutput setNewFrameAvailableBlock:^{
                [weakSelf releaseSemaphore];
                [weakSelf waitOnRead];
            }];
            
            [rawDataInput addTarget:filter];
            [filter addTarget:rawDataOutput];
         
            [rawDataInput processData];
            
            if (dispatch_semaphore_wait(dataUpdateSemaphore, DISPATCH_TIME_NOW) != 0)
            {
                NSLog(@"semaphore creation problem. filter");
                return;
            }
            
            memcpy(pixel, [rawDataOutput rawBytesForImage], bufferHeight * bufferWidth *4);
        
            dispatch_semaphore_signal(readDataSemaphore);
        } else if (isInCut && ciFilter) {
            CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            [ciFilter setValue:image forKey:@"inputImage"];
            CIImage *imageOut = ciFilter.outputImage;
            [ciContext render:imageOut toCVPixelBuffer:pixelBuffer];
        }
    
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        pixel = nil;
    }
}


-(void)waitOnRead {
    if (dispatch_semaphore_wait(readDataSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        NSLog(@"semaphore creation problem. rawdataoutput");
        return;
    }
}

-(void)setBytes:(GLubyte *)b {
    outputBytes = b;
}


-(void)releaseSemaphore {
    dispatch_semaphore_signal(dataUpdateSemaphore);
}

-(BOOL)isBlockReady {
    return blockReady;
}

-(void)setBlockReady:(BOOL)ready {
    blockReady = ready;
}


-(void)shutdown {
    
}


@end
