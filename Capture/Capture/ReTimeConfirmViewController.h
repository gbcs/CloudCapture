//
//  ReTimeConfirmViewController.h
//  Capture
//
//  Created by Gary Barnett on 12/1/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReTimeConfirmViewController : UIViewController <UIActionSheetDelegate, GradientAttributedButtonDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) AVURLAsset *clip;
@property (nonatomic, copy) NSArray *cutList;
@property (nonatomic, assign) NSInteger naturalFrameRate;
@end

