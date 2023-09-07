//
//  S3UploaderActivity.m
//  Capture
//
//  Created by Gary Barnett on 1/17/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "S3UploaderActivity.h"
#import "S3UploaderActivityViewController.h"

@implementation S3UploaderActivity

+ (NSString *)activityTypeString
{
    return @"com.gbcs.S3UploaderActivity";
}

- (NSString *)activityType {
    return [S3UploaderActivity activityTypeString];
}

- (NSString *)activityTitle {
    return @"Upload to S3 Bucket";
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
    S3UploaderActivityViewController *vc = [[S3UploaderActivityViewController alloc] initWithNibName:@"S3UploaderActivityViewController" bundle:nil];
    vc.activityItems = self.activityItems;
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    return nav;
}


- (void)S3DidFinish:(BOOL)completed {
    [[UtilityBag bag] logEvent:@"S3Upload" withParameters:@{ @"result" : @(completed) } ];
    
    self.activityItems = nil;
    [self activityDidFinish:YES];
}

@end
