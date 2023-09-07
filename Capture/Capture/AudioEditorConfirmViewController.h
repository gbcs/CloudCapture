//
//  AudioEditorConfirmViewController.h
//  Capture
//
//  Created by Gary Barnett on 12/23/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioEditorConfirmViewController : UIViewController <UIActionSheetDelegate, GradientAttributedButtonDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) AVURLAsset *clip;
@property (nonatomic, copy) NSArray *cutList;

@end
