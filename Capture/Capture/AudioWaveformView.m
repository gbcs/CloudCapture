//
//  AudioWaveformView.m
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioWaveformView.h"

@implementation AudioWaveformView {
    BOOL ready;
    CGMutablePathRef path;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

//Given a width and height and a set of values, compose a nice waveform view

-(void)cleanup {
    if (path) {
        CGPathRelease(path);
        path = nil;
    }
    _entryList = nil;
}

-(void)update {
    ready = NO;
    
    CGMutablePathRef p = CGPathCreateMutable();
    CGMutablePathRef p2 = CGPathCreateMutable();
    
    NSInteger index = 0;
    CGPathMoveToPoint(p, NULL, 0,24);
    CGPathMoveToPoint(p2, NULL, 0,24);
    CGAffineTransform xf = CGAffineTransformIdentity;
    
    CGFloat l = 0.0f;
    CGFloat factor = 24.0f / 128.0f;
    
    for (NSArray *sample in self.entryList) {
        l = [sample[0] floatValue];
        CGPathAddLineToPoint(p, &xf, index, 24 + (l * factor));
        CGPathAddLineToPoint(p2, &xf, index, 24 - (l * factor));
        index++;
    }

    if (path) {
        CFRelease(path);
    }
    
    
    
    CGPathAddLineToPoint(p, &xf, index, 24);
    CGPathAddLineToPoint(p2, &xf, index, 24);

   
    path = CGPathCreateMutable();
  
    CGPathAddPath(path, NULL, p);
    CGPathAddPath(path, NULL, p2);
   
    CGPathRelease( p );
    CGPathRelease( p2 );
    
    self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, index, self.bounds.size.height);
    
    ready = YES;
}



- (void)drawRect:(CGRect)rect
{
    if (ready) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.6 alpha:1.0].CGColor);
            //CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.8 alpha:1.0].CGColor);
            // CGContextSetLineWidth(context, 1.0f);
        CGContextMoveToPoint(context, 0,0);
        CGContextAddPath(context, path);
            //CGContextStrokePath(context);
        CGContextFillPath(context);
        
        
    }
}



@end
