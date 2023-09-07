//
//  TitleFrameTextView.m
//  Capture
//
//  Created by Gary Barnett on 10/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "TitleFrameTextView.h"

@implementation TitleFrameTextView {
    NSDateFormatter *dateFormatter;
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy HH:mm:ssZ"];

    }
    return self;
}

-(void)dealloc {
        //NSLog(@"%s", __func__);
    
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    dateFormatter = nil;
}

-(void)drawRect:(CGRect)rect
{
    NSStringDrawingContext *c = [[NSStringDrawingContext alloc] init];
    
    NSString *font = [_dict objectForKey:@"font"];
    CGSize bgSize = [[_dict objectForKey:@"bgSize"] CGSizeValue];
    CGSize bgScaleFactor = CGSizeMake(self.bounds.size.width / bgSize.width, (self.bounds.size.height / bgSize.height));
    
    for (NSString *element in [[SettingsTool settings] masterTitlingElementList]) {
        NSDictionary *elementDict = [_dict objectForKey:element];
        if (elementDict) {
            CGRect o = [[elementDict objectForKey:@"rect"] CGRectValue];
            CGRect r = CGRectMake(o.origin.x * bgScaleFactor.width, o.origin.y * bgScaleFactor.height, o.size.width * bgScaleFactor.width, o.size.height * bgScaleFactor.height);
            NSString *str = [elementDict objectForKey:@"text"];
            CGFloat pointSize = [[elementDict objectForKey:@"pointSize"] floatValue];
            
            if ([element isEqualToString:@"title"]) {
                str = [[SettingsTool settings] engineTitlingTitle];
            } else if ([element isEqualToString:@"author"]) {
                str = [[SettingsTool settings] engineTitlingAuthor];
            } else if ([element isEqualToString:@"scene"]) {
                str = [[SettingsTool settings] engineTitlingScene];
            } else if ([element isEqualToString:@"take"]) {
                str = [NSString stringWithFormat:@"Take %ld", (long)[[SettingsTool settings] engineTitlingTake]];
            } else if ([element isEqualToString:@"Date+Time"]) {
                str = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]];
            }
           
            NSMutableParagraphStyle* p = [NSMutableParagraphStyle new];
            p.alignment = NSTextAlignmentCenter;
            p.lineBreakMode = NSLineBreakByWordWrapping;
            
            NSDictionary *attr =@{
                                  NSFontAttributeName : [UIFont fontWithName:font size:pointSize * bgScaleFactor.width],
                                  NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"],
                                  NSParagraphStyleAttributeName: p
                                  };
            
            
            [[str stringByAppendingString:@"\n"] drawWithRect:r
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:attr
                                                      context:c];
        }
    }

}


@end
