//
//  YoutubeActivityViewController.h
//  Capture
//
//  Created by Gary Barnett on 11/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTLYoutube.h"

@protocol YoutubeActivityViewControllerDelegate;

@interface YoutubeActivityViewController : UIViewController <GradientAttributedButtonDelegate, UITextFieldDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, weak) id<YoutubeActivityViewControllerDelegate> delegate;
@property (nonatomic, readonly) GTLServiceYouTube *youTubeService;

- (IBAction)userTappedUpload:(id)sender;
- (IBAction)userTappedCancel:(id)sender;


@end

@protocol YoutubeActivityViewControllerDelegate <NSObject>
- (void)youTubeDidFinish:(BOOL)completed;
@end