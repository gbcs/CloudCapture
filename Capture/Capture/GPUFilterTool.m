//
//  GPUFilterTool.m
//  Capture
//
//  Created by Gary Barnett on 12/2/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "GPUFilterTool.h"
#include <sys/param.h>
#include <sys/mount.h>
#import <ImageIO/ImageIO.h>

@implementation GPUFilterTool {

}

static GPUFilterTool  *sharedSettingsManager = nil;

+ (GPUFilterTool *)bag
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
    }
    
    return sharedSettingsManager ;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self bag];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(NSArray *)filterList {
    return [self filterNames];
}

-(NSArray *)filterNames {
    return @[
              @"Toon",
              @"Smooth Toon",
              @"Threshold Sketch",
              @"Tilt Shift",
              @"Gaussian Blur",
              @"Saturation",
              @"Contrast",
              @"Brightness",
              @"Exposure",
              @"WhiteBalance",
              @"Tone Curve",
              @"Luminance Threshold",
              @"Sepia",
              @"Grayscale",
              @"Color Invert",
              @"Low Pass",
              @"Sketch",
              @"Posterize",
              @"Emboss",
              @"Vignette",
              @"Stretch",
              @"Noir",
              @"Chrome",
              @"Fade",
              @"Instant",
              @"Process",
              @"Tonal",
              @"Transfer"
              ];
}



