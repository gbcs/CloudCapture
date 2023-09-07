//
//  LabeledButton.m
//  Capture
//
//  Created by Gary Barnett on 7/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "LabeledButton.h"

@implementation LabeledButton {
    UIFont *boldFont;
    NSTimer *repeatTimer;
    NSTimer *timer;
    NSDictionary *boldAttribs;
    NSShadow *shadow;
    NSInteger justify;
}

-(void)dealloc {
    NSLog(@"%s", __func__);

    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }

    boldFont = nil;
    repeatTimer = nil;
    timer = nil;
    boldAttribs = nil;
    shadow = nil;
}



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        boldFont = [UIFont fontWithName:@"LiquidCrystal-Bold" size:14];

        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        UILongPressGestureRecognizer *longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(bottomPressed:)];
        longP.minimumPressDuration = 0.0f;
        [self addGestureRecognizer:longP];
        self.enabled = YES;
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentLeft;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        
        shadow = [[UtilityBag bag] getBlackShadowForText];
        
       boldAttribs = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithWhite:0.7f alpha:1.0f], NSForegroundColorAttributeName, boldFont,NSFontAttributeName,  paragraphStyle, NSParagraphStyleAttributeName, shadow, NSShadowAttributeName, nil];

        
    }
    return self;
}

-(void)justify:(NSInteger)j {
    justify = j;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    switch (justify) {
        case 0:
            paragraphStyle.alignment = NSTextAlignmentCenter;
            break;
        case 1:
            paragraphStyle.alignment = NSTextAlignmentLeft;
            break;
        case 2:
            paragraphStyle.alignment = NSTextAlignmentRight;
            break;
    }

    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    shadow = [[UtilityBag bag] getBlackShadowForText];
    
    boldAttribs = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithWhite:0.7f alpha:1.0f], NSForegroundColorAttributeName, boldFont,NSFontAttributeName,  paragraphStyle, NSParagraphStyleAttributeName, shadow, NSShadowAttributeName, nil];
    [self setNeedsDisplay];

}


-(void)bottomPressed:(UILongPressGestureRecognizer *)g {
    if (!self.notifyStringDown) {
        NSLog(@"notifyStringDown is nil in LabeledButton:%@", self.caption);
        return;
    } else if ([self.notifyStringDown isEqualToString:@""]) {
        return; //silently
    }
    
    if (g.state == UIGestureRecognizerStateBegan) {
        [[NSNotificationCenter defaultCenter] postNotificationName:self.notifyStringDown object:nil];
    } else if (g.state == UIGestureRecognizerStateEnded) {
        if (self.notifyStringUp && ([self.notifyStringUp length] > 0)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:self.notifyStringUp object:nil];
        }
    }
}

- (void)drawRect:(CGRect)rect
{
    CGSize cS = CGSizeMake(5,5);
    
    CGPoint c1 = CGPointZero;
    CGPoint p1 = CGPointZero;
    
    switch (justify) {
        case 0:
            c1 = CGPointMake(self.frame.size.width - cS.width, 20 + 12 - (cS.height / 2.0f));
            p1 = CGPointMake(5,25);
            break;
        case 1:
            c1 = CGPointMake(5, 5);
            p1 = CGPointMake(1,20);
            break;
        case 2:
            c1 = CGPointMake(self.frame.size.width - 10, 5);
            p1 = CGPointMake(5,20);
            break;
    }
    
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextDrawingMode(context, kCGTextFill);
    
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0.0 green:0.0 blue:0.7 alpha:self.enabled ? 1.0 : 0.5] CGColor]);
    CGContextFillEllipseInRect(context, CGRectMake(c1.x, c1.y, cS.width, cS.height));
        
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite:0.7 alpha:self.enabled ? 1.0 : 0.5] CGColor]);
    CGContextStrokeEllipseInRect(context, CGRectMake(c1.x, c1.y, cS.width, cS.height));
    
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.7 alpha:self.enabled ? 1.0 : 0.5] CGColor]);
    
  
    [self.caption drawInRect:CGRectMake(p1.x, p1.y, self.frame.size.width - 6 , 24) withAttributes:boldAttribs];
}

@end
