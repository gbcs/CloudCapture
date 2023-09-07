//
//  AppDelegate.h
//  Capture
//
//  Created by Gary Barnett on 7/4/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PurchaseObject.h"
#import "NavController.h"

#ifdef CCFREE
#import "AppsfireSDK.h"
#import "AppsfireAdSDK.h"
#endif
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NavController *navController;

@property (assign, nonatomic) BOOL allowRotation;
@property (assign, nonatomic) BOOL audioRecordingAllowed;
@property (assign, nonatomic) BOOL wasInterrupted;

-(UIViewController *)rootController;
-(void)allowRotation:(BOOL)allowed;

-(void)stopRemoteSessions;
-(void)handleRemoteSessionSetup;
-(void)askForMicrophone;

@end
