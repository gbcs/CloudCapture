//
//  CutScrubberBar.m
//  Capture
//
//  Created by Gary Barnett on 9/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CutScrubberBar.h"

@implementation CutScrubberBar {
    NSInteger seconds;
    NSDictionary *secondsAttribDictL;
    NSDictionary *secondsAttribDictM;
    NSDictionary *secondsAttribDictR;
    NSInteger currentSecond;
    __weak NSObject <CutScrubberBarDelegate> *delegate;
    BOOL gestureAdded;
}

-(void)dealloc {
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
        
    secondsAttribDictL = nil;
    secondsAttribDictM = nil;
    secondsAttribDictR = nil;
    delegate = nil;
}

-(void)setDelegate:(NSObject <CutScrubberBarDelegate> *)scrubDelegate {
    delegate = scrubDelegate;
    if (!gestureAdded) {
        UILongPressGestureRecognizer *longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longP.minimumPressDuration = 0.01;
        [self addGestureRecognizer:longP];
        gestureAdded = YES;
    }
}

-(void)updatePosition:(NSInteger)second {
    currentSecond = second;
    [self setNeedsDisplay];
}


-(void)longPress:(UILongPressGestureRecognizer *)g {
    
    BOOL updatePosition = NO;
    
    if (g.state == UIGestureRecognizerStateBegan) {
        [delegate userDidBeginScrubberPress];
        updatePosition = YES;
    } else if ( (g.state == UIGestureRecognizerStateEnded) || (g.state == UIGestureRecognizerStateCancelled) ) {
       [delegate userPressedScrubberAtSecond:currentSecond];
       [delegate userDidEndScrubberPress];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        updatePosition = YES;
    }
    
    if (updatePosition) {
        CGPoint pos = [g locationInView:self];
        float secPer = seconds / self.frame.size.width;
        currentSecond = secPer * pos.x;
        [self setNeedsDisplay];
    }
}

-(void)setDuration:(NSInteger)duration {
    
    NSMutableParagraphStyle* pL = [NSMutableParagraphStyle new];
    pL.alignment = NSTextAlignmentLeft;

    NSMutableParagraphStyle* pM = [NSMutableParagraphStyle new];
    pM.alignment = NSTextAlignmentCenter;

    NSMutableParagraphStyle* pR = [NSMutableParagraphStyle new];
    pR.alignment = NSTextAlignmentRight;

    secondsAttribDictL =@{
                         NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"],
                         NSParagraphStyleAttributeName: pL
                         };
    
    secondsAttribDictM =@{
                         NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"],
                         NSParagraphStyleAttributeName: pM
                         };

    
    secondsAttribDictR =@{
                         NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"],
                         NSParagraphStyleAttributeName: pR
                         };


    seconds = duration;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (seconds <1) {
        return;
    }
    
    if (currentSecond > seconds) {
        currentSecond = seconds;
    }
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(c, [UIColor colorWithWhite:0.8 alpha:1.0].CGColor);
    
    NSInteger numLines = (self.frame.size.width + 7.5) / 7.5;
    
    CGContextMoveToPoint(c, 0, 24);
    
    float offset = 3.0;
    
    for (NSInteger x=0;x<=numLines;x++) {
        CGContextAddLineToPoint(c, offset + (x*7.5), 24);
        CGContextAddLineToPoint(c, offset + (x*7.5), 20);
        CGContextAddLineToPoint(c, offset + (x*7.5), 20);
        CGContextAddLineToPoint(c, offset + (x*7.5), 24);
    }
    
    CGContextStrokePath(c);
    
    float cellSize = self.frame.size.width / 5.0f;
    
    [@"00:00" drawInRect:CGRectMake(0, 0, cellSize, 14) withAttributes:secondsAttribDictL];
    
    NSInteger min = seconds / 60.0f;
    
    NSInteger sec = seconds - (min * 60);
    
    [[NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec] drawInRect:CGRectMake(cellSize * 4, 0, cellSize, 14) withAttributes:secondsAttribDictR];
    
    NSInteger p25 = (seconds * 0.5f);
    min = p25 / 60.0f;
    sec = p25 - (min * 60);
    [[NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec] drawInRect:CGRectMake(0, 0, self.frame.size.width, 14) withAttributes:secondsAttribDictM];
    
    CGContextSetStrokeColorWithColor(c, [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0].CGColor);
    
    float perX = (self.frame.size.width - 6.0f) / seconds;
    
    if (delegate) {
        float pointerX = 3.0f + (currentSecond * perX);
        
        CGContextMoveToPoint(c, pointerX, 25);
        CGContextAddLineToPoint(c, pointerX - 3, 29);
        CGContextAddLineToPoint(c, pointerX + 3, 29);
        CGContextAddLineToPoint(c, pointerX , 25);
        CGContextStrokePath(c);
    }
}

@end
