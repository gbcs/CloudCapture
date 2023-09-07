//
//  AudioMergeEditView.m
//  Capture
//
//  Created by Gary Barnett on 1/29/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AudioMergeEditView.h"

@implementation AudioMergeEditView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
            // Initialization code
    }
    return self;
}

-(void)update {
    UILabel *l = (UILabel *)[self viewWithTag:100];
    
    if (l) {
        [l removeFromSuperview];
        l = nil;
    }
    
    l = [[UILabel alloc] initWithFrame:self.bounds];
    l.tag = 100;
    l.text = [NSString stringWithFormat:@"Clip:%@",
              _filename
    
              ];
    l.textAlignment = NSTextAlignmentCenter;
    l.lineBreakMode = NSLineBreakByCharWrapping;
    l.numberOfLines = 0;
    l.adjustsFontSizeToFitWidth = YES;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont boldSystemFontOfSize:18];
    if (self.bounds.size.width < 200) {
        l.font = [UIFont systemFontOfSize:12];
    }
    [self addSubview:l];
}

@end
