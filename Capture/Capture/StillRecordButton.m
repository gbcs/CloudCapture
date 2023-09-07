//
//  StillRecordButton.m
//  Capture
//
//  Created by Gary  Barnett on 4/5/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "StillRecordButton.h"

@implementation StillRecordButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        UILongPressGestureRecognizer *longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userPressed:)];
        longP.minimumPressDuration = 0.01f;
        [self addGestureRecognizer:longP];
        self.userInteractionEnabled = YES;
    }
    return self;
}


-(void)userPressed:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [_delegate userStoppedPressingRecordButton];
    } else if (g.state == UIGestureRecognizerStateBegan) {
        [_delegate userStartedPressingRecordButton];
    }
}

- (void)drawRect:(CGRect)rect
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextDrawingMode(context, kCGTextFill);
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0].CGColor);
    CGContextFillEllipseInRect(context, self.bounds);
    
    
    
}



@end