-(NSDictionary *)attributesForFilterAtIndex:(NSInteger )index {
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    NSString *name = [[self filterList] objectAtIndex:index];
    
    if ([name isEqualToString:@"Toon"]) {
        [d setObject:@[ @(0.0f), @(0.2f), @(1.0f), @(0.01f), @(0.2f)] forKey:@"threshold"];
        [d setObject:@[ @(1), @(10), @(20), @(1), @(10)] forKey:@"quantizationLevels"];
    } else if ([name isEqualToString:@"Smooth Toon"]) {
        [d setObject:@[ @(1), @(2), @(32), @(1), @(2)] forKey:@"blurRadiusInPixels"];
        [d setObject:@[ @(0.0f), @(0.2f), @(1.0f), @(0.01f), @(0.2f)] forKey:@"threshold"];
        [d setObject:@[ @(1), @(10), @(20), @(1), @(10)] forKey:@"quantizationLevels"];
    } else if ([name isEqualToString:@"Sepia"]) {
        [d setObject:@[ @(0.0f), @(1.0f), @(1.0f), @(0.02f), @(1.0f)] forKey:@"intensity"];
    } else if ([name isEqualToString:@"Threshold Sketch"]) {
        [d setObject:@[ @(0.0f), @(0.5f), @(1.0f), @(0.05f)] forKey:@"threshold"];
    } else if ([name isEqualToString:@"Tilt Shift"]) {
        [d setObject:@[ @(0.2f), @(0.5f), @(0.8f), @(0.02f), @(0.5f)] forKey:@"midpoint"];
    } else if ([name isEqualToString:@"Gaussian Blur"]) {
        [d setObject:@[ @(1.0f), @(2.0f), @(24.0f), @(0.05f), @(2.0f)] forKey:@"blurRadiusInPixels"];
    } else if ([name isEqualToString:@"Saturation"]) {
        [d setObject:@[ @(0.0f), @(1.0f), @(2.0f), @(0.01f), @(1.5f)] forKey:@"saturation"];
    } else if ([name isEqualToString:@"Contrast"]) {
        [d setObject:@[ @(0.0f), @(1.0f), @(4.0f), @(0.02f), @(2.0f)] forKey:@"contrast"];
    } else if ([name isEqualToString:@"Brightness"]) {
        [d setObject:@[ @(-1.0f), @(0.0f), @(1.0f), @(0.01f), @(0.3f)] forKey:@"brightness"];
    } else if ([name isEqualToString:@"Exposure"]) {
        [d setObject:@[ @(-4.0f), @(0.0f), @(4.0f), @(0.02f), @(1.0f)] forKey:@"exposure"];
    } else if ([name isEqualToString:@"WhiteBalance"]) {
        [d setObject:@[ @(2500.f), @(5000.f), @(7500.f), @(100.f), @(5000.f)] forKey:@"temperature"];
    } else if ([name isEqualToString:@"Tone Curve"]) {
        [d setObject:@[ @(0.0f), @(0.5f), @(1.0f), @(0.01f), @(0.5f)] forKey:@"value"];
    } else if ([name isEqualToString:@"Luminance Threshold"]) {
        [d setObject:@[ @(0.2f), @(0.5f), @(0.8f), @(0.02f), @(0.5f)] forKey:@"threshold"];
    } else if ([name isEqualToString:@"Grayscale"]) {
        [d setObject:@[ @(0.0f), @(0.0f), @(0.0f), @(0.00f), @(0.0f)] forKey:@"none"];
    } else if ([name isEqualToString:@"Color Invert"]) {
        [d setObject:@[ @(0.0f), @(0.0f), @(0.0f), @(0.00f), @(0.0f)] forKey:@"none"];
    } else if ([name isEqualToString:@"Low Pass"]) {
        [d setObject:@[ @(0.0f), @(0.5f), @(1.0f), @(0.01f), @(0.5f)] forKey:@"filterStrength"];
    } else if ([name isEqualToString:@"Sketch"]) {
        [d setObject:@[ @(0.0f), @(0.25f), @(1.0f), @(0.01f), @(0.25f)] forKey:@"edgeStrength"];
    } else if ([name isEqualToString:@"Posterize"]) {
        [d setObject:@[ @(1.0f), @(10.0f), @(20.0f), @(0.01f), @(10.0f)] forKey:@"colorLevels"];
    } else if ([name isEqualToString:@"Emboss"]) {
        [d setObject:@[ @(1.0f), @(10.0f), @(20.0f), @(0.25f), @(10.0f)] forKey:@"intensity"];
    } else if ([name isEqualToString:@"Vignette"]) {
        [d setObject:@[ @(0.5f), @(0.75f), @(0.9f), @(0.02f), @(0.5f)] forKey:@"vignetteEnd"];
    } else if ([name isEqualToString:@"Stretch"]) {
        [d setObject:@[ @(0.0f), @(0.0f), @(0.0f), @(0.00f), @(0.0f)] forKey:@"none"];
    } else {
        [d setObject:@[ @(0.0f), @(0.0f), @(0.0f), @(0.00f), @(0.0f)] forKey:@"none"];
    }

  
    return [d copy];
}

-(UIImage *)generateImageForCGImage:(CGImageRef )image withFilterAtIndex:(NSInteger)index usingAttributes:(NSDictionary *)attributes {
    UIImage *inputImage = [UIImage imageWithCGImage:image];
    
    NSString *filterName = [[self filterList] objectAtIndex:index];
    return [self filteredImageForName:filterName andSource:inputImage andAttributes:attributes];
}

-(void)generateFilterThumbnailsForUIImage:(UIImage *)image {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        for (NSInteger x = 0;x < [[self filterList] count];x++) {
            NSString *filterName = [[self filterList] objectAtIndex:x];
            UIImage *inputImage = image;
            UIImage *outputImage = [self filteredImageForName:filterName andSource:inputImage andAttributes:nil];
          
            NSData *imageData = UIImagePNGRepresentation(outputImage);
            NSString *fname = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:[NSString stringWithFormat:@"f%ld.png", (long)x]];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:fname error:&error];
            [imageData writeToFile:fname atomically:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"filterGeneratedForThumbnailAtIndex" object:@(x)];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate hasGeneratedFilterThumbnailsForImage:image];
        });
    });
}

-(NSInteger)filterCount {
    return [[self filterList] count];
}

