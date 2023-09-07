//
//  ConfigureViewController.m
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ConfigureViewController.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "HelpViewController.h"
#import "PurchaseObject.h"
#import <StoreKit/StoreKit.h>


@interface ConfigureViewController () {
    IBOutlet UICollectionView *colView;
    
    
    UIBarButtonItem *progressButton;
    UIView *progressContainer;
    UIBarButtonItem *closeButton;
    UIBarButtonItem *rateButton;
   
    NSArray *leftHandButtons;
    
    NSInteger selected;
    NSInteger selectedTag;
    UIView *pageView;
    UIView *oldPageView;
    
    UIDynamicAnimator *cellAnimator;
    UIDynamicAnimator *oldAnimator;
    UIDynamicAnimator *detailAnimator;
    ConfigureDetailsView *detailView;
    ConfigureDetailsButtonView *detailButtonView;

    __weak IBOutlet UIView *animatorPane;
    
    CLLocationManager *locationManager;
    
    NSInteger waitCount;
    
    PurchaseObject *purchaseObject;
    
    UIView *albumPickView;
    
    BOOL firstPageShown;
}

@end

@implementation ConfigureViewController

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
    NSLog(@"%@:%s", [self class], __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    colView = nil;
    progressButton = nil;
    progressContainer = nil;
    closeButton = nil;
    rateButton = nil;
    leftHandButtons = nil;
    pageView = nil;
    oldPageView = nil;
    cellAnimator = nil;
    oldAnimator = nil;
    detailAnimator = nil;
    detailView = nil;
    detailButtonView = nil;
    animatorPane = nil;
    locationManager = nil;
    purchaseObject = nil;
    albumPickView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupPurchaseObject];
    
   
    rateButton = [[UIBarButtonItem alloc] initWithTitle:@"Rate This App" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedRateButton:)];
    self.navigationController.toolbarHidden = YES;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.opaque = YES;
    
    progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0,0,140,30)];
    progressContainer.backgroundColor = [UIColor clearColor];
    progressButton = [[UIBarButtonItem alloc] initWithCustomView:progressContainer];
    
    closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose:)];
  
    animatorPane.backgroundColor = [UIColor clearColor];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.preferredContentSize = CGSizeMake(568,276);
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hasPaidUpdate) name:@"hasPaidUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];

}

-(void)hasPaidUpdate {
    if (selected == 0) {
        [self userPressedGradientAttributedButtonWithTag:0];
    }
}

-(void)userTappedHelpButton:(id)sender {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"launchForHelp" object:nil];
        
    } else {
        HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
        configureVC.backOnly = YES;
        [self.navigationController pushViewController:configureVC animated:YES];
    }
}


