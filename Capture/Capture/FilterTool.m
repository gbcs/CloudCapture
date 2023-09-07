//
//  FilterTool.m
//  Capture
//
//  Created by Gary Barnett on 9/2/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "FilterTool.h"
#import "ColorSpaceUtilities.h"
#import "TitleFrameView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
#import "UIColor-HSVAdditions.h"
#import "AppDelegate.h"

@implementation FilterTool {
    CIFilter *colorControls;
    CIFilter *remotePreview;
    CIFilter *titling;
    CIImage *chromaKeyImage;
    CIFilter *chromaKeyCube;
    CIFilter *chromaKeySOComposite;
    CIImage *titleImageBegin;
    CIImage *titleImageEnd;
    CIFilter *titleFilter;
    CIImage *matteImage;
    CIFilter *matteFilter;
    CIFilter *effectFilter;
    CIFilter *noiseFilter;
    
    BOOL bypassFilters;
    
    __weak NSObject <FilterToolHistogramDelegate> *histogramDelegate;
    __weak NSObject <FilterToolRemotePreviewDelegate> *remotePreviewDelegate;
    
    CGAffineTransform transformForRemotePreview;
    BOOL regenTitleBegin;
    BOOL regenTitleEnd;
    NSData *updatedChromaKeyCubeData;
    BOOL observersAdded;
    BOOL computingCube;
    BOOL computeCubeAgain;
    BOOL stillRequested;
    BOOL stillInProgress;
    BOOL updateWatermarkImage;
    CIImage *updatedWatermarkImage;
    NSDateFormatter *dateFormatter;

}

-(void)setHistogramDelegate:(NSObject <FilterToolHistogramDelegate> *)delegate {
    histogramDelegate = delegate;
}

-(void)setRemotePreviewDelegate:(NSObject <FilterToolRemotePreviewDelegate> *)delegate {
    remotePreviewDelegate = delegate;
}

