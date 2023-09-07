//
//  ConfigureViewController.h
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfigureCellView.h"
#import "ConfigureDetailsView.h"
#import "ConfigureDetailsButtonView.h"
#import <MessageUI/MessageUI.h>
@interface ConfigureViewController : UIViewController <GradientAttributedButtonDelegate, UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate, ConfigureCellDelegate, ConfigureCellDetailDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, assign) BOOL launchForPurchase;
@property (nonatomic, assign) BOOL popInsteadOfNotificationForClose;
@end