-(void)userTappedCellWithTag:(NSInteger) tag {
    if (albumPickView) {
        return;
    }

    
    selectedTag = tag;
    if (selected == 1) { //privacy
        switch (tag) {
            case 0:
            {
                [self presentDetailsView];
                [detailView useDetails:@{ @"title" : @"Microphone",
                                          @"description" : @"Access to the microphone is controlled in the Settings app. Press the home button, find and open the settings app, then navigate to Privacy and then Microphone. Here you will find Cloud Capture listed with a switch allowing access when On."
                                         } andDelegate:self];
            
            }
                break;
            case 1:
            {
                [self presentDetailsView];
                [detailView useDetails:@{ @"title" : @"Photo Album and Camera Roll",
                                          @"description" : @"Access to the camera roll and photo album(s) is controlled in the Settings app. Press the home button, find and open the settings app, then navigate to Privacy and then Photos. Here you will find Cloud Capture listed with a switch allowing access when On."
                                          } andDelegate:self];
            }
                break;
            case 2:
            {
                if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                    [self presentDetailsButtonView];
                    [detailView useDetails:@{ @"title" : @"Location",
                                              @"description" : @"Request that location access be granted for this app.",
                                              @"button1" : @{ @"title" : @"Request" , @"tag" : @1 },
                                              @"button2" : @{ @"title" : @"Close" , @"tag" : @2}
                                              } andDelegate:self];

                } else { //granted, denied or restricted
                    [self presentDetailsView];
                    [detailView useDetails:@{ @"title" : @"Location",
                                              @"description" : @"Access to the device location is controlled in the Settings app. Press the home button, find and open the settings app, then navigate to Privacy and then Location Services. Here you will find Cloud Capture listed with a switch allowing access when On."
                                              } andDelegate:self];

                }
                
                
                
            }
                break;
        }
    } else if (selected == 2) {
        switch (tag) {
            case 0:
            {
                 [self presentDetailsButtonView];
                [detailView useDetails:@{ @"title" : @"Clip Storage Location",
                                          @"description" : @"Clips are recorded to files in the app's working area and appear in the Library view. Once recorded, clips may be moved to the camera roll to enable access from other applications.",
                                          @"button1" : @{ @"title" : @"Move to Camera Roll" , @"tag" :@1 },
                                          @"button2" : @{ @"title" : @"Keep in App Library" , @"tag" : @2}
                                          } andDelegate:self];

                
            }
                break;
                
            case 1:
            {
                [self presentDetailsButtonView];
                [detailView useDetails:@{ @"title" : @"Move Recorded Clips",
                                          @"description" : @"Move clips to the camera roll/photo album immediately after recording or wait until the library window is opened.",
                                          @"button1" : @{ @"title" : @"Move Immediately" , @"tag" : @1 },
                                          @"button2" : @{ @"title" : @"Wait For Library" , @"tag" : @2}
                                          } andDelegate:self];
                
                
                
            }
                break;
            case 2:
            {
                 [self presentDetailsButtonView];
                [detailView useDetails:@{ @"title" : @"Record GPS Location",
                                          @"description" : @"Store Location information in recorded clip metadata.",
                                          @"button1" : @{ @"title" : @"Store" , @"tag" : @1 },
                                          @"button2" : @{ @"title" : @"Do Not Store" , @"tag" : @2}
                                          } andDelegate:self];
                
                
                
            }
                break;
         
        }
    } else if (selected == 3) {
        switch (tag) {
            case 0:
            {
                [self presentDetailsButtonView];
              
                NSInteger length = [[SettingsTool settings] hideUserInterface];
                NSString *descText = @"The user interface will not hide.";
                if (length > 0) {
                    NSInteger min = length / 60;
                    NSInteger sec = length - (min * 60);
                    
                    descText = [NSString stringWithFormat:@"The user interface will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec];
                }
                
                [detailView useDetails:@{ @"title" : @"Interface Visibility",
                                          @"description" :  descText,
                                          @"button1" : @{ @"title" : @"Second -" , @"tag" : @1 },
                                          @"button2" : @{ @"title" : @"Minute -" , @"tag" : @2 },
                                          @"button3" : @{ @"title" : @"Done" , @"tag" : @3 },
                                          @"button4" : @{ @"title" : @"Second +" , @"tag" : @4 },
                                          @"button5" : @{ @"title" : @"Minute +" , @"tag" : @5 },
                                          @"button6" : @{ @"title" : @"Disable" , @"tag" : @6 }
                                          } andDelegate:self];
                
                
            }
                break;
            case 1:
            {
                [self presentDetailsButtonView];
                
                NSInteger length = [[SettingsTool settings] hidePreview];
                NSString *descText = @"The preview will not hide.";
                if (length > 0) {
                    NSInteger min = length / 60;
                    NSInteger sec = length - (min * 60);
                    
                    descText = [NSString stringWithFormat:@"The preview will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec];
                }

                
                [detailView useDetails:@{ @"title" : @"Preview Visibility",
                                          @"description" :descText,
                                          @"button1" : @{ @"title" : @"Second -" , @"tag" : @1 },
                                          @"button2" : @{ @"title" : @"Minute -" , @"tag" : @2 },
                                          @"button3" : @{ @"title" : @"Done" , @"tag" : @3 },
                                          @"button4" : @{ @"title" : @"Second +" , @"tag" : @4 },
                                          @"button5" : @{ @"title" : @"Minute +" , @"tag" : @5 },
                                          @"button6" : @{ @"title" : @"Disable" , @"tag" : @6 }
                                          } andDelegate:self];
                
            }
                break;
            case 2:
            {
                [self presentDetailsButtonView];
                [detailView useDetails:@{ @"title" : @"Zoom Bar Location",
                                          @"description" : @"Select the location of the zoom bar.",
                                          @"button1" : @{ @"title" : @"Hidden" , @"tag" : @1 },
                                          @"button2" : @{ @"title" : @"Left" , @"tag"   : @2 },
                                          @"button3" : @{ @"title" : @"Right" , @"tag"  : @3 }
                                          } andDelegate:self];
                
            }
                break;
        }
        
    } else if (selected == 4) {
        
        switch (tag) {
            case 0:
            {
                [self userTappedHelpButton:nil];
            }
                break;
            case 1:
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://cloudcapt.com/"]];
            }
                break;
            case 2:
            {
                AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                
                if (![MFMailComposeViewController canSendMail]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email" message:@"Email is not currently available on this device.  Please send a request to support@cloudcapt.com for help." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    return;
                }
                
                MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
                composer.mailComposeDelegate = self;
                [composer setSubject:@"CloudCapt 1.2 Help Request"];
         
                NSArray *toRecipients=[NSArray arrayWithObject:@"support@cloudcapt.com"];
                [composer setToRecipients:toRecipients];
                
                [appD.rootController presentViewController:composer animated:YES completion:^{
                    
                }];
            }
                break;
            case 3:
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://cloudcapt.com/"]];
            }
                break;
        
            case 4:
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.mediacollege.com/video/camera/tutorial/"]];
            }
                break;
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sendEmailThankYouResponse" object:@(result)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"resetAfterModalDialog" object:nil];
    }];
}


