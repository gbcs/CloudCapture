//
//  AudioWaveformView.h
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioWaveformView : UIView
@property (nonatomic, assign) NSMutableArray *entryList;
-(void)update;
-(void)cleanup;
@end
