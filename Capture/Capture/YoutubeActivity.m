//
//  YoutubeActivity.m
//  Capture
//
//  Created by Gary Barnett on 11/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "YoutubeActivity.h"
#import "AppDelegate.h"

@implementation YoutubeActivity

+ (NSString *)activityTypeString
{
    return @"com.gbcs.YoutubeActivity";
}

- (NSString *)activityType {
    return [YoutubeActivity activityTypeString];
}

- (NSString *)activityTitle {
    return @"Upload to YouTube";
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
    
    YoutubeActivityViewController *vc = [[YoutubeActivityViewController alloc] initWithNibName:@"YoutubeActivityViewController" bundle:nil];
    vc.activityItems = self.activityItems;
    vc.delegate = self;
     
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    
    return nc;
}

- (void)youTubeDidFinish:(BOOL)completed {
    self.activityItems = nil;
    [[UtilityBag bag] logEvent:@"youtubeUpload" withParameters:@{ @"result" : @(completed) } ];
    [self activityDidFinish:completed];
}

@end
