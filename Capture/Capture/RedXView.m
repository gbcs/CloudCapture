//
//  RedXView.m
//  Capture
//
//  Created by Gary Barnett on 10/25/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "RedXView.h"

@implementation RedXView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
    CGRect microphoneLoc = self.bounds;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(context, 3.0);
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextMoveToPoint(context,microphoneLoc.origin.x, microphoneLoc.origin.y);
    CGContextAddLineToPoint(context,microphoneLoc.origin.x + microphoneLoc.size.width, microphoneLoc.origin.y + microphoneLoc.size.height);
    CGContextMoveToPoint(context,microphoneLoc.origin.x + microphoneLoc.size.width, microphoneLoc.origin.y);
    CGContextAddLineToPoint(context,microphoneLoc.origin.x, microphoneLoc.origin.y + microphoneLoc.size.height);
    CGContextStrokePath(context);
    

}


@end
