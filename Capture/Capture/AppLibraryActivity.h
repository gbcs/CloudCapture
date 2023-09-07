//
//  AppLibraryActivity.h
//  Capture
//
//  Created by Gary Barnett on 11/27/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppLibraryActivityViewController.h"

@interface AppLibraryActivity : UIActivity <AppLibraryActivityViewControllerDelegate>

@property (nonatomic, copy) NSArray *activityItems;

+ (NSString*)activityTypeString;

@end

