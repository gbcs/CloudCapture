//
//  GuidePane.h
//  Capture
//
//  Created by Gary Barnett on 7/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuidePane : UIView
@property (nonatomic, assign) BOOL thirdsEnabled;
@property (nonatomic, assign) int framingMode;
@property (nonatomic, assign) BOOL displayHorizon;

-(void)updateFramingGuideOffset:(CGFloat )offset;
@end
