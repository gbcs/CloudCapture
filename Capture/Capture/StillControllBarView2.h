//
//  StillControllBarView2.h
//  Capture
//
//  Created by Gary  Barnett on 4/10/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StillControlBarViewDelegate2 <NSObject>
-(void)userTappedWhiteBalanceButton;
-(void)userTappedExposureButton;
-(void)userTappedFocusButton;
-(void)usertappedFlashButton;
@end

@interface StillControllBarView2 : UIView
@property (nonatomic, weak) IBOutlet NSObject <StillControlBarViewDelegate2> *delegate;
@end