-(CIImage *)filterImageWithSourceImage:(CIImage *)sourceImage withContext:(CIContext *)context {
    CIImage *outputImage = sourceImage;
    
    if (updatedChromaKeyCubeData) {
        [chromaKeyCube setValue:updatedChromaKeyCubeData forKey:@"inputCubeData"];
        updatedChromaKeyCubeData = nil;
        if (computeCubeAgain) {
            computeCubeAgain = NO;
            [self performSelectorInBackground:@selector(computeChromaKeyCube) withObject:nil];
        }
    }
    
    if (!bypassFilters) {
        
        if (updateWatermarkImage) {
            updateWatermarkImage = NO;
            matteImage = updatedWatermarkImage;
            [matteFilter setValue:matteImage forKey:@"inputBackgroundImage"];
            updatedWatermarkImage = nil;
        }

        if (chromaKeySOComposite) {
            [chromaKeyCube setValue:outputImage forKey:@"inputImage"];
            outputImage = chromaKeyCube.outputImage;
            
            [chromaKeySOComposite setValue:outputImage forKey:@"inputImage"];
            outputImage = chromaKeySOComposite.outputImage;
        }
        
        if (colorControls) {
            [colorControls setValue:outputImage forKey:@"inputImage"];
            outputImage = colorControls.outputImage;
        }
      
        if (effectFilter) {
            [effectFilter setValue:outputImage forKey:@"inputImage"];
            outputImage = effectFilter.outputImage;
        }
        
        if (noiseFilter) {
            [noiseFilter setValue:outputImage forKey:@"inputImage"];
            outputImage = noiseFilter.outputImage;
        }
        
        if (matteFilter) {
            [matteFilter setValue:outputImage forKey:@"inputImage"];
            outputImage = matteFilter.outputImage;
        }
        
        if (regenTitleBegin) {
            titleImageBegin = [self imageForTitleBegin];
            regenTitleBegin = NO;
        } else if (regenTitleEnd) {
            titleImageEnd = [self imageForTitleEnd];
            regenTitleEnd = NO;
        }
        
        if (titleFilter && [[SettingsTool settings] titleFilterBeginActive] && titleImageBegin) {
            [titleFilter setValue:titleImageBegin forKey:@"inputImage"];
            [titleFilter setValue:outputImage forKey:@"inputBackgroundImage"];
            outputImage = titleFilter.outputImage;
        } else if (titleFilter && [[SettingsTool settings] titleFilterEndActive] && titleImageEnd) {
            [titleFilter setValue:titleImageEnd forKey:@"inputImage"];
            [titleFilter setValue:outputImage forKey:@"inputBackgroundImage"];
            outputImage = titleFilter.outputImage;
        }
        if ( ([[SettingsTool settings] engineRemote] && remotePreviewDelegate && [remotePreviewDelegate isReadyForRemotePreviewImage]) ||
             ([[SettingsTool settings] engineHistogram] && histogramDelegate && [histogramDelegate isReadyForImage]) ) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                CIImage *previewImage = [outputImage imageByApplyingTransform:transformForRemotePreview];
                CGImageRef previewCGImage = [context createCGImage:previewImage fromRect:CGRectMake(0,0,kPreviewDataWidth, kPreviewDataHeight)];
               
                if ([[SettingsTool settings] engineRemote] && remotePreviewDelegate && [remotePreviewDelegate isReadyForRemotePreviewImage]) {
                    NSData *i = UIImageJPEGRepresentation([UIImage imageWithCGImage:previewCGImage], 0.3);
                    [remotePreviewDelegate didGenerateRemotePreview:i];
                }
                
                if ([[SettingsTool settings] engineHistogram] && histogramDelegate && [histogramDelegate isReadyForImage]) {
                    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithCGImage:previewCGImage];
                    
                    GPUImageHistogramFilter *hf = [[GPUImageHistogramFilter alloc] initWithHistogramType:(int)[[SettingsTool settings] engineHistogramType]];
               
                    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
                    [picture addTarget:gammaFilter];
                    [gammaFilter addTarget:hf];
                    
                    GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
                    [hf addTarget:histogramGraph];
                    [histogramGraph forceProcessingAtSize:CGSizeMake(256.0, 100.0)];
                    
                    GPUImageGammaFilter *gammaFilter2 = [[GPUImageGammaFilter alloc] init];
                    [histogramGraph addTarget:gammaFilter2];
   
                    [histogramDelegate didGenerateHistogram:gammaFilter2 withPicture:picture];
                }
                
                CGImageRelease(previewCGImage);
            });
        }

        if (stillRequested && (!stillInProgress)) {
            stillInProgress = YES;
            stillRequested = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"flashScreenForStill" object:nil];
            });
            
            NSInteger outputResolution = [[SettingsTool settings] captureOutputResolution];
            
            CGSize frameSize = [self sizeForFrameHeight:outputResolution];
            
            CGImageRef stillCGImage = [context createCGImage:outputImage fromRect:CGRectMake(0,0,frameSize.width, frameSize.height)];
            [self performSelectorInBackground:@selector(handleStill:) withObject:CFBridgingRelease(stillCGImage)];
        }
    }
    
    return outputImage;
}

typedef struct {
    CGFloat h;
    CGFloat s;
    CGFloat v;
} COLOR_HSV;

typedef struct {
    CGFloat r;
    CGFloat g;
    CGFloat b;
} COLOR_RGB;

typedef struct {
    CGFloat r;
    CGFloat g;
    CGFloat b;
    CGFloat a;
} COLOR_RGBA;

- (CGFloat)maxValueInArray:(NSArray *)arr withIndex:(NSInteger *)outIndex {
    CGFloat max = -1;
    if ([arr count] > 0) {
        max = [[arr objectAtIndex:0] floatValue];
        for (NSInteger i=0; i<[arr count]; i++) {
            if ([[arr objectAtIndex:i] floatValue] > max) {
                max = [[arr objectAtIndex:i] floatValue];
                if (outIndex != NULL) {
                    *outIndex = i;
                }
            }
        }
    }
    return max;
}
- (CGFloat)minValueInArray:(NSArray *)arr withIndex:(NSInteger *)outIndex {
    CGFloat min = -MAXFLOAT;
    if ([arr count] > 0) {
        min = [[arr objectAtIndex:0] floatValue];
        for (NSInteger i=0; i<[arr count]; i++) {
            if ([[arr objectAtIndex:i] floatValue] < min) {
                min = [[arr objectAtIndex:i] floatValue];
                if (outIndex != NULL) {
                    *outIndex = i;
                }
            }
        }
    }
    return min;
}


