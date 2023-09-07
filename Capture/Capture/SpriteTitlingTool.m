//
//  SpriteTitlingTool.m
//  Capture
//
//  Created by Gary Barnett on 1/23/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "SpriteTitlingTool.h"

@implementation SpriteTitlingTool {
    UIView *view;
    __weak NSObject <SpriteTitlingImageDelegate> *delegate;
}

-(void)setupWithDict:(NSDictionary *)instructions {
    if (!view) {
       
    }
   
}

-(void)recordToPath:(NSString *)moviePath forLength:(NSInteger)seconds {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:5.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(frameReadyCallback:)];
            _displayLink.frameInterval = 30;
            [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_displayLink setPaused:NO];
        });
    });;
	
    
    
    
}

- (void)frameReadyCallback:(CADisplayLink *)sender
{
    

	/*
	 The callback gets called once every Vsync.
	 Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
	 This pixel buffer can then be processed and later rendered on screen.
	 */
	
	// Calculate the nextVsync time which is when the screen will be refreshed next.
	CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
    NSLog(@"DisplayLink:%@", @(nextVSync));
    
    CGFloat scale = 1.0f;
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spriteFrame" object:viewImage];
    
}


- (BOOL)shouldAutorotate
{
    return YES;
}

-(void)presentInView:(UIView *)v {
    [v addSubview:view];
}

-(void)imageDelegate:(NSObject <SpriteTitlingImageDelegate> *)d {
    delegate = d;
}

-(void)cleanup {
    delegate = nil;
    [view removeFromSuperview];
    view = nil;
 
}


@end
