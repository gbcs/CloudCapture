//
//  LandscapeViewController.h
//  Capture
//
//  Created by Gary Barnett on 7/5/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraTopBarView.h"
#import "CameraTopDetailView.h"
#import "CameraZoomButtonBar.h"

#ifdef CCFREE
#import "AppsfireSDK.h"
#import "AppsfireAdSDK.h"
@interface VideoCameraViewController : UIViewController <UIPopoverControllerDelegate, AppsfireAdSDKDelegate>

#endif

#ifdef CCPRO
@interface LandscapeViewController : UIViewController <GradientAttributedButtonDelegate, UIPopoverControllerDelegate>
#endif

//-(CameraTopDetailView2 *)detailView;

-(void)startCameraAfterLaunch;
-(BOOL)cameraIsRunning;
-(void)setInterfaceHidden;

@end
