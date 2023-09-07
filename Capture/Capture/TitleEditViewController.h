//
//  TitleEditViewController.h
//  Capture
//
//  Created by Gary Barnett on 10/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPUserResizableView.h"
@interface TitleEditViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, GradientAttributedButtonDelegate, SPUserResizableViewDelegate, UITextViewDelegate>
@property (nonatomic, strong) NSString *pageToLoad;
@property (nonatomic, assign) BOOL isBeginTitle;
@end