-(void)userTappedCellWithAction:(NSInteger)action {
   
    if ( (selected == 1) && (selectedTag == 2) && (action == 1) ) {
        locationManager = [[CLLocationManager alloc] init];
        [locationManager startUpdatingLocation];
        [[SettingsTool settings] setUseGPS:YES];
        return;
    } else if (selected == 2) {
        switch (selectedTag) {
            case 0:
            {
                [[SettingsTool settings] setClipStorageLibrary:(action == 2)];
            }
                break;
            case 2:
            {
                [[SettingsTool settings] setClipRecordLocation:(action == 1)];
            }
                break;
            case 1:
            {
                [[SettingsTool settings] setClipMoveImmediately:(action == 1)];
            }
                break;
        }
    } else if (selected == 3) {
        switch (selectedTag) {
            case 0:
            {
                switch (action) {
                    case 4:
                    {
                        NSInteger length = [[SettingsTool settings] hideUserInterface];
                        length += 1;
                        [[SettingsTool settings] setHideUserInterface:length];
                        NSInteger min = length / 60;
                        NSInteger sec = length - (min * 60);
                        [detailView updateDescLabel:[NSString stringWithFormat:@"The user interface will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                    }
                        break;
                    case 5:
                    {
                        NSInteger length = [[SettingsTool settings] hideUserInterface];
                        length += 60;
                        [[SettingsTool settings] setHideUserInterface:length];
                        NSInteger min = length / 60;
                        NSInteger sec = length - (min * 60);
                        [detailView updateDescLabel:[NSString stringWithFormat:@"The user interface will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                    }
                        break;
                    case 1:
                    {
                        NSInteger length = [[SettingsTool settings] hideUserInterface];
                        length -= 1;
                        if (length <0) {
                            length = 0;
                        }
                        [[SettingsTool settings] setHideUserInterface:length];
                        if (length == 0) {
                            [detailView updateDescLabel:@"The user interface will not hide."];
                        } else {
                            NSInteger min = length / 60;
                            NSInteger sec = length - (min * 60);
                            [detailView updateDescLabel:[NSString stringWithFormat:@"The user interface will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                        }

                    }
                        break;
                    case 2:
                    {
                        NSInteger length = [[SettingsTool settings] hideUserInterface];
                        length -= 60;
                        if (length <0) {
                            length = 0;
                        }
                        [[SettingsTool settings] setHideUserInterface:length];
                        if (length == 0) {
                            [detailView updateDescLabel:@"The user interface will not hide."];
                        } else {
                            NSInteger min = length / 60;
                            NSInteger sec = length - (min * 60);
                            [detailView updateDescLabel:[NSString stringWithFormat:@"The user interface will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                        }
                    }
                        break;
                    case 6:
                    {
                        [[SettingsTool settings] setHideUserInterface:0];
                    }
                        break;
                }
                if ( (action != 3) && (action != 6) ) {
                    return; //avoid detail drop
                }
            }
                break;
            case 1:
            {
                switch (action) {
                    case 4:
                    {
                        NSInteger length = [[SettingsTool settings] hidePreview];
                        length += 1;
                        [[SettingsTool settings] setHidePreview:length];
                        NSInteger min = length / 60;
                        NSInteger sec = length - (min * 60);
                        [detailView updateDescLabel:[NSString stringWithFormat:@"The preview will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                    }
                        break;
                    case 5:
                    {
                        NSInteger length = [[SettingsTool settings] hidePreview];
                        length += 60;
                        [[SettingsTool settings] setHidePreview:length];
                        NSInteger min = length / 60;
                        NSInteger sec = length - (min * 60);
                        [detailView updateDescLabel:[NSString stringWithFormat:@"The preview will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                    }
                        break;
                    case 1:
                    {
                        NSInteger length = [[SettingsTool settings] hidePreview];
                        length -= 1;
                        if (length <0) {
                            length = 0;
                        }
                        [[SettingsTool settings] setHidePreview:length];
                        if (length == 0) {
                            [detailView updateDescLabel:@"The preview will not hide."];
                        } else {
                            NSInteger min = length / 60;
                            NSInteger sec = length - (min * 60);
                            [detailView updateDescLabel:[NSString stringWithFormat:@"The preview  will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                        }
                        
                    }
                        break;
                    case 2:
                    {
                        NSInteger length = [[SettingsTool settings] hidePreview];
                        length -= 60;
                        if (length <0) {
                            length = 0;
                        }
                        [[SettingsTool settings] setHidePreview:length];
                        if (length == 0) {
                            [detailView updateDescLabel:@"The preview will not hide."];
                        } else {
                            NSInteger min = length / 60;
                            NSInteger sec = length - (min * 60);
                            [detailView updateDescLabel:[NSString stringWithFormat:@"The preview will be hidden after %02ld:%02ld of inactivity.", (long)min, (long)sec]];
                        }
                    }
                        break;
                    case 6:
                    {
                        [[SettingsTool settings] setHidePreview:0];
                    }
                        break;
                }
                if ( (action != 3) && (action != 6) ) {
                    return; //avoid detail drop
                }
            }
                break;
            case 2:
            {
                [[SettingsTool settings] setZoomBarLocation:action-1];
            }
                break;
        }
    } else if (selected == 4) {
    
    }
    
    if (detailAnimator) {
        [detailAnimator removeAllBehaviors];
        
        NSArray *items = @[ detailView ];
        if (albumPickView) {
            items = @[ detailView, albumPickView ];
        }
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:items];
        [detailAnimator addBehavior:gravity];
       
        [self performSelector:@selector(finishDetailAnimation) withObject:nil afterDelay:2.0];
        [self userPressedGradientAttributedButtonWithTag:selected];
        albumPickView = nil;
    }
    
   
}



-(void)finishDetailAnimation {
    [detailAnimator removeAllBehaviors];
    [detailView removeFromSuperview];
    detailView = nil;
    detailAnimator = nil;
    //[self enableButtons];
}

-(void)presentDetailsView {
    
    [self disableButtons];
    
    CGFloat width = self.view.frame.size.width - 120 - 100;
    
    CGRect f = CGRectMake(120 + 50, -320, width, 250);
    
    detailView = [[ConfigureDetailsView alloc] initWithFrame:f];
    [detailView useDetails:@{ @"title" : @"", @"description" : @""} andDelegate:self];

    [animatorPane addSubview:detailView];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[detailView]];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[detailView]];
   
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, 320) toPoint:CGPointMake(animatorPane.bounds.size.width, 320)];
    
    detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:animatorPane];
    [detailAnimator addBehavior:gravity];
    [detailAnimator addBehavior:collision];
    
}

-(void)presentDetailsButtonView {
    
    [self disableButtons];
    
    CGFloat width = self.view.frame.size.width - 120 - 100;
    
    CGRect f = CGRectMake(120 + 50, -320, width, 250);
    
    detailView = [[ConfigureDetailsButtonView alloc] initWithFrame:f];
    [detailView useDetails:@{ @"title" : @"", @"description" : @""} andDelegate:self];
    
    [animatorPane addSubview:detailView];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[detailView]];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[detailView]];
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, 320) toPoint:CGPointMake(animatorPane.bounds.size.width, 320)];
    
    detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:animatorPane];
    [detailAnimator addBehavior:gravity];
    [detailAnimator addBehavior:collision];
    
}

-(void)updateButtons {
    if (leftHandButtons) {
        for (GradientAttributedButton *button in leftHandButtons) {
            button.delegate = nil;
            [button removeFromSuperview];
        }
        leftHandButtons = nil;
    }
    
    NSMutableArray *l = [[NSMutableArray alloc] initWithCapacity:4];
    
    
    
    [l addObject:[self buttonWithSetup:@{ @"tag" : @0,
                                          @"selected" : [NSNumber numberWithBool:(selected == 0)],
                                          @"text" : @"About",
                                          @"frame" : [NSValue valueWithCGRect:CGRectMake(5,40+5,105,50)]
                                          }]];

    
    [l addObject:[self buttonWithSetup:@{ @"tag" : @1,
                                          @"selected" : [NSNumber numberWithBool:(selected == 1)],
                                          @"text" : @"Permissions",
                                          @"frame" : [NSValue valueWithCGRect:CGRectMake(5,85+15,105,50)]
                                          }]];
    
    [l addObject:[self buttonWithSetup:@{  @"tag" : @2,
                                           @"selected" : [NSNumber numberWithBool:(selected == 2)],
                                           @"text" : @"Clips",
                                           @"frame" : [NSValue valueWithCGRect:CGRectMake(5,130+25,105,50)]
                                           }]];
    
    [l addObject:[self buttonWithSetup:@{ @"tag" : @3,
                                          @"selected" : [NSNumber numberWithBool:(selected == 3)],
                                          @"text" : @"Interface",
                                          @"frame" : [NSValue valueWithCGRect:CGRectMake(5,175+35,105,50)]
                                          }]];
    
    [l addObject:[self buttonWithSetup:@{  @"tag" : @4,
                                           @"selected" : [NSNumber numberWithBool:(selected == 4)],
                                           @"text" : @"Help and Support",
                                           @"frame" : [NSValue valueWithCGRect:CGRectMake(5,220+45,105,50)]
                                           }]];

    
    leftHandButtons = [l copy];
    
    for (GradientAttributedButton *b in leftHandButtons) {
        [self.view addSubview:b];
    }
    
    [self.view sendSubviewToBack:animatorPane];
}



-(GradientAttributedButton *)buttonWithSetup:(NSDictionary *)setup {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    NSAttributedString *activeText = [[NSAttributedString alloc] initWithString:[setup objectForKey:@"text"] attributes:@{
                                                                                                                          NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                                          NSShadowAttributeName : shadow,
                                                                                                                          NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                                          }];
    
    
    NSAttributedString *inactiveText = [[NSAttributedString alloc] initWithString:[setup objectForKey:@"text"]  attributes:@{
                                                                                                                             NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                                             NSShadowAttributeName : shadow,
                                                                                                                             NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                                             }];
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:[[setup objectForKey:@"frame"] CGRectValue]];
    button.delegate = self;
    
    button.tag = [[setup objectForKey:@"tag"] integerValue];
    
    if ([[setup objectForKey:@"selected"] boolValue]) {
        [button setTitle:activeText disabledTitle:activeText beginGradientColorString:@"#006600" endGradientColor:@"#003300"];
    } else {
        [button setTitle:inactiveText disabledTitle:inactiveText beginGradientColorString:@"#666666" endGradientColor:@"#333333"];
    }
    
    button.enabled = YES;
    [button update];
    
    return button;
}

-(void)disableButtons {
        // NSLog(@"Buttons Disabled");
    for (GradientAttributedButton *b in leftHandButtons) {
        b.enabled = NO;
    }
}

-(void)enableButtons {
        //NSLog(@"Buttons Enabled");
    for (GradientAttributedButton *b in leftHandButtons) {
        b.enabled = YES;
    }
}

-(void)setupPurchaseObject {
    if (!purchaseObject) {
        purchaseObject = [[PurchaseObject alloc] init];
        [purchaseObject setup];
    }
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
        // NSLog(@"userPressedGradientAttributedButtonWithTag:%ld", (long)tag);
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    if ( (tag == 1000) || (tag == 1001) || (tag == 1002) ) {
        switch (tag) {
            case 1000: //buy
            {
                [[UtilityBag bag] buyApp];
                
                /*
                // NSLog(@"Get Button");
    
                SKProduct *product = [purchaseObject product];
                if (!product) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Problem" message:@"Unable to contact the App Store. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                        
                    });
                    return;
                }
                
                if (![SKPaymentQueue canMakePayments]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Payment Problem" message:@"Your device is unable to make payments at this time." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                      
                    });
                    return;
                }
               
                [self presentDetailsView];
                [detailView useDetails:@{ @"title" : [NSString stringWithFormat:@"%@", product.localizedTitle],
                                          @"description" : [NSString stringWithFormat:@"%@", product.localizedDescription],
                                          } andDelegate:self];
                
              
                UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,55,detailView.frame.size.width, 40)];
                priceLabel.font = [UIFont boldSystemFontOfSize:24];
                
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                [numberFormatter setLocale:product.priceLocale];
    
                priceLabel.text = [numberFormatter stringFromNumber:product.price];
                priceLabel.textColor = [UIColor blackColor];
                priceLabel.textAlignment = NSTextAlignmentCenter;
                [detailView addSubview:priceLabel];
                
                GradientAttributedButton *buyButton = [self buttonWithSetup:@{ @"tag" : @1002,
                                                          @"selected" : @YES,
                                                          @"text" : @"Buy",
                                                                               @"frame" : [NSValue valueWithCGRect:CGRectMake((detailView.frame.size.width / 2.0f) - 100, 190, 200, 50)]
                                                          }];
                buyButton.delegate = self;
                [detailView addSubview:buyButton];
                 */
                
                return;
            }
                break;
            case 1001: //restore purchase
            {
                    // NSLog(@"Restore");
                [purchaseObject restorePurchases];
                return;
            }
                break;
            case 1002: //buy
            {
                    //NSLog(@"Buy");
                SKProduct *product = [purchaseObject product];
                [purchaseObject purchaseProduct:product];
                return;
            }
                break;
        }
    } else {
        selected = tag;
        
        [self updateButtons];
        [self disableButtons];
        
        if (pageView) {
            oldPageView = pageView;
            pageView = nil;
            oldAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:animatorPane];
            [oldAnimator removeAllBehaviors];
            UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ oldPageView]];
            [oldAnimator addBehavior:gravity];
        }
        
        if (detailView) {
            [detailAnimator removeAllBehaviors];
            
            NSArray *items = @[ detailView ];
            if (albumPickView) {
                items = @[ detailView, albumPickView ];
            }
            UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:items];
            [detailAnimator addBehavior:gravity];
            
            [self performSelector:@selector(finishDetailAnimation) withObject:nil afterDelay:2.0];
        }
        
        CGSize cellSize = CGSizeMake(116,120);
        if ([[SettingsTool settings] isiPhone4S]) {
            cellSize = CGSizeMake(110,120);
        }
        ConfigureCellView *cell = nil;
        
        pageView = [[UIView alloc] init];
        
        switch (tag) {
            case 0:
            {
                pageView = [self makeAboutView];
                pageView.frame = CGRectMake(pageView.frame.origin.x,-320,pageView.frame.size.width, 270);
                
            }
                break;
            case 1:
            {
                
                pageView = [[UIView alloc] initWithFrame:CGRectMake(0,-320,animatorPane.bounds.size.width,250)];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:0 cellSize:cellSize]];
                cell.tag = 0;
                cell.delegate = self;
                cell.category = tag;
                
                NSString *microphoneStr = appD.audioRecordingAllowed ? @"Access Granted" : @"Access Denied";
                
                [pageView addSubview:cell];
                [cell useDetails:@{ @"title" : @"Microphone\n " , @"description" : microphoneStr, @"icon" : @"microphone_30", @"selected" : @NO } andDelegate:self];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:1 cellSize:cellSize]];
                cell.tag = 1;
                cell.delegate = self;
                cell.category = tag;
                
                NSString *photoDescription = @"";
                switch ([ALAssetsLibrary authorizationStatus]) {
                    case ALAuthorizationStatusNotDetermined:
                    {
                        photoDescription = @"Waiting for permission.";
                    }
                        break;
                    case ALAuthorizationStatusRestricted:
                    {
                        photoDescription = @"Access is restricted.";
                    }
                        break;
                    case ALAuthorizationStatusDenied:
                    {
                        photoDescription = @"Access is denied.";
                    }
                        break;
                    case ALAuthorizationStatusAuthorized:
                    {
                        photoDescription = @"Access granted";
                    }
                        break;
                }
                
                [pageView addSubview:cell];
                [cell useDetails:@{ @"title" : @"Photo Library\n " , @"description" : photoDescription, @"icon" : @"film_reel", @"selected" : @NO } andDelegate:self];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:2 cellSize:cellSize]];
                cell.tag = 2;
                cell.delegate = self;
                cell.category = tag;
                
                NSString *locationDescription = @"";
                switch ([CLLocationManager authorizationStatus]) {
                    case kCLAuthorizationStatusNotDetermined:
                    {
                        locationDescription = @"Waiting for permission";
                    }
                        break;
                    case kCLAuthorizationStatusRestricted:
                    {
                        locationDescription = @"Access is restricted";
                    }
                        break;
                    case kCLAuthorizationStatusDenied:
                    {
                        locationDescription = @"Access is denied";
                    }
                        break;
                    case kCLAuthorizationStatusAuthorized:
                    {
                        locationDescription = @"Access granted";
                    }
                        break;
                }
                
                
                
                [pageView addSubview:cell];
                [cell useDetails:@{ @"title" : @"Location\n " , @"description" : locationDescription, @"icon" : @"74-location", @"selected" : @NO } andDelegate:self];
            
            }
                break;
            case 2: //clips
            {
                
                pageView = [[UIView alloc] initWithFrame:CGRectMake(0,-320,animatorPane.bounds.size.width,250)];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:0 cellSize:cellSize]];
                cell.tag = 0;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                BOOL useLibary = [[SettingsTool settings] clipStorageLibrary];
                
                [cell useDetails:@{ @"title" : @"Clip Storage\nLocation" , @"description" : useLibary ? @"App Library" : @"Camera Roll", @"icon" : @"", @"selected" : @NO } andDelegate:self];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:2 cellSize:cellSize]];
                cell.tag = 2;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
        
                BOOL storeLoc = [[SettingsTool settings] clipRecordLocation];
                
                [cell useDetails:@{ @"title" : @"Record GPS Location" , @"description" : storeLoc ? @"Enabled" : @"Disabled", @"image" : @"", @"selected" : @NO } andDelegate:self];
        
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:1 cellSize:cellSize]];
                cell.tag = 1;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                BOOL moveImmediately = [[SettingsTool settings] clipMoveImmediately];
                
                [cell useDetails:@{ @"title" : @"Move Recorded Clips" , @"description" : moveImmediately ? @"Move After Each Recording" : @"Move when Library opened", @"image" : @"", @"selected" : @NO } andDelegate:self];
         

            }
                break;
            case 3: //UI
            {
                
                pageView = [[UIView alloc] initWithFrame:CGRectMake(0,-320,animatorPane.bounds.size.width,250)];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:0 cellSize:cellSize]];
                cell.tag = 0;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                
                NSInteger length = [[SettingsTool settings] hideUserInterface];
                NSString *descText = @"Always On";
                if (length > 0) {
                    NSInteger min = length / 60;
                    NSInteger sec = length - (min * 60);
                    
                    descText = [NSString stringWithFormat:@"Hides after %02ld:%02ld.", (long)min, (long)sec];
                }
                
                
                [cell useDetails:@{ @"title" : @"Interface Visibility" , @"description" : descText, @"icon" : @"", @"selected" : @NO } andDelegate:self];
                
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:1 cellSize:cellSize]];
                cell.tag = 1;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                descText = @"Always On";
                length = [[SettingsTool settings] hidePreview];
                if (length > 0) {
                    NSInteger min = length / 60;
                    NSInteger sec = length - (min * 60);
                    descText = [NSString stringWithFormat:@"Hides after %02ld:%02ld.", (long)min, (long)sec];
                }
                
                
                [cell useDetails:@{ @"title" : @"Preview Visibility" , @"description" : descText , @"icon" : @"", @"selected" : @NO } andDelegate:self];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:2 cellSize:cellSize]];
                cell.tag = 2;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                NSString *barLocStr = @"Hidden";
                NSInteger barLoc = [[SettingsTool settings] zoomBarLocation];
                if (barLoc == 1) {
                    barLocStr = @"Left";
                } else if (barLoc == 2) {
                    barLocStr = @"Right";
                }
                
                [cell useDetails:@{ @"title" : @"Zoom Bar Location" , @"description" : barLocStr, @"icon" : @"", @"selected" : @NO } andDelegate:self];
  
            }
                break;
                
            case 4: //support
            {
                
                pageView = [[UIView alloc] initWithFrame:CGRectMake(0,-320,animatorPane.bounds.size.width,250)];
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:0 cellSize:cellSize]];
                cell.tag = 0;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                [cell useDetails:@{ @"title" : @"Documentation" , @"description" : @"Complete documentation in PDF format.", @"icon" : @"", @"selected" : @NO , @"largeDetailTextArea" : @(YES), @"tapStr" : @"Tap To Read" } andDelegate:self];
                
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:1 cellSize:cellSize]];
                cell.tag = 1;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                [cell useDetails:@{ @"title" : @"CloudCapt Website" , @"description" : @"FAQs and Support" , @"icon" : @"", @"selected" : @NO, @"largeDetailTextArea" : @(YES) , @"tapStr" : @"Tap To View" } andDelegate:self];
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x1CellForIndex:2 cellSize:cellSize]];
                cell.tag = 2;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
    
                [cell useDetails:@{ @"title" : @"Ask For Help" , @"description" : @"Ask the developer for assistance.", @"icon" : @"", @"selected" : @NO, @"largeDetailTextArea" : @(YES), @"tapStr" : @"Tap To Email" } andDelegate:self];
                
                /*
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x2CellForIndex:3 cellSize:cellSize]];
                cell.tag = 3;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                [cell useDetails:@{ @"title" : @"Cloud Capture Video" , @"description" : @"Instructional videos using Cloud Capture", @"icon" : @"", @"selected" : @NO , @"largeDetailTextArea" : @(YES), @"tapStr" : @"Tap To View"} andDelegate:self];
                
                
                cell = [[ConfigureCellView alloc] initWithFrame:[self locate3x2CellForIndex:4 cellSize:cellSize]];
                cell.tag = 4;
                cell.delegate = self;
                cell.category = tag;
                [pageView addSubview:cell];
                
                [cell useDetails:@{ @"title" : @"Video Camera Tutorials" , @"description" : @"View tutorials at MediaCollege.com" , @"icon" : @"", @"selected" : @NO, @"largeDetailTextArea" : @(YES), @"tapStr" : @"Tap To View" } andDelegate:self];
                */
                
            
            }
                break;
        }
        
        [animatorPane addSubview:pageView];
        
        cellAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:animatorPane];
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[pageView]];
        [cellAnimator addBehavior:gravity];
        
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[pageView]];
        [collision setCollisionMode:UICollisionBehaviorModeBoundaries];
        [collision addBoundaryWithIdentifier:@"bottom"   fromPoint:CGPointMake(0, 320 ) toPoint:CGPointMake(animatorPane.bounds.size.width,320)];
        
        [cellAnimator addBehavior:collision];
        
        [self performSelector:@selector(finishAnimation) withObject:nil afterDelay:2.0];
    }
    
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}


