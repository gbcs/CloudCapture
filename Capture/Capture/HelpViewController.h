//
//  HelpViewController.h
//  Capture
//
//  Created by Gary Barnett on 7/18/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController <GradientAttributedButtonDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, assign) BOOL backOnly;
@property (nonatomic, assign) BOOL noCloseButton;

- (IBAction)userTappedClose:(id)sender;

@end
