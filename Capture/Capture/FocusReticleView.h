//
//  FocusReticleView.h
//  Capture
//
//  Created by Gary Barnett on 7/21/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FocusReticleView : UIView
@property (nonatomic, assign) BOOL locked;
-(void)update;
@end
