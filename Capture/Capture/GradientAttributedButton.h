//
//  GradientAttributedButton.h
//  Capture
//
//  Created by Gary Barnett on 9/4/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GradientAttributedButtonDelegate
-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag;
@end


@interface GradientAttributedButton : UIView

@property (nonatomic, strong) NSObject <GradientAttributedButtonDelegate> *delegate;

@property (nonatomic, assign) BOOL enabled;

-(void)setTitle:(NSAttributedString *)title disabledTitle:(NSAttributedString *)disabledTitle beginGradientColorString:(NSString *)bgGradientColorBegin endGradientColor:(NSString *)bgGradientColorEnd;
-(void)update;
@end
