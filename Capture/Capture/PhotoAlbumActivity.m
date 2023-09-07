//
//  PhotoAlbumActivity.m
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "PhotoAlbumActivity.h"

@implementation PhotoAlbumActivity

+ (NSString *)activityTypeString
{
    return @"com.gbcs.PhotoAlbumActivity";
}

- (NSString *)activityType {
    return [PhotoAlbumActivity activityTypeString];
}

- (NSString *)activityTitle {
    return @"Move to Camera Roll";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"moveActivity"];
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
    // Filter out any items that aren't NSURL objects
    NSMutableArray *urlItems = [NSMutableArray arrayWithCapacity:[activityItems count]];
    for (id object in activityItems) {
        if ([object isKindOfClass:[NSURL class]]) {
            [urlItems addObject:object];
        }
    }
    self.activityItems = [NSArray arrayWithArray:urlItems];
}
- (UIViewController *)activityViewController {
    PhotoAlbumActivityViewController *vc = [[PhotoAlbumActivityViewController alloc] initWithNibName:@"PhotoAlbumActivityViewController" bundle:nil];
    vc.activityItems = self.activityItems;
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    return vc;
}

- (void)photoAlbumDidFinish:(BOOL)completed {
    self.activityItems = nil;
    [self activityDidFinish:completed];
    [[UtilityBag bag] logEvent:@"moveToCameraRoll" withParameters:@{ @"result" : @(completed) } ];
    
}

@end
