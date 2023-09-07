//
//  LabeledButton.h
//  Capture
//
//  Created by Gary Barnett on 7/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabeledButton : UIView
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, copy) UIColor *buttonColor;
@property (nonatomic, copy) NSString *notifyStringUp;
@property (nonatomic, copy) NSString *notifyStringDown;
@property (nonatomic, assign) BOOL enabled;
-(void)justify:(NSInteger)j;
@end
