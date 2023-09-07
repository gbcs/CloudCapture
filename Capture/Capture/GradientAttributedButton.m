//
//  GradientAttributedButton.m
//  Capture
//
//  Created by Gary Barnett on 9/4/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "GradientAttributedButton.h"

@implementation GradientAttributedButton {
    NSAttributedString *title;
    NSAttributedString *titleDisabled;
    
    UIColor *bgBeginGradientColor;
    UIColor *bgEndGradientColor;
    
    UILabel *label;
    BOOL applyGradient;
}

-(void)dealloc {
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    title = nil;
    titleDisabled = nil;
    
    bgBeginGradientColor = nil;
    bgEndGradientColor = nil;
    
    label = nil;
}

-(void)setTitle:(NSAttributedString *)buttonTitle disabledTitle:(NSAttributedString *)buttonDisabledTitle beginGradientColorString:(NSString *)bgGradientColorBegin endGradientColor:(NSString *)bgGradientColorEnd {
    title = buttonTitle;
    titleDisabled = buttonDisabledTitle;
    bgBeginGradientColor = [[UtilityBag bag] colorWithHexString:bgGradientColorBegin];
    bgEndGradientColor = [[UtilityBag bag] colorWithHexString:bgGradientColorEnd];
    [self update];
}

-(void)update {
    self.backgroundColor = [UIColor clearColor];
    
    if (!label) {
        label = [[UILabel alloc] initWithFrame:self.bounds];
        [self addSubview:label];
        
        UILongPressGestureRecognizer *longG = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userPressed:)];
        [self addGestureRecognizer:longG];
        longG.minimumPressDuration = 0.001;
        self.userInteractionEnabled  = YES;

    }
    
    label.frame = CGRectInset(self.bounds, 10,0);
    
    label.attributedText = self.enabled ? title : titleDisabled;
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    applyGradient = YES;
    
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
         }
    return self;
}

-(void)userPressed:(UILongPressGestureRecognizer *)g {
    if (!self.enabled) {
        return;
    }
    
    if (g.state == UIGestureRecognizerStateBegan) {
        applyGradient = NO;
        [self setNeedsDisplay];
    } else if (g.state == UIGestureRecognizerStateEnded) {
        applyGradient = YES;
        [self setNeedsDisplay];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate userPressedGradientAttributedButtonWithTag:self.tag];
        });
    }
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    NSMutableArray *normalGradientLocations = [NSMutableArray arrayWithObjects:
                                   [NSNumber numberWithFloat:0.0f],
                                   [NSNumber numberWithFloat:1.0f],
                                   nil];
  
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:2];
    
    if (!bgBeginGradientColor) {
        bgBeginGradientColor = [UIColor redColor];
    }
    
    [colors addObject:(id)[bgBeginGradientColor CGColor]];
    
    if (applyGradient) {
        if (bgEndGradientColor) {
            [colors addObject:(id)[bgEndGradientColor CGColor]];
        } else {
            [colors addObject:(id)[bgBeginGradientColor CGColor]];
        }
    }
    
    NSMutableArray  *normalGradientColors = colors;
    
    NSInteger locCount = [normalGradientLocations count];
    CGFloat locations[locCount];
    for (NSInteger i = 0; i < [normalGradientLocations count]; i++)
    {
        NSNumber *location = [normalGradientLocations objectAtIndex:i];
        locations[i] = [location floatValue];
    }
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGGradientRef normalGradient = CGGradientCreateWithColors(space, (CFArrayRef)normalGradientColors, locations);
    CGColorSpaceRelease(space);

    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGMutablePathRef outlinePath = CGPathCreateMutable();
    float offset = 5.0;
    float w  = [self bounds].size.width;
    float h  = [self bounds].size.height;
    CGPathMoveToPoint(outlinePath, nil, offset*2.0, offset);
    CGPathAddArcToPoint(outlinePath, nil, offset, offset, offset, offset*2, offset);
    CGPathAddLineToPoint(outlinePath, nil, offset, h - offset*2.0);
    CGPathAddArcToPoint(outlinePath, nil, offset, h - offset, offset *2.0, h-offset, offset);
    CGPathAddLineToPoint(outlinePath, nil, w - offset *2.0, h - offset);
    CGPathAddArcToPoint(outlinePath, nil, w - offset, h - offset, w - offset, h - offset * 2.0, offset);
    CGPathAddLineToPoint(outlinePath, nil, w - offset, offset*2.0);
    CGPathAddArcToPoint(outlinePath, nil, w - offset , offset, w - offset*2.0, offset, offset);
    CGPathCloseSubpath(outlinePath);
    
    CGContextSetShadow(ctx, CGSizeMake(0,2), 3);
    CGContextAddPath(ctx, outlinePath);
    CGContextFillPath(ctx);
    
    CGContextAddPath(ctx, outlinePath);
    CGContextClip(ctx);
    CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint end = CGPointMake(rect.origin.x, rect.size.height);
    CGContextDrawLinearGradient(ctx, normalGradient, start, end, 0);
    CGGradientRelease(normalGradient);
    CGPathRelease(outlinePath);
  
    

}


@end
