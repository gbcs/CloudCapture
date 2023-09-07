//
//  LinkShareViewController.h
//  Capture
//
//  Created by Gary Barnett on 1/31/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
 
@interface LinkShareViewController : UIViewController <GradientAttributedButtonDelegate>
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSDictionary *dict;
@end
