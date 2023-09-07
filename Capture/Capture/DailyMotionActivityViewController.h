//
//  DailyMotionActivityViewController.h
//  Capture
//
//  Created by Gary Barnett on 1/14/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DailymotionSDK/DailymotionSDK.h>

@protocol DailyMotionActivityViewControllerDelegate;

@interface DailyMotionActivityViewController : UIViewController <GradientAttributedButtonDelegate, UITextFieldDelegate, UITextViewDelegate, DailymotionOAuthDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, weak) id<DailyMotionActivityViewControllerDelegate> delegate;


- (IBAction)userTappedUpload:(id)sender;
- (IBAction)userTappedCancel:(id)sender;

@end

@protocol DailyMotionActivityViewControllerDelegate <NSObject>
- (void)dailyMotionDidFinish:(BOOL)completed;
@end

