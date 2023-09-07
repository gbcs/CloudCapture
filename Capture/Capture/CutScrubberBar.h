//
//  CutScrubberBar.h
//  Capture
//
//  Created by Gary Barnett on 9/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CutScrubberBarDelegate <NSObject>

-(void)userDidBeginScrubberPress;
-(void)userPressedScrubberAtSecond:(NSInteger)sec;
-(void)userDidEndScrubberPress;

@end

@interface CutScrubberBar : UIView
-(void)setDelegate:(NSObject <CutScrubberBarDelegate> *)scrubDelegate;
-(void)setDuration:(NSInteger)duration;
-(void)updatePosition:(NSInteger)second;
@end
