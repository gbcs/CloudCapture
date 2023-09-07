//
//  AzureActivity.h
//  Capture
//
//  Created by Gary Barnett on 1/29/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AzureViewController.h"

@interface AzureActivity : UIActivity <AzureUploaderActivityViewControllerDelegate>

@property (nonatomic, copy) NSArray *activityItems;

+ (NSString*)activityTypeString;

@end