-(void)finishAnimation {
        //NSLog(@"finish animation");
    [oldAnimator removeAllBehaviors];
    oldAnimator = nil;
    [oldPageView removeFromSuperview];
    oldPageView = nil;
    
    [cellAnimator removeAllBehaviors];
    cellAnimator = nil;
    
    [self enableButtons];
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator*)animator {
        //NSLog(@"animator resumed");
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator*)animator {
        // NSLog(@"animator paused");
}

- (IBAction)userTappedClose:(id)sender {
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    [[LocationHandler tool] startup];
    [self performSelector:@selector(cleanup:) withObject:nil afterDelay:0.4];
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)userTappedCredits:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self presentDetailsView];
        [detailView useDetails:@{ @"title" : @"Code Credits",
                                  @"description" : @"GPUImage - Post-filters, OpenSSL-for-iPhone - Receipt validation, SPUserResizableView - Sizable widget, Google Youtube SDK, GSDropboxActivity - Dropbox UI, Dropbox SDK, SSKeychain - Secure Storage, Daily Motion SDK, Amazon AWS SDK, Azure SDK, Galileo SDK\nThank you"
                                  } andDelegate:self];
        

    }
}

-(UIView *)makeAboutView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(120,50,self.view.frame.size.width - 120, 270)];
    
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,v.bounds.size.width, 90)];
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.textColor = [UIColor whiteColor];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.lineBreakMode  = NSLineBreakByWordWrapping;
    statusLabel.font = [UIFont fontWithName:@"LiquidCrystal-Bold" size:36];
    statusLabel.numberOfLines = 0;
    statusLabel.text = @"CloudCapt Camera and Edit Studio";
    [v addSubview:statusLabel];
    
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,90,v.bounds.size.width, 30)];
    versionLabel.backgroundColor = [UIColor clearColor];
    versionLabel.textColor = [UIColor whiteColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.font = [[[UtilityBag bag] standardFont] fontWithSize:15];
    versionLabel.numberOfLines = 1;
    versionLabel.text = [NSString stringWithFormat:@"v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    [v addSubview:versionLabel];
    
    UILabel *creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(v.bounds.size.width - 100,v.bounds.size.height - 30,100, 30)];
    creditLabel.backgroundColor = [UIColor clearColor];
    creditLabel.textColor = [UIColor whiteColor];
    creditLabel.textAlignment = NSTextAlignmentCenter;
    creditLabel.font = [[[UtilityBag bag] standardFont] fontWithSize:15];
    creditLabel.numberOfLines = 1;
    creditLabel.text = @"Credits";
    creditLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedCredits:)];
    [creditLabel addGestureRecognizer:tapG];
    [v addSubview:creditLabel];
    
    
    UILabel *purchaseLabel = nil;
    GradientAttributedButton *purchaseButton = nil;
    GradientAttributedButton *restorePurchaseButton = nil;
    
    if ([[SettingsTool settings] hasPaid]) {
        purchaseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,140,v.bounds.size.width, 30)];
        purchaseLabel.backgroundColor = [UIColor clearColor];
        purchaseLabel.textColor = [UIColor whiteColor];
        purchaseLabel.textAlignment = NSTextAlignmentCenter;
        purchaseLabel.font = [[[UtilityBag bag] standardFont] fontWithSize:15];
        purchaseLabel.numberOfLines = 1;
