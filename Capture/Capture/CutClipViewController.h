//
//  CutClipViewController.h
//  Capture
//
//  Created by Gary Barnett on 9/4/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailView.h"
#import "CutScrubberBar.h"

@interface CutClipViewController : UIViewController <GradientAttributedButtonDelegate, CutScrubberBarDelegate>
@property (nonatomic, copy) AVURLAsset *clip;

-(IBAction)userTappedConfirmButton:(id)sender;
-(IBAction)userTappedStartOverButton:(id)sender;
-(IBAction)userTappedHelpButton:(id)sender;
-(IBAction)userTappedSavePictureButton:(id)sender;
- (IBAction)userTappedExtractAudioButton:(id)sender;

@end
