//
//  ExposureReticleView.m
//  Capture
//
//  Created by Gary Barnett on 7/21/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ExposureReticleView.h"

@implementation ExposureReticleView {
    UILabel *l;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self update];
    }
    return self;
}
-(void)dealloc {
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }

    l = nil;
}

-(void)update {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    float lineWidth = 2.0f;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, CGRectMake(0,0,50,50));
    CGContextSetShadowWithColor(context, CGSizeMake(0,1.0), 0.0, [UIColor blackColor].CGColor);
    
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite:0.7 alpha:0.7] CGColor]);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.7 alpha:0.7] CGColor]);
    CGContextSetLineWidth(context, lineWidth);
    
    CGRect circlePoint1 = CGRectMake(16,16, 20.0, 20.0);
    CGContextStrokeEllipseInRect(context, circlePoint1);
    
    CGRect circlePoint2 = CGRectMake(8.5,8.5, 35.0, 35.0);
    CGContextStrokeEllipseInRect(context, circlePoint2);
    
    CGRect circlePoint3 = CGRectMake(23,23,6,6);
    CGContextFillEllipseInRect(context, circlePoint3);
    
    
    if (self.locked) {
        
        UIColor *c = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.35];
        if (self.lockIsWhiteBalance) {
            c =[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.35];
        }
        
        CGContextSetFillColorWithColor(context, [c CGColor]);
        CGContextFillEllipseInRect(context, circlePoint2);
    }
    
}

@end
