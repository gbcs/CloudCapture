//
//  GPUVideoCompositor.m
//  Capture
//
//  Created by Gary Barnett on 12/3/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "GPUVideoCompositor.h"
#import "GPUVideoCompositionInstruction.h"
#import <CoreVideo/CoreVideo.h>
#import <GPUImage/GPUImage.h>

@interface GPUVideoCompositor () {
	BOOL								_shouldCancelAllRequests;
	BOOL								_renderContextDidChange;
	dispatch_queue_t					_renderingQueue;
	dispatch_queue_t					_renderContextQueue;
	AVVideoCompositionRenderContext*	_renderContext;
    CVPixelBufferRef					_previousBuffer;
    GPUImageRawDataInput *rawDataInput;
    GPUImageRawDataOutput *rawDataOutput;
  
}


@end

@implementation GPUVideoCompositor

#pragma mark - AVVideoCompositing protocol


-(void)dealloc {
        // //NSLog(@"%s", __func__);
}


- (id)initWithVideoComposition:(AVVideoComposition *)videoComposition
{
	self = [super init];
	if (self)
	{
		if (!videoComposition) {
			goto bail;
		}
        _renderContextDidChange = NO;
		
	}
	return self;
bail:
	return nil;
}

- (NSDictionary *)sourcePixelBufferAttributes
{
	return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
			  (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
	return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
			  (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext
{
    [self setupQueues];
	dispatch_sync(_renderContextQueue, ^() {
		_renderContext = newRenderContext;
		_renderContextDidChange = YES;
	});
}

-(void)setupQueues {
    if (!_renderingQueue) {
        _renderingQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.renderingqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.rendercontextqueue", DISPATCH_QUEUE_SERIAL);
        _previousBuffer = nil;
    }
    
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
    [self setupQueues];
	@autoreleasepool {
		dispatch_async(_renderingQueue,^() {
			
                // Check if all pending requests have been cancelled
			if (_shouldCancelAllRequests) {
				[request finishCancelledRequest];
			} else {
				NSError *err = nil;
                    // Get the next rendererd pixel buffer
				CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:request error:&err];
				
				if (resultPixels) {
					[request finishWithComposedVideoFrame:resultPixels];
					CFRelease(resultPixels);
				} else {
					[request finishWithError:err];
				}
			}
		});
	}
}

- (void)cancelAllPendingVideoCompositionRequests
{
        // pending requests will call finishCancelledRequest, those already rendering will call finishWithComposedVideoFrame
	_shouldCancelAllRequests = YES;
	[self setupQueues];
	dispatch_barrier_async(_renderingQueue, ^() {
            // start accepting requests again
		_shouldCancelAllRequests = NO;
	});
}

#pragma mark - Utilities

static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
	CMTime elapsed = CMTimeSubtract(time, range.start);
	return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}

- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    
    
    dispatch_semaphore_t render_sema = dispatch_semaphore_create(0);
    
	CVPixelBufferRef dstPixels = nil;
	
    GPUVIdeoCompositionInstruction *currentInstruction = request.videoCompositionInstruction;
    NSLog(@"render:%@:%@", request, currentInstruction);
    
    CMPersistentTrackID trackID = [[request.sourceTrackIDs objectAtIndex:0] intValue];
	
    CVPixelBufferRef pixelBuffer = [request sourceFrameByTrackID:trackID];
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    
	NSInteger bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
	NSInteger bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	GLubyte *pixel = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    
    if (!rawDataInput) {
        rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:pixel size:CGSizeMake(bufferWidth,bufferHeight)];
        rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(bufferWidth,bufferHeight) resultsInBGRAFormat:YES];

        [rawDataOutput setNewFrameAvailableBlock:^{
            dispatch_semaphore_signal(render_sema);
        }];
        [rawDataInput addTarget:rawDataOutput];
    } else {
        [rawDataInput updateDataFromBytes:pixel size:CGSizeMake(bufferWidth, bufferHeight)];
    }
    
    [rawDataInput processData];
    
    if ( 1 == 1) {
            //rebuild filter chain
    }

    dispatch_semaphore_wait(render_sema, DISPATCH_TIME_FOREVER);

	dstPixels = [_renderContext newPixelBuffer];
    
    CVPixelBufferLockBaseAddress(dstPixels,0);
        // NSInteger dstBufferWidth = CVPixelBufferGetWidth(pixelBuffer);
        //NSInteger dstBufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	GLubyte *dstPixel = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
    GLuint size = (int)(bufferWidth * bufferHeight);
    memcpy( rawDataOutput.rawBytesForImage, dstPixel, size * 4 );
    CVPixelBufferUnlockBaseAddress(dstPixels, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	return dstPixels;
}

@end
