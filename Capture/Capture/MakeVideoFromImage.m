//
//  MakeVideoFromImage.m
//  Capture
//
//  Created by Gary Barnett on 12/30/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "MakeVideoFromImage.h"

@implementation MakeVideoFromImage {
    NSString        *_path;
    AVAssetWriter *videoWriter;
    AVAssetWriterInput* writerInput;
    AVAssetWriterInputPixelBufferAdaptor *adaptor;
    CVPixelBufferRef buffer;
    NSUInteger currentIndex;
    UIImage *sourceImage;
    NSInteger duration;
    NSObject <MakeVideoFromImageDelegate> *delegate;
}

- (id)init
{
    self = [super init];
    if (self) {
        buffer = NULL;
        currentIndex = 0;
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
}


-(void)startVideoCaptureOfDuration:(NSInteger)seconds usingImage:(UIImage *)image usingPath:(NSString *)path andDelegate:(NSObject<MakeVideoFromImageDelegate> *)d startRect:(CGRect)startRect endRect:(CGRect)endRect {
    [self cancel];
    delegate = d;
    _path = path;
    sourceImage = image;
    duration = seconds * 24;
    CGFloat steps = duration -1;
   
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error = nil;
        videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_path] fileType:AVFileTypeQuickTimeMovie error:&error];
        
        NSDictionary *videoSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSNumber numberWithInt:[[SettingsTool settings] isOldDevice] ? 1280 : 1920], AVVideoWidthKey,
                                       [NSNumber numberWithInt:[[SettingsTool settings] isOldDevice] ? 720 : 1080], AVVideoHeightKey,
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
            void *pxdata = CVPixelBufferGetBaseAddress(buffer);
            
            CGFloat width =[[SettingsTool settings] isOldDevice] ? 1280 : 1920;
            CGFloat height =[[SettingsTool settings] isOldDevice] ? 720 : 1080;
            
            CGContextRef context = CGBitmapContextCreate(pxdata, width, height,
                                                         8,
                                                         4*width,
                                                         rgbColorSpace,
                                                         (CGBitmapInfo)kCGImageAlphaPremultipliedFirst
                                                         );

            CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
            //NSLog(@"photoFrame: image_size:%lf, %lf rect:%@", sourceImage.size.width, sourceImage.size.height, [NSValue valueWithCGRect:r]);
            
                //CGRect r = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
            
                //r = CGRectInset(r, 250, 250);
            
            CGImageRef croppedImage = CGImageCreateWithImageInRect(sourceImage.CGImage, r);
            
            CGContextDrawImage(context, CGRectMake(0,0,width, height), croppedImage);
            CGContextRelease(context);
            CGImageRelease(croppedImage);
            CVPixelBufferUnlockBaseAddress(buffer, 0);
            
                    
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
    });
}

@end
