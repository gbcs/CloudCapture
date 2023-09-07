//
//  AzureActivity.m
//  Capture
//
//  Created by Gary Barnett on 1/29/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AzureActivity.h"
#import "AzureViewController.h"

@implementation AzureActivity

+ (NSString *)activityTypeString
{
    return @"com.gbcs.AzureUploaderActivity";
}

- (NSString *)activityType {
    return [AzureActivity activityTypeString];
}

- (NSString *)activityTitle {
    return @"Upload to Azure Container";
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
    AzureViewController *vc = [[AzureViewController alloc] initWithNibName:@"AzureViewController" bundle:nil];
    vc.activityItems = self.activityItems;
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    return nav;
}

- (void)AzureDidFinish:(BOOL)completed {
    [[UtilityBag bag] logEvent:@"AzureUpload" withParameters:@{ @"result" : @(completed) } ];
    
    self.activityItems = nil;
    [self activityDidFinish:YES];
}

@end
