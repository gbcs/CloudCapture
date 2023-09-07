//
//  ReTimeClipViewController.h
//  Capture
//
//  Created by Gary Barnett on 11/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailView.h"
#import "CutScrubberBar.h"

@interface ReTimeClipViewController : UIViewController <GradientAttributedButtonDelegate, CutScrubberBarDelegate>
@property (nonatomic, copy) AVURLAsset *clip;
@property (nonatomic, weak) IBOutlet UIToolbar *toolBar;
-(IBAction)userTappedConfirmButton:(id)sender;
-(IBAction)userTappedStartOverButton:(id)sender;
-(IBAction)userTappedHelpButton:(id)sender;
-(IBAction)userTappedFPSButton:(id)sender;
-(IBAction)userTappedFreezeButton:(id)sender;
@end
