//
//  GPUMakeVideoFromImage.m
//  Capture
//
//  Created by Gary Barnett on 2/14/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "GPUMakeVideoFromImage.h"
#import <CoreImage/CoreImage.h>
#import <GLKit/GLKit.h>
#import <GPUImage/GPUImage.h>


@implementation GPUMakeVideoFromImage {
        NSString        *_path;
        AVAssetWriter *videoWriter;
        AVAssetWriterInput* writerInput;
        AVAssetWriterInputPixelBufferAdaptor *adaptor;
        CVPixelBufferRef buffer;
        NSUInteger currentIndex;
        UIImage *sourceImage;
        NSInteger duration;
        NSObject <GPUMakeVideoFromImageDelegate> *delegate;
        CIImage *sourceCIImage;

        CIContext *ciContext;
        FilterClipTool2 *filterTool;
    }
    
    - (id)init
    {
        self = [super init];
        if (self) {
            buffer = NULL;
            currentIndex = 0;
            filterTool = [[FilterClipTool2 alloc] init];
        }
        return self;
    }
    
    
    -(void)cancel {
        buffer = NULL;
        currentIndex = 0;
    }
    
    -(void)dealloc {
        _path = nil;
        videoWriter = nil;
        writerInput = nil;
        adaptor = nil;
        buffer = nil;
        sourceImage = nil;
        delegate = nil;
        filterTool = nil;
    }
    
    
    -(void)startVideoCaptureOfDuration:(NSInteger)seconds usingImage:(UIImage *)image usingPath:(NSString *)path andDelegate:(NSObject<GPUMakeVideoFromImageDelegate> *)d startRect:(CGRect)startRect endRect:(CGRect)endRect {
        [self cancel];
        delegate = d;
        _path = path;
        sourceImage = image;
        sourceCIImage = [CIImage imageWithCGImage:image.CGImage];
        duration = seconds * 24;
        
        CGFloat steps = duration -1;
        
        ciContext = [CIContext contextWithOptions:nil];
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *error = nil;
            videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_path] fileType:AVFileTypeQuickTimeMovie error:&error];
            
            CGSize frameSize = CGSizeMake([[SettingsTool settings] isOldDevice] ? 1280 : 1920, [[SettingsTool settings] isOldDevice] ? 720 : 1080);
            
            NSDictionary *videoSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           AVVideoCodecH264, AVVideoCodecKey,
                                           [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                           [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                           nil];
            
            writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
            
            
            NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
                                              [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                              [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                              nil];
            
            adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:bufferAttributes];
            
            [videoWriter addInput:writerInput];
            
            [videoWriter startWriting];
            [videoWriter startSessionAtSourceTime:kCMTimeZero];
            
            CGRect r = startRect;
            
            CGFloat xDelta = r.origin.x - endRect.origin.x;
            CGFloat yDelta = r.origin.y - endRect.origin.y;
            CGFloat xSizeChange = r.size.width - endRect.size.width;
            CGFloat ySizeChange = r.size.height - endRect.size.height;
            
            xDelta = xDelta / steps;
            yDelta = yDelta / steps;
            xSizeChange = xSizeChange / steps;
            ySizeChange = ySizeChange / steps;
            
            CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
            
            NSInteger frame = -1;
            
            while (frame < duration) {
                while ((adaptor.assetWriterInput.readyForMoreMediaData)==NO ) {
                    
                }
                frame++;
   
                CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
                
                CVPixelBufferLockBaseAddress(buffer, 0);
                
               
               // [filterTool filterPixelBuffer:buffer usingImage:sourceImage.CGImage croppedToRect:r frameSize:frameSize];
                
                CVPixelBufferUnlockBaseAddress(buffer,0);
                
                if (!buffer) {
                    NSLog(@"no buffer after pixelBufferFromCGImage");
                    continue;
                }
                
                [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,24)];
                CVPixelBufferRelease(buffer);
                
                r = CGRectMake(r.origin.x - xDelta, r.origin.y - yDelta, r.size.width - xSizeChange, r.size.height - ySizeChange);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"makePhotoVideoProgress" object:@((float)frame / (float)duration)];
            }
            
            CGColorSpaceRelease(rgbColorSpace);
            
            [writerInput markAsFinished];
            
            if (!videoWriter) {
                [delegate makeVideoComplete:NO withPath:_path];
                [self cancel];
            } else {
                [videoWriter finishWritingWithCompletionHandler:^{
                    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [delegate makeVideoComplete:YES withPath:_path];
                        [self cancel];
                    });
                    
                }];
            }
            ciContext = nil;
        });
    }
@end