-(CGSize )sizeForFrameHeight:(NSInteger)height {
    CGSize frameSize = CGSizeZero;
    
    switch (height) {
        case 1080:
            frameSize = CGSizeMake(1920,1080);
            break;
        case 720:
            frameSize = CGSizeMake(1280,720);
            break;
        case 576:
            frameSize = CGSizeMake(1024,576);
            break;
        case 540:
            frameSize = CGSizeMake(960,540);
            break;
        case 480:
            frameSize = CGSizeMake(854,480);
            break;
        case 360:
            frameSize = CGSizeMake(640,360);
            break;
    }

    return frameSize;
}

-(CGFloat)hueForColorwithR:(CGFloat)r G:(CGFloat)g B:(CGFloat)b {
    float rgb[3], hsv[3];

    rgb[0] = r;
    rgb[1] = g;
    rgb[2] = b;
    
    rgbToHSV(rgb, hsv);
    
    return hsv[0];
}


void rgbToHSV(float rgb[3], float hsv[3])
{
    float min, max, delta;
    float r = rgb[0], g = rgb[1], b = rgb[2];
        //float *h = hsv[0], *s = hsv[1], *v = hsv[2];
    
    min = MIN( r, MIN( g, b ));
    max = MAX( r, MAX( g, b ));
    hsv[2] = max;               // v
    delta = max - min;
    if( max != 0 )
        hsv[1] = delta / max;       // s
    else {
            // r = g = b = 0        // s = 0, v is undefined
        hsv[1] = 0;
        hsv[0] = -1;
        return;
    }
    if( r == max )
        hsv[0] = ( g - b ) / delta;     // between yellow & magenta
    else if( g == max )
        hsv[0] = 2 + ( b - r ) / delta; // between cyan & yellow
    else
        hsv[0] = 4 + ( r - g ) / delta; // between magenta & cyan
    hsv[0] *= 60;               // degrees
    if( hsv[0] < 0 )
        hsv[0] += 360;
    hsv[0] /= 360.0;
}

void hsvToRGB(float hsv[3], float rgb[3])
{
    float C = hsv[2] * hsv[1];
    float HS = hsv[0] * 6.0;
    float X = C * (1.0 - fabsf(fmodf(HS, 2.0) - 1.0));
    
    if (HS >= 0 && HS < 1)
    {
        rgb[0] = C;
        rgb[1] = X;
        rgb[2] = 0;
    }
    else if (HS >= 1 && HS < 2)
    {
        rgb[0] = X;
        rgb[1] = C;
        rgb[2] = 0;
    }
    else if (HS >= 2 && HS < 3)
    {
        rgb[0] = 0;
        rgb[1] = C;
        rgb[2] = X;
    }
    else if (HS >= 3 && HS < 4)
    {
        rgb[0] = 0;
        rgb[1] = X;
        rgb[2] = C;
    }
    else if (HS >= 4 && HS < 5)
    {
        rgb[0] = X;
        rgb[1] = 0;
        rgb[2] = C;
    }
    else if (HS >= 5 && HS < 6)
    {
        rgb[0] = C;
        rgb[1] = 0;
        rgb[2] = X;
    }
    else {
        rgb[0] = 0.0;
        rgb[1] = 0.0;
        rgb[2] = 0.0;
    }
    
    
    float m = hsv[2] - C;
    rgb[0] += m;
    rgb[1] += m;
    rgb[2] += m;
}



-(void)computeChromaKeyCube {
    computingCube = YES;
  
    NSArray *vals = [[SettingsTool settings] engineChromaKeyValues];
    
    float minHueAngle = [vals[0] floatValue];
    float maxHueAngle = [vals[1] floatValue];
    
        // NSLog(@"computeChromaKeyCube:%f:%f", minHueAngle, maxHueAngle);
    float centerHueAngle = minHueAngle + (maxHueAngle - minHueAngle)/2.0;
    float destCenterHueAngle = 1.0/3.0;
    
    const unsigned int size = 64;
    size_t cubeDataSize = size * size * size * sizeof ( float ) * 4;
    float *cubeData = (float *) malloc ( cubeDataSize );
    float rgb[3], hsv[3], newRGB[3];
    
    size_t offset = 0;
    for (int z = 0; z < size; z++)
    {
        rgb[2] = ((double) z) / size; // blue value
        for (int y = 0; y < size; y++)
        {
            rgb[1] = ((double) y) / size; // green value
            for (int x = 0; x < size; x++)
            {
                rgb[0] = ((double) x) / size; // red value
                rgbToHSV(rgb, hsv);
                
                float alpha = 1.0;
                
                if (hsv[0] < minHueAngle || hsv[0] > maxHueAngle)
                    memcpy(newRGB, rgb, sizeof(newRGB));
                else
                {
                    hsv[0] = destCenterHueAngle + (centerHueAngle - hsv[0]);
                    hsvToRGB(hsv, newRGB);
                    alpha = 0.0;
                }
                
                cubeData[offset]   = newRGB[0] * alpha;
                cubeData[offset+1] = newRGB[1] * alpha;
                cubeData[offset+2] = newRGB[2] * alpha;
                cubeData[offset+3] = alpha;
                
                offset += 4;
            }
        }
    }
    
    updatedChromaKeyCubeData= [NSData dataWithBytesNoCopy:cubeData length:cubeDataSize freeWhenDone:YES];
    
    computingCube = NO;
    
}

