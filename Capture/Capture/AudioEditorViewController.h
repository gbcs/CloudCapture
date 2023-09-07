//
//  AudioEditorViewController.h
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioWaveformHandler.h"
#import "AudioWaveformView.h"
#import "CutScrubberBar.h"
#import "AudioMergeSelectViewController.h"

@interface AudioEditorViewController : UIViewController <AudioSampleDelegate, GradientAttributedButtonDelegate, UIScrollViewDelegate, CutScrubberBarDelegate, AudioMergeSelectFileDelegate>
@property (nonatomic, copy) AVURLAsset *asset;

@end