-(UIImage *)thumbnailForFilterAtIndex:(NSInteger)index {
   return [UIImage imageWithContentsOfFile:[[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:[NSString stringWithFormat:@"f%ld.png", (long)index]]];
}

-(UIImage *)filteredImageForName:(NSString *)name andSource:(UIImage *)image andAttributes:(NSDictionary *)attributes {
     UIImage *outputImage = nil;
    if ([name isEqualToString:@"Toon"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageToonFilter *stillImageFilter = [[GPUImageToonFilter alloc] init];
        if ([attributes objectForKey:@"threshold"]) {
                  stillImageFilter.threshold = [[attributes objectForKey:@"threshold"] floatValue];
        }
        if ([attributes objectForKey:@"quantizationLevels"]) {
                 stillImageFilter.quantizationLevels = [[attributes objectForKey:@"quantizationLevels"] floatValue];
        }
        [source addTarget:stillImageFilter];
        [source processImage];
        outputImage = [stillImageFilter imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Sepia"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];
        if ([attributes objectForKey:@"intensity"]) {
                  stillImageFilter.intensity = [[attributes objectForKey:@"intensity"] floatValue];
        }
        [source addTarget:stillImageFilter];
        [source processImage];
        outputImage = [stillImageFilter imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Smooth Toon"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
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
        [source addTarget:stillImageFilter];
        [source processImage];
        outputImage = [stillImageFilter imageFromCurrentlyProcessedOutput];
    }  else if ([name isEqualToString:@"Threshold Sketch"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageThresholdSketchFilter *f = [[GPUImageThresholdSketchFilter alloc] init];
       
        if ([attributes objectForKey:@"threshold"]) {
            f.threshold =[[attributes objectForKey:@"threshold"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Tilt Shift"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageTiltShiftFilter *f = [[GPUImageTiltShiftFilter alloc] init];
        
        if ([attributes objectForKey:@"midpoint"]) {
            CGFloat midpoint = [[attributes objectForKey:@"midpoint"] floatValue];
            [f setTopFocusLevel:midpoint - 0.1f];
            [f setBottomFocusLevel:midpoint + 0.1f];
            [f setFocusFallOffRate:0.2];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
        
    } else if ([name isEqualToString:@"Gaussian Blur"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageGaussianBlurFilter *f = [[GPUImageGaussianBlurFilter alloc] init];
        
        if ([attributes objectForKey:@"blurRadiusInPixels"]) {
            f.blurRadiusInPixels =[[attributes objectForKey:@"blurRadiusInPixels"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Saturation"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageSaturationFilter *f = [[GPUImageSaturationFilter alloc] init];
        
        if ([attributes objectForKey:@"saturation"]) {
            f.saturation = [[attributes objectForKey:@"saturation"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Contrast"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageContrastFilter *f = [[GPUImageContrastFilter alloc] init];
       
        if ([attributes objectForKey:@"contrast"]) {
            f.contrast = [[attributes objectForKey:@"contrast"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Brightness"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageBrightnessFilter *f = [[GPUImageBrightnessFilter alloc] init];
        
        if ([attributes objectForKey:@"brightness"]) {
            f.brightness = [[attributes objectForKey:@"brightness"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Exposure"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageExposureFilter *f = [[GPUImageExposureFilter alloc] init];
        
        if ([attributes objectForKey:@"exposure"]) {
            f.exposure = [[attributes objectForKey:@"exposure"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"WhiteBalance"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageWhiteBalanceFilter *f = [[GPUImageWhiteBalanceFilter alloc] init];
       
        if ([attributes objectForKey:@"temperature"]) {
            f.temperature = (int)[[attributes objectForKey:@"temperature"] integerValue];
        }
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Tone Curve"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageToneCurveFilter *f = [[GPUImageToneCurveFilter alloc] init];

        if ([attributes objectForKey:@"value"]) {
            [f setBlueControlPoints:@[ [NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)],
                                       [NSValue valueWithCGPoint:CGPointMake(0.5, [[attributes objectForKey:@"value"] floatValue])],
                                       [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)] ] ];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Luminance Threshold"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageLuminanceThresholdFilter *f = [[GPUImageLuminanceThresholdFilter alloc] init];
        
        if ([attributes objectForKey:@"threshold"]) {
            f.threshold = [[attributes objectForKey:@"threshold"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Grayscale"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageGrayscaleFilter *f = [[GPUImageGrayscaleFilter alloc] init];
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Color Invert"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageColorInvertFilter *f = [[GPUImageColorInvertFilter alloc] init];
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Low Pass"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageLowPassFilter *f = [[GPUImageLowPassFilter alloc] init];
        
        if ([attributes objectForKey:@"filterStrength"]) {
           f.filterStrength = [[attributes objectForKey:@"filterStrength"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Sketch"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        GPUImageSketchFilter *f = [[GPUImageSketchFilter alloc] init];
        
        if ([attributes objectForKey:@"edgeStrength"]) {
            f.edgeStrength = [[attributes objectForKey:@"edgeStrength"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Posterize"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImagePosterizeFilter *f = [[GPUImagePosterizeFilter alloc] init];
        
        if ([attributes objectForKey:@"colorLevels"]) {
            f.colorLevels = [[attributes objectForKey:@"colorLevels"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Emboss"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageEmbossFilter *f = [[GPUImageEmbossFilter alloc] init];
        
        if ([attributes objectForKey:@"intensity"]) {
            f.intensity = [[attributes objectForKey:@"intensity"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Vignette"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageVignetteFilter *f = [[GPUImageVignetteFilter alloc] init];
        
        if ([attributes objectForKey:@"vignetteEnd"]) {
            f.vignetteEnd = [[attributes objectForKey:@"vignetteEnd"] floatValue];
        }
        
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Stretch"]) {
        GPUImagePicture *source = [[GPUImagePicture alloc] initWithImage:image];
        
        GPUImageStretchDistortionFilter *f = [[GPUImageStretchDistortionFilter alloc] init];
        f.center = CGPointMake(0.5f, 0.5f);
        [source addTarget:f];
        [source processImage];
        outputImage = [f imageFromCurrentlyProcessedOutput];
    } else if ([name isEqualToString:@"Noir"]) {
        outputImage = [self filterCIImage:image.CGImage withEffect:@"CIPhotoEffectNoir"];
    } else if ([name isEqualToString:@"Chrome"]) {
        outputImage = [self filterCIImage:image.CGImage withEffect:@"CIPhotoEffectChrome"];
    } else if ([name isEqualToString:@"Fade"]) {
        outputImage = [self filterCIImage:image.CGImage withEffect:@"CIPhotoEffectFade"];
    } else if ([name isEqualToString:@"Instant"]) {
        outputImage = [self filterCIImage:image.CGImage withEffect:@"CIPhotoEffectInstant"];
    } else if ([name isEqualToString:@"Process"]) {
        outputImage = [self filterCIImage:image.CGImage withEffect:@"CIPhotoEffectProcess"];
    } else if ([name isEqualToString:@"Tonal"]) {
        outputImage = [self filterCIImage:image.CGImage withEffect:@"CIPhotoEffectTonal"];
    } else if ([name isEqualToString:@"Transfer"]) {
        outputImage = [self filterCIImage:image.CGImage withEffect:@"CIPhotoEffectTransfer"];
    }
    
    return outputImage;
}

-(UIImage *)filterCIImage:(CGImageRef )image withEffect:(NSString *)effect {
    CIFilter *filter = [CIFilter filterWithName:effect];
    CIImage *source = [CIImage imageWithCGImage:image];
    [filter setValue:source forKey:@"inputImage"];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
    UIImage *outputImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return outputImage;
}


@end