-(void)chromaKeyValuesChanged:(NSNotification *)n {
    if (computingCube && updatedChromaKeyCubeData) {
        computeCubeAgain = YES;
    } else {
         [self performSelectorInBackground:@selector(computeChromaKeyCube) withObject:nil];
    }
}

-(void)handleVideoStillImageRequest:(NSNotification *)n {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        stillRequested = YES;
    }
}


-(void)rebuildFilterInfo:(NSInteger)diskRes {
    //NSLog(@"Rebuild: diskRes:%ld", (long)diskRes);
    bypassFilters = YES;
    if (!observersAdded) {
        observersAdded = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chromaKeyValuesChanged:) name:@"chromaKeyValuesChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleVideoStillImageRequest:) name:@"handleVideoStillImageRequest" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHistogramDelegate:) name:@"handleHistogramDelegate" object:nil];

    }
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ssZ"];
    }
    
    
    BOOL flipFilters = [[SettingsTool settings] cameraFlipEnabled];
    
    
    chromaKeySOComposite = nil;
    chromaKeyImage = nil;
    chromaKeyCube = nil;

    colorControls = nil;
    effectFilter = nil;
    matteFilter = nil;
    titleFilter = nil;
    
    
    if ([[SettingsTool settings] advancedFiltersAvailable]) {
        if ([[SettingsTool settings] engineHistogram]) {
            bypassFilters = NO;
        }         
        
        BOOL cameraNeedsHorizontalFlip = ![[SettingsTool settings] cameraIsBack];
        if (flipFilters) {
            cameraNeedsHorizontalFlip = !cameraNeedsHorizontalFlip;
        }
        if ([[SettingsTool settings] engineChromaKey]) {
            bypassFilters = NO;
           int size = 64;
            
            [self computeChromaKeyCube];
            
                //NSLog(@"CubeDataSize:%lu", (unsigned long)[updatedChromaKeyCubeData length]);
            chromaKeyCube = [CIFilter filterWithName:@"CIColorCube"];
            [chromaKeyCube setValue:[NSNumber numberWithInt:size] forKey:@"inputCubeDimension"];
            [chromaKeyCube setValue:updatedChromaKeyCubeData forKey:@"inputCubeData"];
            
            NSString *chromaKeyPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] stringByAppendingPathComponent:[[SettingsTool settings] chromaKeyImage]];
            UIImage *i = [UIImage imageWithContentsOfFile:chromaKeyPath];
            
            
            
            UIImage *screen = [[UtilityBag bag] imageByScalingAndCroppingForSize:[self sizeForFrameHeight:diskRes] usingImage:i rotated:flipFilters mirror:cameraNeedsHorizontalFlip];
            
            chromaKeyImage = [CIImage imageWithCGImage:screen.CGImage];
            
            chromaKeySOComposite = [CIFilter filterWithName:@"CISourceOverCompositing"];
            [chromaKeySOComposite setValue:chromaKeyImage forKey:@"inputBackgroundImage"];
        } else {
            chromaKeyImage = nil;
            chromaKeyCube = nil;
            chromaKeySOComposite = nil;
        }

        if ([[SettingsTool settings] engineColorControl] ) {
            bypassFilters = NO;
            colorControls = [CIFilter filterWithName:@"CIColorControls"];
        } else {
            colorControls = nil;
        }
        
        noiseFilter = nil;
        
        if ([[SettingsTool settings] engineImageEffect] ) {
            bypassFilters = NO;
          
            NSString *effectStr =[[SettingsTool settings] imageEffectStr];
            if ([effectStr isEqualToString:@"Noir"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
            } else if ([effectStr isEqualToString:@"Vignette"]) {
                effectFilter = [CIFilter filterWithName:@"CIVignette"];
            } else if ([effectStr isEqualToString:@"Chrome"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectChrome"];
            } else if ([effectStr isEqualToString:@"Fade"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectFade"];
            } else if ([effectStr isEqualToString:@"Instant"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
            } else if ([effectStr isEqualToString:@"Mono"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectMono"];
            } else if ([effectStr isEqualToString:@"Process"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectProcess"];
            } else if ([effectStr isEqualToString:@"Tonal"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectTonal"];
            } else if ([effectStr isEqualToString:@"Transfer"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectTransfer"];
            } else if ([effectStr isEqualToString:@"FaceDetect"]) {
                effectFilter = [CIFilter filterWithName:@"CIPhotoEffectTransfer"];
            } else {
                effectFilter = nil;
            }
  
            if (effectFilter) {
                [self updateImageEffectParameters:effectStr withDict:[[SettingsTool settings] imageEffectParameters:effectStr]];
            }
            
            if (effectFilter) {
                    // NSLog(@"%@: %@", [[SettingsTool settings] imageEffectStr], [effectFilter attributes]);
            }
        } else {
            effectFilter = nil;
        }
        
        if ( ([[SettingsTool settings] engineOverlay] && ([[[SettingsTool settings] engineOverlayType] integerValue] == 3)) && (![[SettingsTool settings] fastCaptureMode])) {
            NSInteger outputResolution = [[SettingsTool settings] captureOutputResolution];
  
            CGImageRef image = [self newWatermarkWithSize:[self sizeForFrameHeight:outputResolution] rotated:flipFilters mirrored:cameraNeedsHorizontalFlip];
            matteImage = [CIImage imageWithCGImage:image];
            CGImageRelease(image);
            
            matteFilter = [CIFilter filterWithName:@"CIMaximumCompositing"];
            [matteFilter setValue:matteImage forKey:@"inputBackgroundImage"];
            bypassFilters = NO;
        } else if ([[SettingsTool settings] engineOverlay] ) {
            CGSize frameSize = [self sizeForFrameHeight:diskRes];
            
            int len = (4 * frameSize.width * frameSize.height);
            
            unsigned char *buffer = malloc(len);

            NSInteger matteVal = [[[SettingsTool settings] engineOverlayType] integerValue];
            CGFloat matteAdjust = 2.20;
            if (matteVal == 1) {
                matteAdjust = 2.35;
            } else if (matteVal == 2) {
                matteAdjust = 2.40;
            }
            
            CGFloat matteAmount = 0;
            
            
            matteAmount = frameSize.height - (frameSize.width / (matteAdjust / 1.0f));
            
            CGFloat matteHeight = matteAmount / 2.0f;
            
            CGFloat topMatteEnds = matteHeight;
            
            CGFloat bottomMattteBegins = frameSize.height - matteHeight;
            
            for (int y=0;y<frameSize.height;y++) {
                BOOL allowVideo = YES;
                
                if (y < topMatteEnds) {
                    allowVideo = NO;
                } else if (y >= bottomMattteBegins) {
                    allowVideo = NO;
                }
                
                for (int x=0;x<frameSize.width;x++) {
                    int xPos = x * 4;
                    int bufPos = xPos + (y * frameSize.width * 4);
                    if (allowVideo) {
                        buffer[bufPos] = 255;
                        buffer[bufPos+1] = 255;
                        buffer[bufPos+2] = 255;
                        buffer[bufPos+3] = 255;
                    } else {
                        buffer[bufPos] = 0;
                        buffer[bufPos+1] = 0;
                        buffer[bufPos+2] = 0;
                        buffer[bufPos+3] = 255;
                    }
                }
            }
            
            
            NSData *d = [[NSMutableData alloc] initWithBytes:buffer length:len];
            
            free(buffer);
            
            matteImage = [CIImage imageWithBitmapData:d bytesPerRow:4 * frameSize.width size:frameSize format:kCIFormatRGBA8 colorSpace:nil];
            matteFilter = [CIFilter filterWithName:@"CIMinimumCompositing"];
            [matteFilter setValue:matteImage forKey:@"inputBackgroundImage"];
        } else {
            matteImage = nil;
            matteFilter = nil;
        }
        
        if ([[SettingsTool settings] engineTitling] ) {
            bypassFilters = NO;
            titleImageBegin = nil;
            titleImageEnd = nil;
            titleFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        } else {
            titleImageBegin = nil;
            titleImageEnd = nil;
            titleFilter = nil;
        }
        
        if ([[SettingsTool settings] engineRemote] || [[SettingsTool settings] engineHistogram] ) {
            bypassFilters = NO;
            
            if ([[SettingsTool settings] engineRemote]) {
                remotePreview  = [CIFilter filterWithName:@"CIColorMonochrome" keysAndValues:@"inputIntensity", [NSNumber numberWithFloat:1.0],
                                  @"inputColor", [[CIColor alloc] initWithColor:[UIColor whiteColor]], nil];
                [self setRemotePreviewDelegate:[RemoteAdvertiserManager manager]];
            }
            
            switch (diskRes) {
                case  1080:
                    transformForRemotePreview = CGAffineTransformMakeScale(kPreviewDataWidth / 1920.0f, kPreviewDataHeight / 1080.0f);
                    break;
                case  720:
                    transformForRemotePreview = CGAffineTransformMakeScale(kPreviewDataWidth / 1280.0f, kPreviewDataHeight / 720.0f);
                    break;
                case  576:
                    transformForRemotePreview = CGAffineTransformMakeScale(kPreviewDataWidth / 1280.0f, kPreviewDataHeight / 720.0f);
                    break;
                case  540:
                    transformForRemotePreview = CGAffineTransformMakeScale(kPreviewDataWidth / 960.0f, kPreviewDataHeight / 540.0f);
                    break;
                case  480:
                    transformForRemotePreview = CGAffineTransformMakeScale(kPreviewDataWidth / 960.0f, kPreviewDataHeight / 540.0f);
                    break;
                case  360:
                    transformForRemotePreview = CGAffineTransformMakeScale(kPreviewDataWidth / 960.0f, kPreviewDataHeight / 540.0f);
                    break;
            }
        } else {
            remotePreview = nil;
        }
    }
    

}

-(void)updateWatermark {
    if (updatedWatermarkImage) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
       NSInteger diskRes = [[SettingsTool settings] captureOutputResolution];
       BOOL flipFilters = [[SettingsTool settings] cameraFlipEnabled];
       BOOL cameraNeedsHorizontalFlip = ![[SettingsTool settings] cameraIsBack];
       if (flipFilters) {
           cameraNeedsHorizontalFlip = !cameraNeedsHorizontalFlip;
       }

    
        CGImageRef image = [self newWatermarkWithSize:[self sizeForFrameHeight:diskRes] rotated:flipFilters mirrored:cameraNeedsHorizontalFlip];
       
        updatedWatermarkImage = [CIImage imageWithCGImage:image];
        CGImageRelease(image);
       
       updateWatermarkImage = YES;
   });
}

-(void)updateImageEffectParameters:(NSString *)effectName withDict:(NSDictionary *)parameters {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultsKey = [NSString stringWithFormat:@"ifDict%@", effectName];
    
    NSDictionary *dict = [defaults objectForKey:defaultsKey];
    if (!dict) {
        dict = [[SettingsTool settings] imageEffectParameters:effectName];
    }
    
    NSMutableDictionary *mDict = [dict mutableCopy];
    
    for (NSString *key in [parameters allKeys]) {
        id val = [parameters objectForKey:key];
        [mDict setObject:val forKey:key];
        [effectFilter setValue:val forKey:key];
    }
 
    [defaults setObject:[mDict copy] forKey:defaultsKey];
    [defaults synchronize];

}


-(void)updateContrast:(float)val {
    [colorControls setValue:[NSNumber numberWithFloat:val] forKey:@"inputContrast"];
}

-(void)updateBrightness:(float)val {
    [colorControls setValue:[NSNumber numberWithFloat:val] forKey:@"inputBrightness"];
}

-(void)updateSaturation:(float)val {
    [colorControls setValue:[NSNumber numberWithFloat:val] forKey:@"inputSaturation"];
}

-(NSString *)fullPathForTitleWithName:(NSString *)name {
    return [[[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"titlingPages"] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"title"];
}

-(void)updateTitleForBegin {
    regenTitleBegin = YES;
   
}

-(void)updateTitleForEnd {
    regenTitleEnd = YES;
}

-(CIImage *)imageForTitleBegin {
    CIImage *image = nil;
    NSString *titleName =[[SettingsTool settings] engineTitlingBeginName];
    if (![titleName isEqualToString:@"None"]) {
        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithFile:[self fullPathForTitleWithName:titleName]];
        NSString *name = [dict objectForKey:@"bgImage"];
        NSString *picPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] stringByAppendingPathComponent:name];
        image = [self imageForTitleWithPath:picPath andDict:dict];
    }
    return image;
}

-(CIImage *)imageForTitleEnd {
    CIImage *image = nil;
    NSString *titleName =[[SettingsTool settings] engineTitlingEndName];
    if (![titleName isEqualToString:@"None"]) {
        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithFile:[self fullPathForTitleWithName:titleName]];
        NSString *name = [dict objectForKey:@"bgImage"];
        NSString *picPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] stringByAppendingPathComponent:name];
        image = [self imageForTitleWithPath:picPath andDict:dict];
    }
    return image;
}


