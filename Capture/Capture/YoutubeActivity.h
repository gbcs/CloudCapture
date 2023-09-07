//
//  YoutubeActivity.h
//  Capture
//
//  Created by Gary Barnett on 11/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YoutubeActivityViewController.h"

@interface YoutubeActivity : UIActivity <YoutubeActivityViewControllerDelegate>
@property (nonatomic, copy) NSArray *activityItems;

+ (NSString*)activityTypeString;


@end