#ifdef CCFREE
        purchaseLabel.text = @"Paid Version (Thank You)";
#endif
#ifdef CCPRO
        purchaseLabel.text = @"Paid Version (Thank You)";
#endif
        [v addSubview:purchaseLabel];
    } else {
        purchaseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,140,v.bounds.size.width, 30)];
        purchaseLabel.backgroundColor = [UIColor clearColor];
        purchaseLabel.textColor = [UIColor whiteColor];
        purchaseLabel.textAlignment = NSTextAlignmentCenter;
        purchaseLabel.font = [[[UtilityBag bag] standardFont] fontWithSize:15];
        purchaseLabel.numberOfLines = 1;

#ifdef CCFREE
        purchaseLabel.text = @"Free Version";


        [v addSubview:purchaseLabel];
        
        CGFloat midX = v.bounds.size.width / 2.0f;
        
        purchaseButton = [self buttonWithSetup:@{ @"tag" : @1000,
                                                  @"selected" : @YES,
                                                  @"text" : @"Remove Ads",
                                                  @"frame" : [NSValue valueWithCGRect:CGRectMake(midX - 150,190,140,50)]
                                                  }];
        purchaseButton.delegate = self;
        [v addSubview:purchaseButton];
        
        restorePurchaseButton = [self buttonWithSetup:@{ @"tag" : @1001,
                                                         @"selected" : @YES,
                                                         @"text" : @"Restore Purchase",
                                                         @"frame" : [NSValue valueWithCGRect:CGRectMake(midX + 10,190,140,50)]
                                                         }];
        restorePurchaseButton.delegate = self;
        
        [v addSubview:restorePurchaseButton];