-(CIImage *)imageForTitleWithPath:(NSString *)path andDict:(NSDictionary *)dict {
    
    NSInteger outputResolution = [[SettingsTool settings] captureOutputResolution];
    
    NSInteger inputResolution = 1080;
    if (outputResolution < 576) {
        inputResolution = 540;
    } else if (outputResolution < 900) {
        inputResolution = 720;
    }
    
    CGSize frameSize = [self sizeForFrameHeight:outputResolution];
    CGSize inputSize = [self sizeForFrameHeight:inputResolution];
    
    CGRect imageRect = CGRectInset(CGRectMake(0,0,inputSize.width, inputSize.height), (inputSize.width - frameSize.width) / 2.0f, (inputSize.height - frameSize.height) / 2.0f);
    
    __block CIImage *image = nil;
    
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:path];

    dispatch_sync(dispatch_get_main_queue(), ^{
        UIView *c = [[UIView alloc] initWithFrame:CGRectMake(0,0,inputSize.width, inputSize.height)];
        c.backgroundColor = [UIColor clearColor];
        TitleFrameView *v = [[TitleFrameView alloc] initWithFrame:imageRect];
        [c addSubview:v];
        v.bgImage = sourceImage;
        v.titleDict = dict;
        v.flip = [[SettingsTool settings] cameraFlipEnabled];
        BOOL horizFlip = ![[SettingsTool settings] cameraIsBack];
        if ([[SettingsTool settings] cameraFlipEnabled]) {
            horizFlip = !horizFlip;
        }
        v.horizFlip = horizFlip;
        [v updateWithSize:frameSize];
        
        UIGraphicsBeginImageContext(inputSize);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [c.layer renderInContext:context];
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        image = [CIImage imageWithCGImage:newImage.CGImage];
    });
    
    return image;
}


