//
//  FocusReticleView.m
//  Capture
//
//  Created by Gary Barnett on 7/21/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "FocusReticleView.h"

@implementation FocusReticleView {
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
    CGContextSetLineWidth(context, lineWidth);
    
    float midX =( self.frame.size.width / 2.0f )+ (lineWidth / 2.0f);
    float midY = (self.frame.size.height / 2.0f) + (lineWidth / 2.0f);
    
    CGContextMoveToPoint(context, midX-6, midY);
    CGContextAddLineToPoint(context, midX+6, midY);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, midX, midY-6);
    CGContextAddLineToPoint(context, midX, midY +6);
    CGContextStrokePath(context);
    
    CGRect circlePoint = (CGRectMake(8.5,8.5, 35.0, 35.0));
    CGContextStrokeEllipseInRect(context, circlePoint);

  
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0.0 green:self.locked ? 1.0 : 0.1 blue:0.0 alpha: self.locked ? 0.35 : 0.1] CGColor]);
      
    
    CGContextFillEllipseInRect(context, circlePoint);

}


@end
