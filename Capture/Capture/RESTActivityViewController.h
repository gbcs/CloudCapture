//
//  RESTActivityViewController.h
//  Capture
//
//  Created by Gary Barnett on 1/20/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RESTActivityViewControllerDelegate;

@interface RESTActivityViewController : UIViewController <GradientAttributedButtonDelegate, UITextFieldDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, NSURLSessionDelegate>

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, weak) id<RESTActivityViewControllerDelegate> delegate;

- (IBAction)userTappedUpload:(id)sender;
- (IBAction)userTappedCancel:(id)sender;

@end

@protocol RESTActivityViewControllerDelegate <NSObject>
- (void)RESTDidFinish:(BOOL)completed;
@end

