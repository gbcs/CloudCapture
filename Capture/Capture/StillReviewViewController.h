//
//  StillReviewViewController.h
//  Capture
//
//  Created by Gary  Barnett on 4/6/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GradientAttributedButton.h"

@interface StillReviewViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, GradientAttributedButtonDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) NSInteger reviewGroupIndex;
@end
