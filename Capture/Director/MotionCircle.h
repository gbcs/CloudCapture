//
//  MotionCircle.h
//  Cloud Director
//
//  Created by Gary  Barnett on 3/12/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MotionCircleDelegate <NSObject>
-(void)motionCircleCenterTapped:(id)sender;
-(void)deviceMotionStatusIsStill:(BOOL)still;
@end

@interface MotionCircle : UIView
@property (nonatomic, weak) IBOutlet NSObject <MotionCircleDelegate> *delegate;
-(void)setPitch:(CGFloat)p andYaw:(CGFloat )y  andRoll:(CGFloat )r;
@end
