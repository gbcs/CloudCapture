//
//  StillRecordButton.h
//  Capture
//
//  Created by Gary  Barnett on 4/5/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StillRecordButtonDelegate
-(void)userStartedPressingRecordButton;
-(void)userStoppedPressingRecordButton;
@end

@interface StillRecordButton : UIView
@property (nonatomic, weak) IBOutlet NSObject <StillRecordButtonDelegate> *delegate;
@end
