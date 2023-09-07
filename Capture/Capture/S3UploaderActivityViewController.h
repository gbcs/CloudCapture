//
//  S3UploaderActivityViewController.h
//  Capture
//
//  Created by Gary Barnett on 1/17/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>
#import <AWSRuntime/AWSRuntime.h>

@protocol S3UploaderActivityViewControllerDelegate;

@interface S3UploaderActivityViewController : UIViewController <AmazonServiceRequestDelegate, GradientAttributedButtonDelegate, UITextFieldDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, weak) id<S3UploaderActivityViewControllerDelegate> delegate;

- (IBAction)userTappedUpload:(id)sender;
- (IBAction)userTappedCancel:(id)sender;

@end

@protocol S3UploaderActivityViewControllerDelegate <NSObject>
- (void)S3DidFinish:(BOOL)completed;
@end