-(void)handleHistogramDelegate:(NSNotification *)n {
    NSObject <FilterToolHistogramDelegate> *delegate = (NSObject <FilterToolHistogramDelegate> *)n.object;
    histogramDelegate = delegate;
}


-(void)handleStill:(CGImageRef )image {
    
    UIImage *still = [UIImage imageWithCGImage:image];
    
    CGFloat xOffset = [[SettingsTool settings] framingGuideXOffset];
    NSInteger framingGuide = [[SettingsTool settings] framingGuide];
    CGSize guidePaneSize = [[SettingsTool settings] currentGuidePaneSize];
    
    if ((framingGuide >0) && [[SettingsTool settings] cropStillsToGuide]) {
        CGSize imageSize = [still size];
        
        CGFloat xWidth = imageSize.width / (4.0f / 3.0f);
        
        if (framingGuide == 2) {
            xWidth = imageSize.height;
        }
        
        CGFloat leftX = (imageSize.width - xWidth ) / 2.0f;
        
        if (xOffset != 0.0f) {
            CGFloat guideScaleFactor = imageSize.width / guidePaneSize.width;
            CGFloat imageXOffset = xOffset * guideScaleFactor;
            
            leftX += imageXOffset;
        }
        
        CGRect r = CGRectMake(leftX, 0, xWidth, imageSize.height);
        
        CGImageRef imageRef = CGImageCreateWithImageInRect(still.CGImage, r);
        still = [UIImage imageWithCGImage:imageRef scale:still.scale orientation:still.imageOrientation];
        CGImageRelease(imageRef);
            // NSLog(@"Cropped still from %@ to %@", [NSValue valueWithCGSize:imageSize], [NSValue valueWithCGSize:still.size]);
    }
    
    
    NSData *d = UIImagePNGRepresentation(still);

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache,
                             nil];
    
    
    CGImageSourceRef r = CGImageSourceCreateWithData((__bridge CFDataRef)(d), (__bridge CFDictionaryRef)options);
    
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(r, 0, (__bridge CFDictionaryRef)options);
   
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageDataToSavedPhotosAlbum:d metadata:(__bridge NSDictionary *)(imageProperties) completionBlock:^(NSURL *assetURL, NSError *error) {
         stillInProgress = NO;
        CFRelease(r);
    }];
}

