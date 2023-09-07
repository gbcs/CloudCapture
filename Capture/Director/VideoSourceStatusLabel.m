//
//  VideoSourceStatusLabel.m
//  Cloud Director
//
//  Created by Gary  Barnett on 3/10/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "VideoSourceStatusLabel.h"

@implementation VideoSourceStatusLabel {
    BOOL listening;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)listen {
    if (listening) {
        [self stopListening];
    }
    listening = YES;
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusForID:) name:@"updateConnectionStatusForID" object:nil];
}

-(void)updateConnectionStatusForID:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSString *IDStr =  [args objectAtIndex:0];
    if (![self.ID isEqual:IDStr]) {
        return;
    }
    self.text = [args objectAtIndex:1];
}


-(void)stopListening {
    if (!listening) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dealloc {
    [self stopListening];
}


@end
