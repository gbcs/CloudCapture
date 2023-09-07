//
//  AddVideoVidevoViewController.h
//  Capture
//
//  Created by Gary  Barnett on 2/25/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddVideoVidevoViewController : UIViewController <UIWebViewDelegate, NSURLSessionDownloadDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, weak) IBOutlet UIWebView *webview;

@end
