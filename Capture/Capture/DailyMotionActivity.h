//
//  DailyMotionActivity.h
//  Capture
//
//  Created by Gary Barnett on 1/14/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyMotionActivityViewController.h"

@interface DailyMotionActivity : UIActivity <DailyMotionActivityViewControllerDelegate>
@property (nonatomic, copy) NSArray *activityItems;

+ (NSString*)activityTypeString;


@end

