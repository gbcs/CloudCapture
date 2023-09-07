//
//  MotionCircle.m
//  Cloud Director
//
//  Created by Gary  Barnett on 3/12/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "MotionCircle.h"


@implementation MotionCircle {
    CGFloat midX;
    CGFloat midY;
    BOOL isStill;
    NSInteger pendingStill;
    CGFloat motion;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        midX = self.frame.size.width / 2.0f;
        midY = self.frame.size.height / 2.0f;
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapped:)];
        [self addGestureRecognizer:tapG];
    }
    return self;
}

-(void)userTapped:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self.delegate motionCircleCenterTapped:self];
    }
}

-(void)setPitch:(CGFloat)p andYaw:(CGFloat )y  andRoll:(CGFloat )r {
   
    CGFloat c1 = MAX(p, y);
    c1 = MAX(c1, r);
    
    CGFloat c2 = MIN(p, y);
    c2 = MIN(c2, r);

    motion = MAX(fabsf(c1), fabsf(c2));
    
    if (motion < 0.1f) {
        if (!isStill) {
            if (pendingStill <2) {
                pendingStill++;
            } else {
                isStill = YES;
                [_delegate deviceMotionStatusIsStill:YES];
            }
        }
    } else if (isStill) {
        isStill = NO;
        pendingStill = 0;
        [_delegate deviceMotionStatusIsStill:NO];
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rectb{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat circleSize = motion * 10.0f;
    if (circleSize > 8) {
        circleSize = 8;
    }
    if (circleSize >= 0.5f) {
        CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, midX, midY);
        CGContextAddEllipseInRect(context, CGRectMake(midX - circleSize, midY - circleSize, circleSize*2.0,circleSize*2.0));
        CGContextFillPath(context);
    }
}


@end
