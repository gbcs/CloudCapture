//
//  CameraPanelView.m
//  Capture
//
//  Created by Gary  Barnett on 4/2/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "CameraPanelView.h"

@implementation CameraPanelView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)installPanelHeaderAtIndex:(NSInteger )index withTitle:(NSString *)str {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;

    [str drawInRect:CGRectMake(0, 0 +(60 *index), self.bounds.size.width, 25) withAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                                     NSFontAttributeName : [[UtilityBag bag] standardFont],
                                                                                                NSParagraphStyleAttributeName : paragraphStyle
                                                                                                     }];
    
}

-(void)drawElementAtIndex:(NSInteger )index withPos:(NSInteger)pos andTitle:(NSString *)str enabled:(BOOL)enabled active:(BOOL)active usingContext:(CGContextRef)c {
   
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;

    CGFloat width = self.bounds.size.width / 2.0f;
    
    CGRect r = CGRectMake(pos * width, 0 +(60 *index) + 20, width -  5, 35);
    
    if (!enabled) {
      
    } else if (active) {
        CGContextSetFillColorWithColor(c, [UIColor whiteColor].CGColor);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:4];

        [path fill];
    }
    
    [str drawInRect:CGRectInset(r, 0, 7.5) withAttributes:@{ NSForegroundColorAttributeName : enabled && active ? [UIColor blackColor] : [UIColor whiteColor],
                                                           NSFontAttributeName : [UIFont fontWithName:@"LiquidCrystal-Bold" size:18],
                                                           NSParagraphStyleAttributeName : paragraphStyle
                                                           }];
    
    
}


-(void)drawRect:(CGRect)rect {
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    switch (_selected) {
        case 0:
        {
            [self installPanelHeaderAtIndex:0 withTitle:@"Camera"];
            
            [self drawElementAtIndex:0 withPos:0 andTitle:@"Back" enabled:YES active:YES usingContext:c];
            [self drawElementAtIndex:0 withPos:1 andTitle:@"Front" enabled:YES active:NO usingContext:c];
            
            [self installPanelHeaderAtIndex:1 withTitle:@"Image Stabilization"];
            [self drawElementAtIndex:1 withPos:0 andTitle:@"Back" enabled:YES active:NO usingContext:c];
            [self drawElementAtIndex:1 withPos:1 andTitle:@"Front" enabled:YES active:YES usingContext:c];
            
            [self installPanelHeaderAtIndex:2 withTitle:@"Image Flip"];
            [self drawElementAtIndex:2 withPos:0 andTitle:@"Back" enabled:NO active:YES usingContext:c];
            [self drawElementAtIndex:2 withPos:1 andTitle:@"Front" enabled:NO active:NO usingContext:c];
            
            [self installPanelHeaderAtIndex:3 withTitle:@"Rotation Lock"];
            [self drawElementAtIndex:3 withPos:0 andTitle:@"Back" enabled:YES active:YES usingContext:c];
            [self drawElementAtIndex:3 withPos:1 andTitle:@"Front" enabled:YES active:NO usingContext:c];
            
        }
            break;
            
        default:
            break;
    }
    
    
    /*
     
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
     
     */
    
    
    
}


@end
