//
//  DailyMotionActivity.m
//  Capture
//
//  Created by Gary Barnett on 1/14/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "DailyMotionActivity.h"

@implementation DailyMotionActivity


+ (NSString *)activityTypeString
{
    return @"com.gbcs.DailyMotionActivity";
}

- (NSString *)activityType {
    return [DailyMotionActivity activityTypeString];
}

- (NSString *)activityTitle {
    return @"Upload to DailyMotion";
}


- (UIImage *)activityImage {
    return [UIImage imageNamed:@"Youtube.png"];
}


- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id obj in activityItems) {
        if ([obj isKindOfClass:[NSURL class]]) {
            return YES;
        }
    }
    return NO;
};

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSMutableArray *urlItems = [NSMutableArray arrayWithCapacity:[activityItems count]];
    for (id object in activityItems) {
        if ([object isKindOfClass:[NSURL class]]) {
            [urlItems addObject:object];
        }
    }
    self.activityItems = [NSArray arrayWithArray:urlItems];
}
- (UIViewController *)activityViewController {
    
    DailyMotionActivityViewController *vc = [[DailyMotionActivityViewController alloc] initWithNibName:@"DailyMotionActivityViewController" bundle:nil];
    vc.activityItems = self.activityItems;
    vc.delegate = self;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    return nc;
}

- (void)dailyMotionDidFinish:(BOOL)completed {
    [[UtilityBag bag] logEvent:@"dailyMotionUpload" withParameters:@{ @"result" : @(completed) } ];
    
    self.activityItems = nil;
    [self activityDidFinish:YES];
}

@end
