//
//  TItleElementView.m
//  Capture
//
//  Created by Gary Barnett on 10/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "TItleElementView.h"

@implementation TItleElementView

-(void)dealloc {
        // //NSLog(@"%s", __func__);
    _element = nil;
    _font = nil;
    _textStr = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.3];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:1.0].CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(0.5,0.5), 0.5, [UIColor blackColor].CGColor);
    
    NSMutableParagraphStyle* p = [NSMutableParagraphStyle new];
    p.alignment = NSTextAlignmentCenter;
    p.lineBreakMode = NSLineBreakByWordWrapping;

    NSDictionary *attr =@{
                         NSFontAttributeName : self.font,
                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"],
                         NSParagraphStyleAttributeName: p
                         };

    NSString *displayStr = @"";
    
    if ([self.element isEqualToString:@"title"]) {
        displayStr = (self.textStr && ([self.textStr length]>0)) ? self.textStr : @"Title";
    } else if ([self.element isEqualToString:@"author"]) {
        displayStr = (self.textStr && ([self.textStr length]>0)) ? self.textStr : @"Author";
    } else if ([self.element isEqualToString:@"Date+Time"]) {
        displayStr = (self.textStr && ([self.textStr length]>0)) ? self.textStr : @"88/88/8888 88:88:88";
    } else if ([self.element isEqualToString:@"location"]) {
        displayStr = (self.textStr && ([self.textStr length]>0)) ? self.textStr : @"Location";
    } else if ([self.element isEqualToString:@"scene"]) {
        displayStr = (self.textStr && ([self.textStr length]>0)) ? self.textStr : @"Scene";
    } else if ([self.element isEqualToString:@"take"]) {
        displayStr = (self.textStr && ([self.textStr length]>0)) ? self.textStr : @"Take";
    } else if ([self.element isEqualToString:@"custom"]) {
        displayStr = (self.textStr && ([self.textStr length]>0)) ? self.textStr : @"Custom Field";
    }
   
    NSStringDrawingContext *c = [[NSStringDrawingContext alloc] init];

    [[displayStr stringByAppendingString:@"\n"] drawWithRect:CGRectMake(0,0,self.frame.size.width, self.frame.size.height)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:attr
                                                     context:c];
}

@end
