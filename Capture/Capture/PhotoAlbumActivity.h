//
//  PhotoAlbumActivity.h
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoAlbumActivityViewController.h"

@interface PhotoAlbumActivity : UIActivity <PhotoAlbumActivityViewControllerDelegate>

@property (nonatomic, copy) NSArray *activityItems;

+ (NSString*)activityTypeString;

@end
