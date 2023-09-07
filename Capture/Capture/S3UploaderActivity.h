//
//  S3UploaderActivity.h
//  Capture
//
//  Created by Gary Barnett on 1/17/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "S3UploaderActivityViewController.h"

@interface S3UploaderActivity : UIActivity <S3UploaderActivityViewControllerDelegate>

@property (nonatomic, copy) NSArray *activityItems;

+ (NSString*)activityTypeString;

@end

