//
//  FilterClipViewController.h
//  Capture
//
//  Created by Gary Barnett on 12/1/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailView.h"
#import "CutScrubberBar.h"
@interface FilterClipViewController : UIViewController <GradientAttributedButtonDelegate, CutScrubberBarDelegate, GPUFilterToolDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) AVURLAsset *clip;

-(IBAction)userTappedConfirmButton:(id)sender;
-(IBAction)userTappedStartOverButton:(id)sender;
-(IBAction)userTappedHelpButton:(id)sender;

@end
