//
//  AudioVolumeConfirmViewController.h
//  Capture
//
//  Created by Gary Barnett on 2/1/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioVolumeConfirmViewController : UIViewController <UIActionSheetDelegate, GradientAttributedButtonDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) AVURLAsset *clip;
@property (nonatomic, copy) NSArray *volList;

@end
