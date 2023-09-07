//
//  CreateMovieViewController.h
//  Capture
//
//  Created by Gary Barnett on 9/10/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CutScrubberBar.h"
#import "AddClipsViewController.h"
#import "TransitionBlock.h"
#import "CreateMoviePreviewViewController.h"
#import "AudioBrowser.h"
#import "AddAudioViewController.h"
#import "AudioWaveformHandler.h"
#import "SPUserResizableView.h"

@interface CreateMovieViewController : UIViewController <GradientAttributedButtonDelegate,CutScrubberBarDelegate, AddClipsViewControllerDelegate, UIScrollViewDelegate, AddAudioViewControllerDelegate, SPUserResizableViewDelegate>
- (IBAction)userTappedTransitionButton:(id)sender;
- (IBAction)userTappedSaveButton:(id)sender;
- (IBAction)userTappedHelpButton:(id)sender;
@end
