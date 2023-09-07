//
//  TitleFrameView.m
//  Capture
//
//  Created by Gary Barnett on 10/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "TitleFrameView.h"
#import "TitleFrameTextView.h"

@implementation TitleFrameView {
    TitleFrameTextView *textView;
    UIImageView *iv;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        textView = [[TitleFrameTextView alloc] initWithFrame:CGRectZero];
        iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.backgroundColor = [UIColor clearColor];
        [self addSubview:iv];
        [self addSubview:textView];
        
    }
    return self;
}

-(void)dealloc {
        //NSLog(@"%s", __func__);
    
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    textView = nil;
    iv = nil;
}

-(void)updateWithSize:(CGSize)s {
    textView.frame = CGRectMake(0,0,s.width,s.height);
    iv.frame = textView.frame = CGRectMake(0,0,s.width,s.height);
    iv.image = self.bgImage;
    textView.dict = self.titleDict;
    if (_flip) {
        iv.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
        textView.transform =CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    }
    
    if (_flip) {
        iv.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
        textView.transform =CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    }
    
    if (_horizFlip) {
        iv.transform = CGAffineTransformScale(iv.transform, -1, 1);
        textView.transform = CGAffineTransformScale(textView.transform, -1, 1);
        
    }
    
    [textView setNeedsDisplay];
}


@end
