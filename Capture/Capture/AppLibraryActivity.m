//
//  AppLibraryActivity.m
//  Capture
//
//  Created by Gary Barnett on 11/27/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AppLibraryActivity.h"

@implementation AppLibraryActivity

+ (NSString *)activityTypeString
{
    return @"com.gbcs.AppLibraryActivity";
}

- (NSString *)activityType {
    return [AppLibraryActivity activityTypeString];
}

- (NSString *)activityTitle {
    return @"Copy to App Library";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"copyActivity"];
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
    AppLibraryActivityViewController *vc = [[AppLibraryActivityViewController alloc] initWithNibName:@"AppLibraryActivityViewController" bundle:nil];
    vc.activityItems = self.activityItems;
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    return vc;
}

- (void)appLibraryDidFinish:(BOOL)completed {
    self.activityItems = nil;
    [self activityDidFinish:completed];
    [[UtilityBag bag] logEvent:@"copyToAppLibrary" withParameters:@{ @"result" : @(completed) } ];
    
}

@end
