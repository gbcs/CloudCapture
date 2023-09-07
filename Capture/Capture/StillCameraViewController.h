//
//  StillCameraViewController.h
//  Capture
//
//  Created by Gary  Barnett on 4/3/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StillRecordButton.h"
#import "MotionCircle.h"
#import "StillControlBarView.h"
#import "StillControllBarView2.h"

@interface StillCameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, StillRecordButtonDelegate, MotionCircleDelegate, StillControlBarViewDelegate, StillControlBarViewDelegate2>
@property (weak, nonatomic) IBOutlet StillControlBarView *controlBar;
@property (weak, nonatomic) IBOutlet StillControllBarView2 *controlBar2;


@end