#endif
        
    }
       
    BOOL isiPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    CGFloat yOffset = - 64;
    
    if (isiPad) {
        
    } else {
        statusLabel.frame = CGRectMake(statusLabel.frame.origin.x, yOffset + (self.view.frame.size.height / 2.0f) - (statusLabel.frame.size.height /2.0f), statusLabel.frame.size.width, statusLabel.frame.size.height);
        versionLabel.frame = CGRectMake(versionLabel.frame.origin.x, yOffset + (self.view.frame.size.height / 3.0f) - (versionLabel.frame.size.height /2.0f), versionLabel.frame.size.width, versionLabel.frame.size.height);
        purchaseLabel.frame = CGRectMake(purchaseLabel.frame.origin.x, yOffset + (self.view.frame.size.height * 0.67f) - (purchaseLabel.frame.size.height /2.0f), purchaseLabel.frame.size.width, purchaseLabel.frame.size.height);
        purchaseButton.frame = CGRectMake(purchaseButton.frame.origin.x, yOffset + self.view.frame.size.height  - (purchaseButton.frame.size.height + 10) , purchaseButton.frame.size.width, purchaseButton.frame.size.height);
        restorePurchaseButton.frame = CGRectMake(restorePurchaseButton.frame.origin.x, yOffset + self.view.frame.size.height -( restorePurchaseButton.frame.size.height+ 10), restorePurchaseButton.frame.size.width, restorePurchaseButton.frame.size.height);
    }
    
    
    
    return v;
}



