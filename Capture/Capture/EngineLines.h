//
//  EngineLines.h
//  Capture
//
//  Created by Gary Barnett on 7/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EngineLines : UIView
@property (nonatomic, copy) NSDictionary *positionDict;
@property (nonatomic, copy) NSDictionary *statusDict;
@property (nonatomic, assign) BOOL directMode;
@end
