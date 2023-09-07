//
//  FixedTimelineAudioView.m
//  Capture
//
//  Created by Gary Barnett on 12/30/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "FixedTimelineAudioView.h"

@implementation FixedTimelineAudioView {
    CGFloat sourceAudio;
    CGFloat clipAudio;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect r = CGRectMake(0,0,frame.size.width, frame.size.height);
        UIView *v = [[UIView alloc] initWithFrame:CGRectInset(r, 2, 2)];
        v.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        [self addSubview:v];
        
        UILabel *l2 = [[UILabel alloc] initWithFrame:CGRectMake(0,0,frame.size.width, (frame.size.height/2.0f) - 10)];
        l2.tag = 102;
        l2.numberOfLines = 0;
        l2.textColor = [UIColor whiteColor];
        l2.backgroundColor = [UIColor clearColor];
        l2.font = [UIFont systemFontOfSize:12];
        l2.textAlignment = NSTextAlignmentCenter;
        l2.lineBreakMode = NSLineBreakByCharWrapping;
        l2.text = @"Unknown Name";
        [self addSubview:l2];

        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,(frame.size.height/2.0f) - 10,frame.size.width, 30)];
        l.tag = 101;
        l.numberOfLines = 0;
        l.textColor = [UIColor whiteColor];
        l.backgroundColor = [UIColor clearColor];
        l.font = [UIFont systemFontOfSize:12];
        l.textAlignment = NSTextAlignmentCenter;
        l.text = @"00:00:00";
        [self addSubview:l];
        
        
        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0,frame.size.height - 60,frame.size.width, 60)];
        t.tag = 103;
        t.numberOfLines = 0;
        t.textColor = [UIColor whiteColor];
        t.backgroundColor = [UIColor clearColor];
        t.font = [UIFont systemFontOfSize:12];
        t.textAlignment = NSTextAlignmentCenter;
        t.numberOfLines = 0;
        t.lineBreakMode = NSLineBreakByWordWrapping;
    
        [self addSubview:t];

        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapped:)];
        [self addGestureRecognizer:tapG];
    }
    return self;
}

-(void)userTapped:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"userTappedAudioResourceAtIndex" object:@(_index)];
    }
}

-(NSString *)strForAudio {
    return [NSString stringWithFormat:@"Volume\nOriginal: %2d%%\nReplacement: %2d%%", (int)(sourceAudio * 100.0f), (int)(clipAudio * 100.0f)];
}

-(void)updateWithArray:(NSArray *)array {
    AVAsset *asset = [array objectAtIndex:0];
    sourceAudio = [[array objectAtIndex:1] floatValue];
    clipAudio = [[array objectAtIndex:2] floatValue];
    
    UILabel *durationLabel = (UILabel *)[self viewWithTag:101];
    durationLabel.text = [[UtilityBag bag] durationStr:CMTimeGetSeconds([asset duration])];
    UILabel *titleLabel = (UILabel *)[self viewWithTag:102];
    
    UILabel *mixLabel = (UILabel *)[self viewWithTag:103];
    mixLabel.text = [self strForAudio];
   
    BOOL found = NO;
    for (AVMetadataItem *item in asset.commonMetadata) {
        if ([item.commonKey isEqualToString:@"title"]) {
            titleLabel.text = (NSString *)item.value;
            found = YES;
            break;
        }
    }
    if (!found) {
        AVURLAsset *a = (AVURLAsset *)asset;
        titleLabel.text = [[a.URL path] lastPathComponent];
    }
}

@end