-(void)userTappedRateButton:(id)sender {
    [[UtilityBag bag] rateApp];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Setup";

    self.navigationItem.rightBarButtonItem =rateButton;
    
    [self updateButtons];
    
    if (!firstPageShown) {
        firstPageShown = YES;
        UIView *v = [self makeAboutView];
        [animatorPane addSubview:v];
        
        pageView = v;
    }

}

-(void)viewDidAppear:(BOOL)animated  {
    [super viewDidAppear:animated];
    
    if (self.launchForPurchase) {
        self.launchForPurchase = NO;
        [self performSelector:@selector(launchPurchaseScreen) withObject:nil afterDelay:2.0f];
    }
}

-(void)launchPurchaseScreen {
    [self userPressedGradientAttributedButtonWithTag:1000];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGRect)locate3x2CellForIndex:(NSInteger)index cellSize:(CGSize)cellSize {
    CGFloat curLeft;
    
    CGFloat curTop = ((320 / 2.0f) - (cellSize.height /2)) + 10;
    
    CGFloat spacing = 0;
    CGFloat wSpace = 4;
    CGFloat left = 115;
    
    if (animatorPane.bounds.size.width == 568.0f) {
        spacing = 17.0f;
        wSpace = 10.0f;
        left = 124;
    }
    
    
    if (index <= 2) {
        curTop -= cellSize.height + 10;
        curLeft = ((cellSize.width + wSpace) * index) + (spacing * (index+1));
    } else {
        curTop += 10;
        curLeft = ((cellSize.width + wSpace) * (index-3)) + (spacing * (index-2));
    }
    
    CGRect f = CGRectMake(left + curLeft, curTop, cellSize.width, cellSize.height);
    
    return f;
}

-(CGRect)locate3x1CellForIndex:(NSInteger)index cellSize:(CGSize)cellSize {
    CGFloat top = ((250 / 2.0f) - (cellSize.height /2)) - 30;
    
    CGFloat spacing = 0;
    CGFloat wSpace = 4;
    CGFloat left = 115;
    
    if (animatorPane.bounds.size.width == 568.0f) {
        spacing = 17.0f;
        wSpace = 10.0f;
        left = 124;
    }
    
    CGFloat curLeft = ((cellSize.width + wSpace) * index) + (spacing * (index +1));
    
    CGFloat curTop = top;
    
    CGRect f = CGRectMake(left + curLeft, curTop, cellSize.width, cellSize.height);
    
    return f;
}

- (void)collisionBehavior:(UICollisionBehavior*)behavior beganContactForItem:(id <UIDynamicItem>)item1 withItem:(id <UIDynamicItem>)item2 atPoint:(CGPoint)p {
        // NSLog(@"collisionbeganContactForItem");
}

- (void)collisionBehavior:(UICollisionBehavior*)behavior endedContactForItem:(id <UIDynamicItem>)item1 withItem:(id <UIDynamicItem>)item2 {
        // NSLog(@"collisionendedContactForItem");
}


@end