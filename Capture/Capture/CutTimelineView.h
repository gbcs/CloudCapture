//
//  CutTimelineView.h
//  Capture
//
//  Created by Gary Barnett on 9/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CutTimelineView : UIView
@property (nonatomic, assign) NSInteger seconds;
@property (nonatomic, assign) CGSize thumbSize;
@property (nonatomic, assign) float centeringOffset;
@property (nonatomic, assign) NSInteger centerSecond;
@end
