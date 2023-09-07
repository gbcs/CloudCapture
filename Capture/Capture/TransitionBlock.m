//
//  TransitionBlock.m
//  Capture
//
//  Created by Gary Barnett on 9/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "TransitionBlock.h"

@implementation TransitionBlock {
    NSDictionary *titleAttribs;
    NSDictionary *typeAttribs;
}
-(void)dealloc {
    //NSLog(@"%s", __func__);
    
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    titleAttribs = nil;
    typeAttribs = nil;
        
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        NSMutableParagraphStyle* p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
        
        titleAttribs =@{
                             NSFontAttributeName : [UIFont systemFontOfSize:12.0f],
                             NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#0000"],
                             NSParagraphStyleAttributeName: p
                             };
        
        typeAttribs =@{
                             NSFontAttributeName : [UIFont systemFontOfSize:10.0f],
                             NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#0000"],
                             NSParagraphStyleAttributeName: p
                             };

    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(c, [UIColor colorWithWhite:0.0 alpha:1.0].CGColor);
    CGContextSetFillColorWithColor(c, [UIColor colorWithWhite:0.0 alpha:1.0].CGColor);
    
    [@"T" drawInRect:CGRectMake(0,10,self.bounds.size.width, 15) withAttributes:titleAttribs];
    
    NSString *transitionText = @"Cut";
    
    switch (self.type) {
        case 0:
            transitionText = @"Cut";
            break;
        case 1:
            transitionText = @"Fade";
            break;
        case 2:
            transitionText = @"X-Fade";
            break;
    }
    
    [transitionText drawInRect:CGRectMake(0, 0,self.bounds.size.width, 15) withAttributes:typeAttribs];
    
}

@end
