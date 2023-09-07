//
//  ExposureReticleView.h
//  Capture
//
//  Created by Gary Barnett on 7/21/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExposureReticleView : UIView
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) BOOL lockIsWhiteBalance;
-(void)update;
@end
