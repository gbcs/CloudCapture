//
//  CutTimelineView.m
//  Capture
//
//  Created by Gary Barnett on 9/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CutTimelineView.h"

@implementation CutTimelineView {
    NSDictionary *secondsAttribDict;
}

-(void)dealloc {
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    secondsAttribDict = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        NSMutableParagraphStyle* p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
        
        secondsAttribDict =@{
                            NSFontAttributeName : [UIFont systemFontOfSize:8.0f],
                            NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"],
                            NSParagraphStyleAttributeName: p
                            };
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(c, [UIColor colorWithWhite:0.8 alpha:1.0].CGColor);
   
    NSInteger numLines = self.seconds * self.thumbSize.width / 7.5;
    
    CGContextMoveToPoint(c, 0, 14);
    
    for (NSInteger x=0;x<numLines;x++) {
        CGContextAddLineToPoint(c, (x*7.5), 14);
        CGContextAddLineToPoint(c, (x*7.5), 10);
        CGContextAddLineToPoint(c, (x*7.5), 10);
        CGContextAddLineToPoint(c, (x*7.5), 14);
    }
    
    CGContextStrokePath(c);
    
    for (NSInteger x=0;x<self.seconds;x++) {
        NSInteger min = x / 60.0f;
        NSInteger sec = x - (min * 60);
        NSString *secStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec];
        [secStr drawInRect:CGRectMake(x * self.thumbSize.width,0, self.thumbSize.width, 8) withAttributes:secondsAttribDict];
    }
}


@end
