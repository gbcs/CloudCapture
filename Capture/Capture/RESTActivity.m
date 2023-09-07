//
//  RESTActivity.m
//  Capture
//
//  Created by Gary Barnett on 1/20/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "RESTActivity.h"

@implementation RESTActivity

+ (NSString *)activityTypeString
{
    return @"com.gbcs.RESTUploaderActivity";
}

- (NSString *)activityType {
    return [RESTActivity activityTypeString];
}

- (NSString *)activityTitle {
    return @"Upload to REST Service";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"Youtube.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id obj in activityItems) {
        if ([obj isKindOfClass:[NSURL class]]) {
                //NSLog(@"obj:%@", obj);
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
    RESTActivityViewController *vc = [[RESTActivityViewController alloc] initWithNibName:@"RESTActivityViewController" bundle:nil];
    vc.activityItems = self.activityItems;
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    return nav;
}


- (void)RESTDidFinish:(BOOL)completed {
    [[UtilityBag bag] logEvent:@"RESTUpload" withParameters:@{ @"result" : @(completed) } ];
    
    self.activityItems = nil;
    [self activityDidFinish:YES];
}

@end
