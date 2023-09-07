//
//  VideoThumbImageView.m
//  Cloud Director
//
//  Created by Gary  Barnett on 3/10/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "VideoThumbImageView.h"

@implementation VideoThumbImageView {
    BOOL listening;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(void)listen {
    if (listening) {
        [self stopListening];
    }
    listening = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewDataForID:) name:@"previewDataForID" object:nil];
}


-(void)stopListening {
    if (!listening) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)previewDataForID:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSString *cameraID =  [args objectAtIndex:0];
    
    if (![self.ID isEqual:cameraID]) {
        return;
    }
    
    UIImage *previewImage = [UIImage imageWithData:[args objectAtIndex:1]];
    if (previewImage) {
        self.image = previewImage;
    }
}

-(void)dealloc {
    [self stopListening];
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
