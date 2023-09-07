//
//  HistogramView.m
//  Capture
//
//  Created by Gary Barnett on 9/2/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "HistogramView.h"

@implementation HistogramView {
    unsigned int buffer[256];
    CGSize vidResolution;
    float perPixel;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}
-(void)dealloc {
    //NSLog(@"%s", __func__);
    
}
-(void)updateWithR:(vImagePixelCount *)r andG:(vImagePixelCount *)g andB:(vImagePixelCount *)b vidRes:(CGSize )vidRes {
    vidResolution = vidRes;
    
    float equal = (vidRes.width *vidRes.height) / 256.0f;
    perPixel = equal / 256.0f;
    
    for (int x=0;x<256;x++) {
        buffer[x] = (r[x] + g[x] + b[x]) / 3.0f;
    }
    
    [self performSelectorOnMainThread:@selector(updateHistogramDisplay) withObject:nil waitUntilDone:NO];
}

-(void)updateHistogramDisplay {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (perPixel <= 0.0f) {
        return;
    }
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(c, [UIColor colorWithWhite:1.0 alpha:1.0].CGColor);
  
    CGContextMoveToPoint(c, 0,255);

    for (int x=0;x<256;x++) {
        float h = ((float)buffer[x]) / perPixel;
            //NSLog(@"%f", h);
        CGContextAddLineToPoint(c,x, 255 - h);
     
    }
   

    CGContextAddLineToPoint(c,255,255);
    CGContextAddLineToPoint(c,0,255);
   
    CGContextFillPath(c);
            
}

@end
