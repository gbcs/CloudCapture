//
//  RESTActivity.h
//  Capture
//
//  Created by Gary Barnett on 1/20/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RESTActivityViewController.h"

@interface RESTActivity : UIActivity <RESTActivityViewControllerDelegate>

@property (nonatomic, copy) NSArray *activityItems;

+ (NSString*)activityTypeString;

@end

