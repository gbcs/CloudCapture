//
//  StillControlBarView.h
//  Capture
//
//  Created by Gary  Barnett on 4/7/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StillControlBarViewDelegate <NSObject>
-(void)userStartedPressingRecordButton;
-(void)userStoppedPressingRecordButton;
-(void)userTappedExitButton;
-(void)userTappedOptionsButton;
-(void)userTappedPhotoButton;

@end

@interface StillControlBarView : UIView
@property (nonatomic, weak) IBOutlet NSObject <StillControlBarViewDelegate> *delegate;
@end
