//
//  AudioLevelView.m
//  iArchiver
//
//  Created by Gary Barnett on 5/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioLevelView.h"

@implementation AudioLevelView {
    BOOL noData;
}
@synthesize isLeft;

-(void)dealloc {
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        value = 1.0;
    }
    return self;
}

-(void)noDataForThisTrack {
    if (!noData) {
        noData = YES;
        ready = YES;
        [self setNeedsDisplay];
    }
}

-(void)updateValue:(float)newVal {
    if (newVal > 1.0f ) {
        newVal = 1.0f;
    } else if (newVal < 0.0f) {
        newVal = 0.0f;
    }
    
    value = 1.0 - newVal;
    ready = YES;
    
    //NSLog(@"value:%f", value);
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!ready) {
        return;
    }
    
    int width = self.frame.size.width -12;
    
    BOOL isIpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    int numElements = 40;
    
    if (width < 378) {
        numElements = 20;
    }
    
    int spacing = 5;
    
    int perWidth = (width - (numElements * spacing)) / numElements;
    
    [[UIColor colorWithWhite:0.8 alpha:1.0] setStroke];
    
    if (noData) {
        [[UIColor colorWithWhite:0.4 alpha:1.0] setStroke];
    } else {
        [[UIColor colorWithWhite:0.8 alpha:1.0] setStroke];
    }
    
    NSString *LRText = self.isLeft ? @"L" : @"R";
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextDrawingMode(context, kCGTextStroke);
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
    
    
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment:NSTextAlignmentCenter];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    
	
	NSDictionary *textAttributes = @{
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSParagraphStyleAttributeName : style,
                                     NSFontAttributeName : [UIFont systemFontOfSize:8.0]
                                     };
    
   
    [LRText drawAtPoint:CGPointMake(0,isIpad ? 5 : 0) withAttributes:textAttributes];
    
    [[UIColor greenColor] setFill];
    [[UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0] setStroke];
      

    for (int x=0;x<numElements;x++) {
        float alpha = noData ? 0.4f : 1.0f;
        
        BOOL showSegment = (x +1 < ((1 - value) * 40)) ? YES : NO;
        
        float tX = perWidth *x + (x*spacing);
        
        float h = 10;
  
        if (noData) {
            showSegment = NO;
        }
        
        if (!showSegment) {
            UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(12 + spacing + tX, isIpad ? 5 : 0, perWidth, h) cornerRadius: isIpad ? 4 : 2];
            [roundedRect strokeWithBlendMode:kCGBlendModeNormal alpha:alpha];
        } else {
            UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(12 + spacing + tX, isIpad ? 5 : 0, perWidth, h) cornerRadius: isIpad ? 4 : 2];
            [roundedRect fillWithBlendMode: kCGBlendModeNormal alpha:alpha];
        }
    }
}


@end
