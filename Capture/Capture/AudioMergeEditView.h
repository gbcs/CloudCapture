//
//  AudioMergeEditView.h
//  Capture
//
//  Created by Gary Barnett on 1/29/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioMergeEditView : UIView
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CGFloat rampLength;
@property (nonatomic, assign) BOOL rampIn;
@property (nonatomic, assign) BOOL rampOut;
@property (nonatomic, assign) NSString *filename;

-(void)update;

@end
