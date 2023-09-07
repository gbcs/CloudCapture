//
//  StillControlBarView.m
//  Capture
//
//  Created by Gary  Barnett on 4/7/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "StillControlBarView.h"

@implementation StillControlBarView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapped:)];
        [self addGestureRecognizer:tapG];

    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
}

-(void)test {
    [_delegate userStartedPressingRecordButton];
    [_delegate userStoppedPressingRecordButton];
    [_delegate userTappedExitButton];
    [_delegate userTappedOptionsButton];
    [_delegate userTappedPhotoButton];
}

-(void)userTapped:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        CGPoint p = [g locationInView:g.view];
        
        BOOL horizontal = g.view.frame.size.width > g.view.frame.size.height;
        
        NSInteger whichOne = -1;
        
        if (horizontal) {
            whichOne = 4.0 * (p.x / g.view.bounds.size.width);
        } else {
            whichOne = 4.0 * (p.y / g.view.bounds.size.height);
        }
        
        NSLog(@"whichOne:1:%@", @(whichOne));
        
        
        
        
    }
}

@end
