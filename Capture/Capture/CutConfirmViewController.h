//
//  CutConfirmViewController.h
//  Capture
//
//  Created by Gary Barnett on 9/9/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CutConfirmViewController : UIViewController <UIActionSheetDelegate, GradientAttributedButtonDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) AVURLAsset *clip;
@property (nonatomic, copy) NSArray *cutList;
@end
