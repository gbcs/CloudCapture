//
//  FixedTimelineView.h
//  Capture
//
//  Created by Gary Barnett on 12/30/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FixedTimelineVideoView : UIView
@property (nonatomic, assign) NSInteger index;

-(void)updateWithAsset:(AVAsset *)asset andPhotoDuration:(NSInteger )duration;
@end
