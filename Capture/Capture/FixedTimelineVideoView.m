//
//  FixedTimelineView.m
//  Capture
//
//  Created by Gary Barnett on 12/30/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "FixedTimelineVideoView.h"

@implementation FixedTimelineVideoView {
    AVAssetImageGenerator *generator;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect r = CGRectMake(0,0,frame.size.width, frame.size.height);
        UIView *v = [[UIView alloc] initWithFrame:CGRectInset(r, 2, 2)];
        v.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self addSubview:v];
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(30,4,60,34)];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.backgroundColor = [UIColor blackColor];
        iv.tag = 100;
        [self addSubview:iv];
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,38,frame.size.width, frame.size.height - 38)];
        l.tag = 101;
        l.numberOfLines = 0;
        l.textColor = [UIColor whiteColor];
        l.backgroundColor = [UIColor clearColor];
        l.font = [UIFont systemFontOfSize:12];
        l.text = @"00:00:00";
        l.textAlignment = NSTextAlignmentCenter;
        [self addSubview:l];
        
    }
    
    return self;
}

-(void)dealloc {
    generator = nil;
}

-(void)updateWithAsset:(AVAsset *)asset andPhotoDuration:(NSInteger )duration {
    UILabel *durationLabel = (UILabel *)[self viewWithTag:101];
   
    if (CMTimeCompare(asset.duration, CMTimeMake(0,1)) == NSOrderedSame) {
        AVURLAsset *a = (AVURLAsset *)asset;
        NSString *path = [a.URL path];
        UIImageView *thumbView = (UIImageView *)[self viewWithTag:100];
        thumbView.contentMode = UIViewContentModeScaleAspectFit;
        thumbView.image = [UIImage imageWithContentsOfFile:path];
        durationLabel.text = [[UtilityBag bag] durationStr:duration];
    } else {
        durationLabel.text = [[UtilityBag bag] durationStr:CMTimeGetSeconds([asset duration])];
        generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        [generator setMaximumSize:CGSizeMake(60,34)];
        
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:CMTimeMake(0, 1)]] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
            CGImageRetain(image);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *thumbView = (UIImageView *)[self viewWithTag:100];
                thumbView.image = [UIImage imageWithCGImage:image];
                CGImageRelease(image);
                [self performSelector:@selector(cleanupGenerator) withObject:nil afterDelay:0.1];
            });
        }];
    }
}

-(void)cleanupGenerator {
    generator = nil;
}


@end