-(CGImageRef )newWatermarkWithSize:(CGSize)size rotated:(BOOL)rotated mirrored:(BOOL)mirrored {
    CGFloat textHeight = 24.0f; //1080
    if (size.height < 576) {
        textHeight = 16.0f;
    } else if (size.height < 900) {
        textHeight = 20.0f;
    }
    
    NSString *rightSide = [dateFormatter stringFromDate:[NSDate date]];
    NSString *leftSide = @"";
    if ([[SettingsTool settings] useGPS] && [[SettingsTool settings] clipRecordLocation]) {
        CLLocation *location = [LocationHandler tool].location;
        leftSide = [NSString stringWithFormat:@"%+08.8lf, %+09.8lf", location.coordinate.latitude, location.coordinate.longitude];
    }
    
    UIFont *boldFont = [UIFont fontWithName:@"LiquidCrystal-Bold" size:textHeight];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowBlurRadius:3.0f];
    [shadow setShadowColor:[UIColor blackColor]];
    [shadow setShadowOffset:CGSizeMake(0, 2.0f)];
    NSDictionary *stdDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:boldFont,[UIColor whiteColor], shadow, nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, nil]];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentRight;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *stdDrawAttrbsR = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:boldFont,[UIColor whiteColor], shadow, paragraphStyle, nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, NSParagraphStyleAttributeName, nil]];


    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel    = 4;
    size_t bytesPerRow      = (size.width * bitsPerComponent * bytesPerPixel + 7) / 8;
    size_t dataSize         = bytesPerRow * size.height;
    
    unsigned char *data = malloc(dataSize);
    memset(data, 0, dataSize);
    
    CGContextRef context = CGBitmapContextCreate(data, size.width, size.height,
                                                 bitsPerComponent,
                                                 bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1);
    CGContextSetTextDrawingMode(context, kCGTextFill);

    UIGraphicsPushContext(context);
   
    CGFloat halfWidth = size.width / 2.0f;
    
    [leftSide drawInRect:CGRectMake(0,size.height - textHeight,halfWidth, textHeight) withAttributes:stdDrawAttrbs];
    [rightSide drawInRect:CGRectMake(halfWidth,size.height - textHeight,halfWidth, textHeight) withAttributes:stdDrawAttrbsR];
    
    CGColorSpaceRelease(colorSpace);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    UIGraphicsPopContext();
    CGContextRelease(context);
    free(data);

    if (rotated) {
        CGImageRef source = imageRef;
        imageRef = [self newCGImageRotatedByAngle:source angle:180];
        CGImageRelease(source);
    }
    
    if (mirrored) {
        CGImageRef source = imageRef;
        imageRef = [self newCGImageHorizontallyFlipped:imageRef];
        CGImageRelease(source);
    }

    return imageRef;
}

- (CGImageRef)newCGImageHorizontallyFlipped:(CGImageRef)imgRef
{
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeScale(-1,1);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGContextSetAllowsAntialiasing(bmContext, YES);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
	CGColorSpaceRelease(colorSpace);
	CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextScaleCTM(bmContext, -1, 1);
	CGContextDrawImage(bmContext, CGRectMake(-width/2, -height/2, width, height),
					   imgRef);
	
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	CFRelease(bmContext);
    
	return rotatedImage;
}

- (CGImageRef)newCGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle
{
	CGFloat angleInRadians = angle * (M_PI / 180);
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGContextSetAllowsAntialiasing(bmContext, YES);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
	CGColorSpaceRelease(colorSpace);
	CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextRotateCTM(bmContext, angleInRadians);
	CGContextDrawImage(bmContext, CGRectMake(-width/2, -height/2, width, height),
					   imgRef);
	
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	CFRelease(bmContext);

	return rotatedImage;
}


@end
