//
//  AudioVolumeEditView.m
//  Capture
//
//  Created by Gary Barnett on 1/29/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AudioVolumeEditView.h"

@implementation AudioVolumeEditView

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
    l.text = [NSString stringWithFormat:@"Volume: %2.0f%%, In:%@, Out:%@, Ramp Duration:%.1fs",
              self.volume * 100.0f,
              self.rampIn ? @"Ramp" : @"Cut",
              self.rampOut ? @"Ramp" : @"Cut",
              self.rampIn || self.rampOut ? self.rampLength : 0.0f
              ];
    l.textAlignment = NSTextAlignmentCenter;
    l.lineBreakMode = NSLineBreakByWordWrapping;
    l.numberOfLines = 0;
    l.adjustsFontSizeToFitWidth = YES;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont systemFontOfSize:18];
    if (self.bounds.size.width < 200) {
        l.font = [UIFont systemFontOfSize:10];
    }
    [self addSubview:l];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
