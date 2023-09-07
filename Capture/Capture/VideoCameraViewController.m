//
//  LandscapeViewController.m
//  Capture
//
//  Created by Gary Barnett on 7/5/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "VideoCameraViewController.h"
#import "VideoCaptureView.h"
#import "AppDelegate.h"
#import "FocusReticleView.h"
#import "ExposureReticleView.h"
#import "HelpViewController.h"
#import "ConfigureViewController.h"
#import "GridCollectionViewController.h"
#import "EngineViewController.h"
#import "LabeledButton.h"
#import "UIImage+NegativeImage.h"
#import "TitleEditViewController.h"
#import "GSDropboxUploader.h"
#import "SpriteTitlingTool.h"
//#import "GSFullscreenAd.h"
//#import "GSSDKInfo.h"
#import "VideoSourcesCollectionViewController.h"



@interface VideoCameraViewController () {
    __strong VideoCaptureView  *videoVC;
    __strong CameraTopBarView *topBar;
    __strong CameraTopDetailView *topDetail;
    __strong CameraZoomButtonBar *zoomBar;
    
    NSInteger oldSelection;
    BOOL interfaceHidden;
    UIView *reticlePane;
    FocusReticleView *focusReticle;
    ExposureReticleView *exposureReticle;
    NSTimer *repeatTimer;
    float repeatDelay;
  
    NSInteger zoomSpeedDirection;
    UILabel *zoomSpeedLabel;
    
    LabeledButton *zoomButton1;
    LabeledButton *zoomButton2;
    LabeledButton *zoomButton3;
    
    GradientAttributedButton *configureButton;
    GradientAttributedButton *libraryButton;
    GradientAttributedButton *engineButton;
    GradientAttributedButton *helpButton;
    GradientAttributedButton *recordButton;
    
    UIScrollView *optionScroller;
    
    BOOL suppressRecordButton;
    UITapGestureRecognizer *paneTapG;
    UIPanGestureRecognizer *panePanG;
    CGFloat timeSinceLastInteractionEvent;
    UILabel *moveClipView;
    UIActivityIndicatorView *moveClipIndicator;
    UIPopoverController *popoverController;
    
    UIView *iPadDetailButtonTray;
    UIView *iPadDetailTray;
    UIView *iPadMainButtonTray;
    UIView *iPadHistogramTray;
    NSMutableDictionary *iPadDetailArray;
    
    BOOL launchForPurchase;
    
    BOOL startupComplete;
    
    
    UIView *rotationCoveringView;
    UIDynamicAnimator *animator;
    UILabel *animatorLabel;
    SpriteTitlingTool *spriteTitlingTool;
    BOOL firstStartupCompleted;
    UIView *reviewView;
}

@end

@implementation VideoCameraViewController

#ifdef CCFREE

#endif

-(void)dealloc {
        //NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    videoVC = nil;
    topBar = nil;
    topDetail = nil;
    zoomBar = nil;
    
    reticlePane = nil;
    focusReticle = nil;
    exposureReticle = nil;
    repeatTimer = nil;
    
    zoomSpeedLabel = nil;
    
    zoomButton1 = nil;
    zoomButton2 = nil;
    zoomButton3 = nil;
    
    configureButton = nil;
    libraryButton = nil;
    engineButton = nil;
    helpButton = nil;
    recordButton = nil;
    
    optionScroller = nil;
    paneTapG = nil;
    panePanG = nil;
    moveClipView = nil;
    moveClipIndicator = nil;
    popoverController = nil;
    
    iPadDetailButtonTray = nil;
    iPadDetailTray = nil;
    iPadMainButtonTray = nil;
    iPadDetailArray = nil;
    iPadHistogramTray = nil;
    
    rotationCoveringView = nil;
    animator = nil;
    animatorLabel = nil;
    reviewView = nil;

}

- (NSString *)greystripeGUID
{
    NSString *guid = @"bf85098e-8dd8-11e3-ae90-f2b2fded7073";
    return guid;
}

-(void)startCameraAfterLaunch {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [self performSelector:@selector(startCameraAfterLaunch2) withObject:nil afterDelay:1.0f];
}

-(void)startCameraAfterLaunch2 {
    [self positionElements];
    [videoVC updateInterfaceHidden:interfaceHidden];
    [videoVC didRotateFromInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)setLastInteractionTimeToNow {
    timeSinceLastInteractionEvent = 0.0f;
}

-(void)userTappedZoomButton1:(NSNotification *)n {
    [self setLastInteractionTimeToNow];
    [self userTappedZoomButton:1];
}

-(void)userTappedZoomButton2:(NSNotification *)n {
    [self setLastInteractionTimeToNow];
    [self userTappedZoomButton:2];
}

-(void)userTappedZoomButton3:(NSNotification *)n {
    [self setLastInteractionTimeToNow];
    [self userTappedZoomButton:3];
}

-(void)userTappedZoomButton:(NSInteger)tag {
    float zoomLevel = 0.0f;
    
    switch (tag) {
        case 1:
            zoomLevel = [[SettingsTool settings] zoomPosition1];
            break;
        case 2:
            zoomLevel = [[SettingsTool settings] zoomPosition2];
            break;
        case 3:
            zoomLevel = [[SettingsTool settings] zoomPosition3];
            break;
    }
    
    if (zoomLevel >= 0.0f) {
        //convert to scale from percentage
        
        float newLevel = [videoVC maxZoomLevel] * zoomLevel;
        if (newLevel < 1.0) {
            newLevel = 1.0f;
        }
            // NSLog(@"Zooming to: %0.1f -> %0.1f", zoomLevel, newLevel);
        [videoVC zoomToLevel:newLevel withSpeed:[[SettingsTool settings] zoomRate]];
    }
}

-(void)userTappedPane:(NSNotification *)n {
    [videoVC dontUpdateVideoView:@(YES)];
    [self setLastInteractionTimeToNow];
    [videoVC addSettleTime:3.5f];
    
    interfaceHidden = !interfaceHidden;
    [self positionElements];
    reticlePane.hidden = !interfaceHidden;
    if (interfaceHidden) {
        oldSelection = topDetail.selected;
        topDetail.selected = -1;
        topBar.selected = -1;
        [videoVC removeGestureRecognizer:paneTapG];
        [reticlePane addGestureRecognizer:paneTapG];
        [self.view sendSubviewToBack:videoVC];
        [self.view bringSubviewToFront:zoomBar];
       
    } else {
        topDetail.selected = oldSelection;
        topBar.selected = oldSelection;
        
        [reticlePane removeGestureRecognizer:paneTapG];
        [videoVC addGestureRecognizer:paneTapG];
        [self.view bringSubviewToFront:videoVC];
        [self updateBarImages];
    }
    
    [topDetail showControlsForSelected];
    [self updateTopBarStatusInfo];
    [topBar update];
    
    [videoVC performSelector:@selector(dontUpdateVideoView:) withObject:@(NO) afterDelay:0.1];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        zoomBar.hidden = NO;
        [self.view bringSubviewToFront:zoomBar];
        [iPadHistogramTray addSubview:[topDetail histogramView]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"handleHistogramDelegate" object:interfaceHidden ? nil : topDetail];
        
    }
    
}

-(void)setupZoomButtons {
    
    NSInteger zoomBarLocation = [[SettingsTool settings] zoomBarLocation];
    
    
    if ( (![videoVC zoomSupported]) || (zoomBarLocation == 0) ) {
        [zoomButton1 removeFromSuperview];
        [zoomButton2 removeFromSuperview];
        [zoomButton3  removeFromSuperview];
        return;
    }
    
    
    if (!zoomButton1) {
        zoomButton1 = [[LabeledButton alloc] initWithFrame:CGRectZero];
        zoomButton2 = [[LabeledButton alloc] initWithFrame:CGRectZero];
        zoomButton3 = [[LabeledButton alloc] initWithFrame:CGRectZero];
        
        zoomButton1.caption = @"z1";
        zoomButton2.caption = @"z2";
        zoomButton3.caption = @"Z3";
        
       
        
        zoomButton1.notifyStringDown = @"userTappedZoomButton1";
        zoomButton2.notifyStringDown = @"userTappedZoomButton2";
        zoomButton3.notifyStringDown = @"userTappedZoomButton3";
    }
    
    [zoomButton1 justify:zoomBarLocation];
    [zoomButton2 justify:zoomBarLocation];
    [zoomButton3 justify:zoomBarLocation];
    
    
    if (!zoomButton1.superview) {
        [reticlePane addSubview:zoomButton1];
        [reticlePane addSubview:zoomButton2];
        [reticlePane addSubview:zoomButton3];
    }
    
    
    float x = 0.0f;
    if (zoomBarLocation == 2) {
        x = self.view.frame.size.width - 44;
    }
    
    float h = (self.view.frame.size.height - 50)/4;
    
    zoomButton1.frame = CGRectMake(x, 70 + (h * 0), 44,44);
    zoomButton2.frame = CGRectMake(x, 70 + (h * 1), 44,44);
    zoomButton3.frame = CGRectMake(x, 70 + (h * 2), 44,44);
    
    
    [reticlePane sendSubviewToBack:zoomButton1];
    [reticlePane sendSubviewToBack:zoomButton2];
    [reticlePane sendSubviewToBack:zoomButton3];
}

-(void)hideInterface:(BOOL)hide {
    topBar.hidden = hide;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        zoomBar.hidden = NO;
    } else {
        zoomBar.hidden = hide;
    }
    
    reticlePane.alpha = hide ? 0.05f : 1.0f;
    exposureReticle.hidden = hide;
    focusReticle.hidden = hide;
    zoomButton1.hidden = hide;
    zoomButton2.hidden = hide;
    zoomButton3.hidden = hide;

}

-(void)hidePreview:(BOOL)hide {
    videoVC.hidden = hide;
}

-(void)repeatTimerEvent {
    
    if (timeSinceLastInteractionEvent == 0.0f) {
        if (topBar.hidden) {
            [self hideInterface:NO];
        }
        
        if (videoVC.hidden) {
            [self hidePreview:NO];
        }
    }
    
    if (!interfaceHidden) {
        if (topBar.hidden) {
            [self hideInterface:NO];
        }
        if (videoVC.hidden) {
            [self hidePreview:NO];
        }
    } else {
        timeSinceLastInteractionEvent += 0.05;
        
        NSInteger hidePreview =[[SettingsTool settings] hidePreview];
        NSInteger hideInterface =[[SettingsTool settings] hideUserInterface];
        
        if ((hidePreview > 0) && (timeSinceLastInteractionEvent > [[SettingsTool settings] hidePreview]) && (!topBar.hidden) ) {
            [self hidePreview:YES];
        }
        
        if ((hideInterface > 0) && (timeSinceLastInteractionEvent > [[SettingsTool settings] hideUserInterface]) ) {
            [self hideInterface:YES];
        }
    }
    
    if (repeatDelay <= 0.0f) {
        return;
    }
    
    repeatDelay -= 0.10f;
    
    if (repeatDelay <= 0.0f) {
        repeatDelay = 0.0f;
        
        if (zoomSpeedDirection == 1) {
            [self zoomSpeedDecrement   ];
        } else if (zoomSpeedDirection == 2) {
            [self zoomSpeedIncrement];
        }
    }
}

-(void)userWantsEngine:(NSNotification *)n {
   // [self userPressedGradientAttributedButtonWithTag:3];
}

//-(CameraTopDetailView2 *)detailView {
 //   return topDetail;
//}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    if (!videoVC.isRunning) {
        [videoVC restartCamera];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanup" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanupPhotoLibraryViewController" object:nil];
}


-(void)setupRightHandButtons {
    
    CGRect f1;
    CGRect f2;
    CGRect f3;
    CGRect f4;
    CGRect f5;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        f1 = CGRectMake(5 + 150,700,110,44);
        f2 = CGRectMake(125 + 150,700,110,44);
        f3 = CGRectMake(245 + 150,700,110,44);
        f4 = CGRectMake(365 + 150,700,110,44);
        f5 = CGRectMake(5,768 - 300,100,568/2);
    } else if (self.view.frame.size.width == 568.0f) {
        f1 = CGRectZero;
        f2 = CGRectZero;
        f3 = CGRectZero;
        f4 = CGRectZero;
        f5 = CGRectMake(2,270,568,50);
    } else {
        f1 = CGRectZero;
        f2 = CGRectZero;
        f3 = CGRectZero;
        f4 = CGRectZero;
        f5 = CGRectMake(2,270,480,50);
    }
    
 
    configureButton = [self buttonWithSetup:@{  @"tag" : @1,
                                                @"selected" : @NO,
                                                @"text" : @"Setup",
                                                @"frame" : [NSValue valueWithCGRect:f1]
                                                }];
    
    libraryButton = [self buttonWithSetup:@{  @"tag" : @2,
                                              @"selected" : @NO,
                                              @"text" : @"Library",
                                              @"frame" : [NSValue valueWithCGRect:f3]
                                              }];
    
    engineButton = [self buttonWithSetup:@{  @"tag" : @3,
                                             @"selected" : @NO,
                                             @"text" : @"Pipeline",
                                             @"frame" : [NSValue valueWithCGRect:f2]
                                             }];
    
    helpButton = [self buttonWithSetup:@{  @"tag" : @4,
                                             @"selected" : @NO,
                                             @"text" : @"Director",
                                            @"frame" : [NSValue valueWithCGRect:f4]
                                             }];
 
    
    if (!optionScroller) {
  
        optionScroller = [[UIScrollView alloc] initWithFrame:f5];
        
        NSArray *barItems = @[@"barVideoCamera",
                               @"barResolution",
                               @"barFocus",
                               @"barExposure",
                               @"barGuides"];
        
 
        
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
            barItems = [barItems arrayByAddingObject:@"barTorch"];
        }
        
        if (!([[SettingsTool settings] isiPhone4S] || [[SettingsTool settings] isiPad3] || [[SettingsTool settings] isIPadMini] || [[SettingsTool settings] isOldDevice])) {
            barItems = [barItems arrayByAddingObjectsFromArray:@[
                                                                 @"barZoom"
                                                                 ]];
        }
        
        barItems = [barItems arrayByAddingObjectsFromArray:@[
                                                             @"barImageEffect",
                                                             @"barColorControls",
                                                             ]];
        
        if (!([[SettingsTool settings] isiPhone4S] || [[SettingsTool settings] isOldDevice]) ) {
            barItems = [barItems arrayByAddingObjectsFromArray:@[
                                                                 @"barChromaKey",
                                                                 ]];
        }

        barItems = [barItems arrayByAddingObjectsFromArray:@[
                                                             @"barTitling",
                                                             @"barPresets"
                                                             ]];
        CGFloat width = self.view.frame.size.width;
        CGFloat spacing = (width - ([barItems count] * 40)) / ([barItems count] -1);
        
        NSInteger index = 0;
        NSInteger row = 0;
        NSInteger ipadIndex = 0;
        
        CGFloat lastX = 0.0f;
        CGFloat lastY = 0.0f;
        
        for (NSString *imageName in barItems) {
            UIImageView *iv = [self imageViewForOption:imageName];
            iv.layer.shadowColor = [UIColor whiteColor].CGColor;
            [iv.layer setShadowOpacity:0.4];
            [iv.layer setShadowRadius:1.0];
            [iv.layer setShadowOffset:CGSizeMake(-1.0, -1.0)];
            iv.layer.cornerRadius = 8;
            iv.layer.masksToBounds = NO;
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                 width = optionScroller.bounds.size.height;
                 NSInteger c = [barItems count] / 2;
                 spacing = (width - (c * 40)) / (c -1);
                if (index > 5) {
                    ipadIndex = index - 6;
                    row = 45;
                } else {
                    ipadIndex = index;
                    row = 0;
                }
                
                 iv.frame = CGRectMake(row, (ipadIndex * 40) + (spacing * ipadIndex), 40,40);
            } else {
                 iv.frame = CGRectMake((index * 40) + (spacing * index), 5, 40,40);
            }
            
           
            [optionScroller addSubview:iv];
            iv.tag = [self tagForBarItem:imageName];
            index++;
            lastX = iv.frame.origin.x + iv.frame.size.width;
            lastY = iv.frame.origin.y + iv.frame.size.height;
        }
        
        [optionScroller setContentSize:CGSizeMake(lastX, lastY)];
        
    }
   
    [self.view addSubview:optionScroller];
    
    configureButton.tag = 1;
    libraryButton.tag = 2;
    engineButton.tag = 3;
    helpButton.tag = 4;
    
    if (UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPad) {
        if (!iPadDetailButtonTray) {
            iPadDetailArray = [[NSMutableDictionary alloc] initWithCapacity:3];
            self.view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
            
            iPadDetailButtonTray = [[UIView alloc] initWithFrame:CGRectZero];
            iPadDetailTray = [[UIView alloc] initWithFrame:CGRectZero];
            iPadMainButtonTray = [[UIView alloc] initWithFrame:CGRectZero];
            iPadHistogramTray = [[UIView alloc] initWithFrame:CGRectZero];
            
            UILongPressGestureRecognizer *longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDraggingElement:)];
            longP.minimumPressDuration = 0.25f;
            iPadDetailButtonTray.tag = 1;
            [iPadDetailButtonTray addGestureRecognizer:longP];
            
            longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDraggingElement:)];
            longP.minimumPressDuration = 0.25f;
            iPadDetailTray.tag = 2;
            [iPadDetailTray addGestureRecognizer:longP];
            
            longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDraggingElement:)];
            longP.minimumPressDuration = 0.25f;
            iPadMainButtonTray.tag = 3;
            [iPadMainButtonTray addGestureRecognizer:longP];
            
            longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDraggingElement:)];
            longP.minimumPressDuration = 0.25f;
            iPadHistogramTray.tag = 4;
            [iPadHistogramTray addGestureRecognizer:longP];
            
            topDetail.iPadDetailSled = iPadDetailTray;
            
            videoVC.backgroundColor = [UIColor blackColor];
        }
        
        iPadDetailButtonTray.frame = CGRectMake([[SettingsTool settings] iPadDetailButtonTray].x, [[SettingsTool settings] iPadDetailButtonTray].y, 100, 400);
        iPadDetailTray.frame = CGRectMake([[SettingsTool settings] iPadDetailTray].x, [[SettingsTool settings] iPadDetailTray].y, 308, 285);
        iPadMainButtonTray.frame = CGRectMake([[SettingsTool settings] iPadMainButtonTray].x, [[SettingsTool settings] iPadMainButtonTray].y, 500, 100);
        iPadHistogramTray.frame = CGRectMake([[SettingsTool settings] iPadHistogramTray].x, [[SettingsTool settings] iPadHistogramTray].y, 256, 100);
        
        iPadDetailButtonTray.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];
        iPadDetailTray.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];
        iPadMainButtonTray.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];
        iPadHistogramTray.backgroundColor = [UIColor colorWithWhite:0.10 alpha:1.0];
        
        [self.view addSubview:iPadDetailButtonTray];
        [self.view addSubview:iPadDetailTray];
        [self.view addSubview:iPadMainButtonTray];
        [self.view addSubview:iPadHistogramTray];
        [iPadHistogramTray addSubview:[topDetail histogramView]];
        videoVC.frame = [[SettingsTool settings] iPadVideoViewRect];
    }
    
    [self updateBarImages];
}

-(void)userDraggingElement:(UILongPressGestureRecognizer *)g {
    NSInteger tag = g.view.tag;
    CGPoint loc = [g locationInView:self.view];
   
    if (g.state == UIGestureRecognizerStateBegan) {
        [iPadDetailArray setObject:[NSValue valueWithCGPoint:g.view.center] forKey:@(tag)];
    } else if (g.state == UIGestureRecognizerStateEnded) {
        switch (tag) {
            case 1:
                [[SettingsTool settings] setiPadDetailButtonTray:g.view.frame.origin];
                break;
            case 2:
                [[SettingsTool settings] setiPadDetailTray:g.view.frame.origin];
                break;
            case 3:
                [[SettingsTool settings] setiPadMainButtonTray:g.view.frame.origin];
                break;
            case 4:
                [[SettingsTool settings] setiPadHistogramTray:g.view.frame.origin];
                break;
        }
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint offset = [[iPadDetailArray objectForKey:@(tag)] CGPointValue];
        
        CGPoint offsetAmt = CGPointMake(g.view.center.x - offset.x, g.view.center.y - offset.y);
    
        CGPoint offsetPos = CGPointMake(loc.x + offsetAmt.x, loc.y + offsetAmt.y);
        
        offsetPos.x -= g.view.bounds.size.width / 2.0f;
        offsetPos.y -= g.view.bounds.size.height / 2.0f;
        
        switch (tag) {
            case 1:
            {
                CGRect r = CGRectMake(offsetPos.x, offsetPos.y, iPadDetailButtonTray.frame.size.width, iPadDetailButtonTray.frame.size.height);
                
                if (r.origin.x + r.size.width > self.view.bounds.size.width) {
                    r.origin.x = self.view.bounds.size.width - r.size.width;
                } else if (r.origin.x < 0.0f) {
                    r.origin.x = 0.0f;
                }
                
                if (r.origin.y + r.size.height > self.view.bounds.size.height) {
                    r.origin.y = self.view.bounds.size.height - r.size.height;
                } else if (r.origin.y < 0.0f) {
                    r.origin.y = 0.0f;
                }
                
                iPadDetailButtonTray.frame = r;
            }
                break;
            case 2:
            {
                CGRect r = CGRectMake(offsetPos.x, offsetPos.y, iPadDetailTray.frame.size.width, iPadDetailTray.frame.size.height);
                
                if (r.origin.x + r.size.width > self.view.bounds.size.width) {
                    r.origin.x = self.view.bounds.size.width - r.size.width;
                } else if (r.origin.x < 0.0f) {
                    r.origin.x = 0.0f;
                }
                
                if (r.origin.y + r.size.height > self.view.bounds.size.height) {
                    r.origin.y = self.view.bounds.size.height - r.size.height;
                } else if (r.origin.y < 0.0f) {
                    r.origin.y = 0.0f;
                }
                
                iPadDetailTray.frame = r;
            }
                break;
            case 3:
            {
                CGRect r = CGRectMake(offsetPos.x, offsetPos.y, iPadMainButtonTray.frame.size.width, iPadMainButtonTray.frame.size.height);
                
                if (r.origin.x + r.size.width > self.view.bounds.size.width) {
                    r.origin.x = self.view.bounds.size.width - r.size.width;
                } else if (r.origin.x < 0.0f) {
                    r.origin.x = 0.0f;
                }
                
                if (r.origin.y + r.size.height > self.view.bounds.size.height) {
                    r.origin.y = self.view.bounds.size.height - r.size.height;
                } else if (r.origin.y < 0.0f) {
                    r.origin.y = 0.0f;
                }
                
                iPadMainButtonTray.frame = r;
            }
                break;
            case 4:
            {
                CGRect r = CGRectMake(offsetPos.x, offsetPos.y, iPadHistogramTray.frame.size.width, iPadHistogramTray.frame.size.height);
                
                if (r.origin.x + r.size.width > self.view.bounds.size.width) {
                    r.origin.x = self.view.bounds.size.width - r.size.width;
                } else if (r.origin.x < 0.0f) {
                    r.origin.x = 0.0f;
                }
                
                if (r.origin.y + r.size.height > self.view.bounds.size.height) {
                    r.origin.y = self.view.bounds.size.height - r.size.height;
                } else if (r.origin.y < 0.0f) {
                    r.origin.y = 0.0f;
                }
                
                iPadHistogramTray.frame = r;
            }
                break;
        }
        
        [iPadDetailArray setObject:[NSValue valueWithCGPoint:g.view.center] forKey:@(tag)];
    }
}

-(NSInteger)tagForBarItem:(NSString *)barItem {
    NSInteger tag = -1;
    
    if ([barItem isEqualToString:@"barVideoCamera"]) {
        tag = 0;
    } else if ([barItem isEqualToString:@"barResolution"]) {
         tag = 1;
    } else if ([barItem isEqualToString:@"barFocus"]) {
         tag = 2;
    } else if ([barItem isEqualToString:@"barExposure"]) {
         tag = 3;
    } else if ([barItem isEqualToString:@"barGuides"]) {
         tag = 4;
    } else if ([barItem isEqualToString:@"barTorch"]) {
         tag = 5;
    } else if ([barItem isEqualToString:@"barZoom"]) {
         tag = 6;
    } else if ([barItem isEqualToString:@"barImageEffect"]) {
         tag = 8;
    } else if ([barItem isEqualToString:@"barColorControls"]) {
         tag = 9;
    } else if ([barItem isEqualToString:@"barChromaKey"]) {
         tag = 7;
    } else if ([barItem isEqualToString:@"barTitling"]) {
         tag = 10;
    } else if ([barItem isEqualToString:@"barPresets"]) {
         tag = 11;
    }

    return tag;
}


-(void)imageTapped:(UITapGestureRecognizer *)g {
    [self setLastInteractionTimeToNow];
    if (g.state == UIGestureRecognizerStateEnded) {
       [videoVC addSettleTime:1.0f];
        topBar.selected = g.view.tag;
        topDetail.activeComponent = 0;
        [self updateTopBarStatusInfo];
        [self updateBarImages];
    }
}

-(void)updateBarImages {
    for (NSObject *o in optionScroller.subviews) {
        if ([[o class] isEqual:[UIImageView class]]) {
            UIImageView *v = (UIImageView *)o;
            v.backgroundColor = (topDetail.selected == v.tag) ? [UIColor blackColor] : [UIColor clearColor];
        }
    }
}

-(UIImageView *)imageViewForOption:(NSString *)name {
    UIImage *i = [UIImage imageNamed:name];
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:[i negativeImage]];
    iv.contentMode = UIViewContentModeCenter;
  
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [iv addGestureRecognizer:tapG];
    iv.alpha = 0.7;
    iv.userInteractionEnabled = YES;
    iv.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    
    return iv;
}

-(GradientAttributedButton *)buttonWithSetup:(NSDictionary *)setup {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#000000"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    NSAttributedString *activeText = [[NSAttributedString alloc] initWithString:[setup objectForKey:@"text"] attributes:@{
                                                                                                                          NSFontAttributeName : [[[UtilityBag bag] standardFontBold] fontWithSize:14],
                                                                                                                          NSShadowAttributeName : shadow,
                                                                                                                          NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#CCCCCC"]
                                                                                                                          }];
    
    
    NSAttributedString *inactiveText = [[NSAttributedString alloc] initWithString:[setup objectForKey:@"text"]  attributes:@{
                                                                                                                              NSFontAttributeName : [[[UtilityBag bag] standardFontBold] fontWithSize:14],
                                                                                                                             NSShadowAttributeName : shadow,
                                                                                                                             NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#CCCCCC"]
                                                                                                                             }];
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:[[setup objectForKey:@"frame"] CGRectValue]];
    button.delegate = self;
    
    button.tag = [[setup objectForKey:@"tag"] integerValue];
    
    if ([[setup objectForKey:@"selected"] boolValue]) {
        [button setTitle:activeText disabledTitle:activeText beginGradientColorString:@"#000099" endGradientColor:@"#000066"];
    } else {
        [button setTitle:inactiveText disabledTitle:inactiveText beginGradientColorString:@"#666666" endGradientColor:@"#333333"];
    }
    
    button.enabled = YES;
    [button update];
    
    return button;
}




-(void)stopCameraForPlayback:(NSNotification *)n {
    if (videoVC.isRecording) {
        [videoVC stopRecording];
        topBar.recording = NO;
        [topBar update];
        [zoomBar stopRecording];
        [[StatusReporter manager] stopRecording];
    }
   
    [videoVC stopCamera];
}

-(void)paneTapMode:(NSNotification *)n {
    NSNumber *enabled = n.object;
    [self setPaneTapMode:[enabled boolValue]];
}

-(void)setPaneTapMode:(BOOL)enabled {
    if (enabled) {
        if (!paneTapG) {
            paneTapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedPane:)];
        }
        if (interfaceHidden) {
            [videoVC removeGestureRecognizer:paneTapG];
            [reticlePane addGestureRecognizer:paneTapG];
            [self.view bringSubviewToFront:reticlePane];
            [self.view bringSubviewToFront:topBar];
            [self.view bringSubviewToFront:zoomBar];
        } else {
            [reticlePane removeGestureRecognizer:paneTapG];
            [videoVC addGestureRecognizer:paneTapG];
        }
       
    } else if ((!enabled) && (paneTapG)) {
        [reticlePane removeGestureRecognizer:paneTapG];
        [videoVC removeGestureRecognizer:paneTapG];
        paneTapG = nil;
    }
}

-(void)panePanMode:(NSNotification *)n {
    NSNumber *enabled = n.object;
    [self setPanePanMode:[enabled boolValue]];
}

-(void)setPanePanMode:(BOOL)enabled {
    if (enabled && (!panePanG)) {
        panePanG = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userPannedPane:)];
        [reticlePane addGestureRecognizer:panePanG];
        [self.view bringSubviewToFront:reticlePane];
    } else if ((!enabled) && (panePanG)) {
        [reticlePane removeGestureRecognizer:panePanG];
        panePanG = nil;
    }
}

-(void)userPannedPane:(UIPanGestureRecognizer *)g {
    static CGPoint originalPoint;
    [self setLastInteractionTimeToNow];
    if (g.state == UIGestureRecognizerStateBegan) {
        originalPoint = [g locationInView:reticlePane];
    } else if (g.state == UIGestureRecognizerStateChanged) {
        CGPoint curPoint = [g locationInView:reticlePane];
        CGFloat deltaX = originalPoint.x - curPoint.x;
        if ([[SettingsTool settings] framingGuide] > 0) {
            [videoVC updateFramingGuideOffset:deltaX];
        }
    }
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
  
    interfaceHidden = YES;
    
    videoVC = [[VideoCaptureView alloc] initWithFrame:self.view.bounds];
    
    topBar = [[CameraTopBarView alloc] initWithFrame:CGRectZero];
    topBar.audioLPercentage = -2000.0f;
    topBar.audioRPercentage = -2000.0f;
    
    topDetail = [[CameraTopDetailView alloc] initWithFrame:CGRectZero];
    
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"LCDBackground"]];
    self.view.backgroundColor = [UIColor blackColor];
    
    zoomBar = [[CameraZoomButtonBar alloc] initWithFrame:CGRectZero];
    
    if (!reticlePane) {
        reticlePane = [[UIView alloc] initWithFrame:CGRectZero];
        reticlePane.backgroundColor = [UIColor clearColor];
        reticlePane.userInteractionEnabled = YES;
       
    }
    
    [self setPaneTapMode:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addSettleTime:) name:@"addSettleTime" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStillImageRequest:) name:@"handleStillImageRequest" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopCameraForPlayback:) name:@"stopCameraForPlayback" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDoneWithHelp:) name:@"userDoneWithHelp" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedHelp:) name:@"bottomBarButtonTappedHelpButtonDown" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedPane:) name:@"userTappedReticlePane" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delayedUpdate) name:@"delayedUpdate" object:nil];
    
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedRecordButtonDown) name:@"bottomBarButtonTappedrecordButtonDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedSelectButtonDown) name:@"bottomBarButtonTappedselectButtonDown" object:nil];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedValueMinusDown) name:@"bottomBarButtonTappedvalueMinusDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedValuePlusDown) name:@"bottomBarButtonTappedvaluePlusDown" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedModeMinusUp) name:@"bottomBarButtonTappedmodeMinusUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedModePlusUp) name:@"bottomBarButtonTappedmodePlusUp" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedSelectButtonUp) name:@"bottomBarButtonTappedselectButtonUp" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedValueMinusUp) name:@"bottomBarButtonTappedvalueMinusUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedValuePlusUp) name:@"bottomBarButtonTappedvaluePlusUp" object:nil];
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioMonitoringDisable) name:@"audioMonitoringDisable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioMonitoringEnable) name:@"audioMonitoringEnable" object:nil];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioCaptureSampleRateDecrement) name:@"audioCaptureSampleRateDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioCaptureSampleRateIncrement) name:@"audioCaptureSampleRateIncrement" object:nil];
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioAACEncodingDisable) name:@"audioAACEncodingDisable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioAACEncodingEnable) name:@"audioAACEncodingEnable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioAACQualityDecrement) name:@"audioAACQualityDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioAACQualityIncrement) name:@"audioAACQualityIncrement" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSampleRateSet:) name:@"audioSampleRateSet" object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraFront) name:@"cameraFront" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraBack) name:@"cameraBack" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraISDisable) name:@"cameraISDisable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraISEnable) name:@"cameraISEnable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraFlipDisable) name:@"cameraFlipDisable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraFlipEnable) name:@"cameraFlipEnable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotationLockDisable) name:@"rotationLockDisable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotationLockEnable) name:@"rotationLockEnable" object:nil];
   
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureOutputResolutionDecrement) name:@"captureOutputResolutionDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureOutputResolutionIncrement) name:@"captureOutputResolutionIncrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureOutputResolutionSet:) name:@"captureOutputResolutionSet" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureFrameRateDecrement) name:@"captureFrameRateDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureFrameRateIncrement) name:@"captureFrameRateIncrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureFrameRateSet:) name:@"captureFrameRateSet" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureVideoRateSetDefault) name:@"captureVideoRateSetDefault" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureVideoRateDecrement) name:@"captureVideoDataRateDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureVideoRateIncrement) name:@"captureVideoDataRateIncrement" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusAuto) name:@"focusAuto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusLock) name:@"focusLock" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusCenter) name:@"focusCenter" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusReticle) name:@"focusReticle" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusRangeOff) name:@"focusRangeOff" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusRangeNear) name:@"focusRangeNear" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusRangeFar) name:@"focusRangeFar" object:nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSpeedSmooth) name:@"focusSpeedSmooth" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSpeedFast) name:@"focusSpeedFast" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteBalanceAuto) name:@"whiteBalanceAuto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteBalanceLock) name:@"whiteBalanceLock" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isoLockAuto) name:@"isoLockAuto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isoLockSet) name:@"isoLockSet" object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exposureAuto) name:@"exposureAuto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exposureLock) name:@"exposureLock" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exposureCenter) name:@"exposureCenter" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exposureReticle) name:@"exposureReticle" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contrastDecrement) name:@"videoContrastDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contrastDefault) name:@"videoContrastDefault" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contrastIncrement) name:@"videoContrastIncrement" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saturationDecrement) name:@"videoSaturationDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saturationDefault) name:@"videoSaturationDefault" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saturationIncrement) name:@"videoSaturationIncrement" object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brightnessDecrement) name:@"videoBrightnessDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brightnessDefault) name:@"videoBrightnessDefault" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brightnessIncrement) name:@"videoBrightnessIncrement" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torchOn) name:@"torchOn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torchOff) name:@"torchOff" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torchLevelDecrement) name:@"torchLevelDecrement" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torchLevelMiddle) name:@"torchLevelMiddle" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torchLevelIncrement) name:@"torchLevelIncrement" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(horizonGuideOff) name:@"horizonGuideOff" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(horizonGuideOn) name:@"horizonGuideOn" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thirdsGuideOff) name:@"thirdsGuideOff" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thirdsGuideOn) name:@"thirdsGuideOn" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(framingGuideOff) name:@"framingGuideOff" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(framingGuide43) name:@"framingGuide43" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(framingGuide11) name:@"framingGuide11" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fastCaptureModeEnabled) name:@"fastCaptureModeEnabled" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fastCaptureModeDisabled) name:@"fastCaptureModeDisabled" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomPosition1Set) name:@"zoomPosition1Set" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomPosition1Unset) name:@"zoomPosition1Unset" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomPosition2Set) name:@"zoomPosition2Set" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomPosition2Unset) name:@"zoomPosition2Unset" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomPosition3Set) name:@"zoomPosition3Set" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomPosition3Unset) name:@"zoomPosition3Unset" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomOutDown) name:@"zoomBarZoomOutDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomOutUp) name:@"zoomBarZoomOutUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomSpeedLessDown) name:@"zoomBarZoomSpeedLessDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomSpeedLessUp) name:@"zoomBarZoomSpeedLessUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarPicDown) name:@"zoomBarPicDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarPicUp) name:@"zoomBarPicUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomSpeedMoreDown) name:@"zoomBarZoomSpeedMoreDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomSpeedMoreUp) name:@"zoomBarZoomSpeedMoreUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomInDown) name:@"zoomBarZoomInDown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomBarZoomInUp) name:@"zoomBarZoomInUp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedZoomButton1:) name:@"userTappedZoomButton1" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedZoomButton2:) name:@"userTappedZoomButton2" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedZoomButton3:) name:@"userTappedZoomButton3" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedCameraExitButton:) name:@"cameraExitButtonDown" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userWantsEngine:) name:@"userWantsEngine" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paneTapMode:) name:@"paneTapMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartCameraForFeatureChange:) name:@"restartCameraForFeatureChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilterAttributes:) name:@"updateFilterAttributes" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioLevelReport:) name:@"audioLevelReport" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveClipToCameraRoll:) name:@"moveClipToCameraRoll" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipMoveReport:) name:@"clipMoveReport" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAfterPresetChange:) name:@"reloadAfterPresetChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAfterModalDialog:) name:@"resetAfterModalDialog" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchForPurchase:) name:@"launchForPurchase" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchForHelp:) name:@"launchForHelp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAfterActivityDialog:) name:@"resetAfterActivityDialog" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendEmailThankYouResponse:) name:@"sendEmailThankYouResponse" object:nil];

    repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.20 target:self selector:@selector(repeatTimerEvent) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleFocusLock:) name:@"toggleFocusLock" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleExposureLock:) name:@"toggleExposureLock" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleWhiteBalanceLock:) name:@"toggleWhiteBalanceLock" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleRecordingFromRemote:) name:@"toggleRecording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopRecording:) name:@"stopRecording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startRecording:) name:@"startRecording" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchPadButtonPressed:) name:@"launchPadButtonPressed" object:nil];


    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxUploadBegin:) name:GSDropboxUploaderDidStartUploadingFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxUploadFinish:) name:GSDropboxUploaderDidFinishUploadingFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxUploadProgress:) name:GSDropboxUploaderDidGetProgressUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxUploadFailed:) name:GSDropboxUploaderDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPasswordPage:) name:@"showPasswordPage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAd:) name:@"showAdOnController" object:nil];
    
    interfaceHidden = YES;
    
    oldSelection = 0;
    topDetail.selected = -1;
    topBar.selected = -1;
    topDetail.activeComponent = 0;
    
    [self.view addSubview:videoVC];
    
    [self.view addSubview:zoomBar];
    
    [zoomBar updateSize];
    
    [self.view addSubview:topBar];
    
    [self.view addSubview:topDetail];
    
    [self.view addSubview:reticlePane];
    
    [topDetail showControlsForSelected];
    
    [self updateTopBarStatusInfo];
    
    [topBar update];
    
    [self positionElements];
    
    [videoVC updateInterfaceHidden:YES];
    
    [self positionReticles];
    
    [[LocationHandler tool] sendMotionUpdates:[[SettingsTool settings] horizonGuide]];
#ifdef CCFREE
 //   if (![[SettingsTool settings] hasPaid]) {
 //       self.myFullscreenAd = [[GSFullscreenAd alloc] initWithDelegate:self];
 //       [myFullscreenAd fetch];
 //   }
#endif
}


-(void)showAd:(NSNotification *)n {
    if (firstStartupCompleted) {
        if (![[SettingsTool settings] hasBeggedForReview]) {
            if ([[SettingsTool settings] shouldBegForReview]) {
                [self performSelector:@selector(begForReview) withObject:nil afterDelay:2.0f];
                [[SettingsTool settings] setHasBeggedForReview];
                return;
            }
        }
    }

    
#ifdef CCFREE
    if ([[SettingsTool settings] hasPaid]) {
        return;
    }
    
    UIViewController *vc = (UIViewController *)n.object;
    
    if ([AppsfireAdSDK isThereAModalAdAvailableForType:AFAdSDKModalTypeSushi] == AFAdSDKAdAvailabilityYes) {
        [AppsfireAdSDK requestModalAd:AFAdSDKModalTypeSushi withController:vc];
        [[SettingsTool settings] setHasDoneSomethingAdWorthy:NO];

    
    //if ([AppsfireAdSDK isThereAModalAdAvailableForType:AFAdSDKModalTypeUraMaki] == AFAdSDKAdAvailabilityYes) {
   //     [AppsfireAdSDK requestModalAd:AFAdSDKModalTypeUraMaki withController:vc];
   //     [[SettingsTool settings] setHasDoneSomethingAdWorthy:NO];
    } else {
        NSLog(@"Ad would show; but one is not ready");
    }
#endif
}

-(void)showPasswordPage:(NSNotification *)n {
    if (animatorLabel) {
        animatorLabel.tag = 30;
    } else {
        animatorLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f)- 200, -200, 400, 200)];
        animatorLabel.text = [NSString stringWithFormat:@"%@", [[SettingsTool settings] engineRemotePassword]];
        animatorLabel.backgroundColor = [UIColor whiteColor];
        animatorLabel.textColor = [UIColor blackColor];
        animatorLabel.numberOfLines = 2;
        animatorLabel.font = [UIFont boldSystemFontOfSize:30];
        animatorLabel.textAlignment = NSTextAlignmentCenter;
        animatorLabel.tag = 30;
        [self.view addSubview:animatorLabel];
        
        UILabel *h = [[UILabel alloc] initWithFrame:CGRectMake(0,0,400,40)];
        h.text = @"Director Password";
        h.backgroundColor =[UIColor darkGrayColor];
        h.textColor = [UIColor whiteColor];
        h.textAlignment = NSTextAlignmentCenter;
        h.font = [UIFont boldSystemFontOfSize:17];
        [animatorLabel addSubview:h];
        
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ animatorLabel ] ];
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ animatorLabel] ];
        
        CGFloat y = self.view.frame.size.height - 50;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            y = (self.view.frame.size.width / 2.0f) - 100;
        }
        
        
        [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, y) toPoint:CGPointMake(self.view.frame.size.width, y)];
        
        [animator addBehavior:collision];
        [animator addBehavior:gravity];
        
        animatorLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedCloseAnimator)];
        [animatorLabel addGestureRecognizer:tapG];
        [self performSelector:@selector(decrementAnimator) withObject:nil afterDelay:1.0f];
    }
}
-(void)userTappedCameraExitButton:(NSNotification *)n {
    
    [self.navigationController popViewControllerAnimated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopCameraForPlayback:nil];
    });
}

-(void)userTappedCloseAnimator {
    animatorLabel.tag = 0;
}

-(void)decrementAnimator {
    animatorLabel.tag--;
    if (animatorLabel.tag <1) {
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ animatorLabel ] ];
        [animator removeAllBehaviors];
        [animator addBehavior:gravity];
        [self performSelector:@selector(removeAnimator) withObject:Nil afterDelay:1.0f];
    } else {
        [self performSelector:@selector(decrementAnimator) withObject:nil afterDelay:1.0f];
    }
}

-(void)removeAnimator {
    
    [animator removeAllBehaviors];
    animator = nil;
    [animatorLabel removeFromSuperview];
    animatorLabel = nil;
}

-(void)dropBoxUploadBegin:(NSNotification *)n {
    [[SyncManager manager] updateProgressTitle:@"Dropbox"];
}

-(void)dropBoxUploadFinish:(NSNotification *)n {
    [[SyncManager manager] updateProgressTitle:@""];
    [[SyncManager manager] updateProgress:0.0f];
}

-(void)dropBoxUploadProgress:(NSNotification *)n {
    [[SyncManager manager] updateProgress:[[n.userInfo objectForKey:GSDropboxUploaderProgressKey] floatValue]];
}

-(void)dropBoxUploadFailed:(NSNotification *)n {
    [[SyncManager manager] updateProgressTitle:@""];
    [[SyncManager manager] updateProgress:0.0f];
}




-(void)toggleRecordingFromRemote:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(), ^{
       [self toggleRecording];
    });
}


-(void)toggleFocusLock:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([videoVC currentFocusLock]) {
            [self focusAuto];
        } else {
            [self focusLock];
        }
    });
}

-(void)toggleExposureLock:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([videoVC currentExposureLock]) {
            [self exposureAuto];
        } else {
            [self exposureLock];
        }});
}

-(void)toggleWhiteBalanceLock:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([videoVC currentWhiteBalanceLock]) {
            [self whiteBalanceAuto];
        } else {
            [self whiteBalanceLock];
        }
    });
}

-(void)sendEmailThankYouResponse:(NSNotification *)n {
    if ([n.object compare:@(MFMailComposeResultCancelled)] == NSOrderedSame) {
        return;
    }
    [self performSelector:@selector(sendEmailThankYouResponseToUser:) withObject:n.object afterDelay:3.0f];
}

-(void)sendEmailThankYouResponseToUser:(NSNumber *)result {
    [[UtilityBag bag] logEvent:@"supportemail" withParameters:@{ @"result" : result }];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = nil;
        
        if ([result compare:@(MFMailComposeResultFailed)] == NSOrderedSame) {
            alert = [[UIAlertView alloc] initWithTitle:@"Email Request" message:@"Your device was unable to send the email." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        } else if ([result compare:@(MFMailComposeResultSaved)] == NSOrderedSame) {
            alert = [[UIAlertView alloc] initWithTitle:@"Email Request" message:@"Your message was saved as a draft." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        } else {
            alert = [[UIAlertView alloc] initWithTitle:@"Email Request" message:@"Your request for help was sent to the developer." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        }
        
        [alert show];
    });
}

-(void)launchForHelp:(NSNotification *)n {
    if (popoverController) {
        [popoverController dismissPopoverAnimated:NO];
        popoverController = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self userPressedGradientAttributedButtonWithTag:4];
    });
}

-(void)addSettleTime:(NSNotification *)n {
    NSNumber *s = (NSNumber *)n.object;
    
    [videoVC addSettleTime:[s floatValue]];
}

-(void)launchForPurchase:(NSNotification *)n {
    if (popoverController) {
        [popoverController dismissPopoverAnimated:NO];
        popoverController = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            launchForPurchase = YES;
            //[self userPressedGradientAttributedButtonWithTag:1];
            [self performSelector:@selector(unsetLaunchForPurchase) withObject:nil afterDelay:1.0];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            ConfigureViewController *configureVC = [[ConfigureViewController alloc] initWithNibName:@"ConfigureViewController" bundle:nil];
            configureVC.launchForPurchase = YES;
            configureVC.popInsteadOfNotificationForClose = YES;
            [self.navigationController pushViewController:configureVC animated:YES];
            [self performSelector:@selector(unsetLaunchForPurchase) withObject:nil afterDelay:1.0];
        });
    }
}

-(void)unsetLaunchForPurchase {
    launchForPurchase = NO;
}



-(CGFloat)percentageFromDB:(CGFloat)decibels {
    CGFloat   level;                // The linear 0.0 .. 1.0 value we need.
    CGFloat   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.

    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        CGFloat   root            = 2.0f;
        CGFloat   minAmp          = powf(10.0f, 0.05f * minDecibels);
        CGFloat   inverseAmpRange = 1.0f / (1.0f - minAmp);
        CGFloat   amp             = powf(10.0f, 0.05f * decibels);
        CGFloat   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    return level;

}

-(void)audioLevelReport:(NSNotification *)n {
    NSArray *channels = n.object;
    
    CGFloat avg = [[[channels objectAtIndex:0] objectAtIndex:0] floatValue];
    
    if (avg == -1000.0f) {
        topBar.audioLPercentage = avg;
        topBar.audioRPercentage = avg;
    } else {
        topBar.audioLPercentage = [self percentageFromDB:avg];
        if ([channels count]>1) {
            avg = [[[channels objectAtIndex:1] objectAtIndex:0] floatValue];
            topBar.audioRPercentage = [self percentageFromDB:avg];
        } else {
            topBar.audioRPercentage = topBar.audioLPercentage;
        }
    }
}

-(void)updateFilterAttributes:(NSNotification *)n {
    NSArray *args = n.object;
    [videoVC updateFilterAttributesWithName:args[0] andDict:args[1]];
}

-(void)audioAACQualityDecrement {
    NSInteger quality = [[SettingsTool settings] audioAACQuality];
    
    quality--;
    
    if (quality < 1) {
        quality = 1;
    }
    
    [[SettingsTool settings] setAudioAACQuality:quality];
    [topDetail showControlsForSelected];
    [topBar update];

}

-(void)audioAACQualityIncrement {
    NSInteger quality = [[SettingsTool settings] audioAACQuality];
    
    quality++;
    
    if (quality > 5) {
        quality = 5;
    }
    
    [[SettingsTool settings] setAudioAACQuality:quality];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)audioSampleRateSet:(NSNotification *)n {
    [self setLastInteractionTimeToNow];
    double rate = [n.object doubleValue];
    
    [[SettingsTool settings] setAudioSamplerate:rate];
    [videoVC updateAudioCaptureSampleRate];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)fastCaptureModeEnabled {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFastCaptureMode:YES];
    [self performSelector:@selector(delayedUpdate) withObject:nil afterDelay:0.1];
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
}

-(void)fastCaptureModeDisabled {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFastCaptureMode:NO];
     [self performSelector:@selector(delayedUpdate) withObject:nil afterDelay:0.1];
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
}


-(void)unSuppressRecordButton {
    suppressRecordButton = NO;
}

//record doesn't
-(void)userTappedRecordButtonDown {
    [self setLastInteractionTimeToNow];
    if (suppressRecordButton) {
        return;
    }
    
    if (moveClipView) {
        return;
    }
    
    [self toggleRecording];
}

-(void)stopRecording:(NSNotification *)n {
    if ([videoVC isRecording]) {
        [videoVC stopRecording];
        [zoomBar stopRecording];
        [[StatusReporter manager] stopRecording];
        [self performSelector:@selector(updateTopBarStatusInfo) withObject:nil afterDelay:1.0f];
    }
}

-(void)startRecording:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![videoVC isRecording]) {
            [videoVC startRecording];
            [zoomBar startRecording];
            [[StatusReporter manager] startRecording];
            [self performSelector:@selector(updateTopBarStatusInfo) withObject:nil afterDelay:1.0f];
            suppressRecordButton = YES;
            [self performSelector:@selector(unSuppressRecordButton) withObject:nil afterDelay:2.0];
        }
    });
}

-(void)toggleRecording {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([videoVC isRecording]) {
            [videoVC stopRecording];
            [zoomBar stopRecording];
            [[StatusReporter manager] stopRecording];
            [self performSelector:@selector(updateTopBarStatusInfo) withObject:nil afterDelay:1.0f];
        } else {
            [videoVC startRecording];
            [zoomBar startRecording];
            [[StatusReporter manager] startRecording];
            [self performSelector:@selector(updateTopBarStatusInfo) withObject:nil afterDelay:1.0f];
            suppressRecordButton = YES;
            [self performSelector:@selector(unSuppressRecordButton) withObject:nil afterDelay:2.0];
        }
    });
}

-(void)isoLockAuto {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setIsoLock:0];
    [videoVC setExposureLock:NO];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)isoLockSet {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setIsoLock:[videoVC currentISO]];
    [topDetail showControlsForSelected];
    [topBar update];
}


-(void)whiteBalanceLock {
   [self setLastInteractionTimeToNow];
    [videoVC setWhiteBalanceLock:YES];
    topDetail.whiteBalanceLocked = YES;
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)whiteBalanceAuto {
   [self setLastInteractionTimeToNow];
    [videoVC setWhiteBalanceLock:NO];
    topDetail.whiteBalanceLocked = NO;
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)exposureAuto {
   [self setLastInteractionTimeToNow];
        //stored in camera; not saved
    [videoVC setExposureLock:NO];
    topDetail.exposureLocked = NO;
    [topDetail showControlsForSelected];
    [topBar update];
    [self positionReticles];
    [self delayedUpdate];
    [topDetail showControlsForSelected];
}

-(void)exposureLock {
   [self setLastInteractionTimeToNow];
        //stored in camera; not saved
    [videoVC setExposureLock:YES];
    topDetail.exposureLocked = YES;
    [topDetail showControlsForSelected];
    [topBar update];
     [self positionReticles];
    [self delayedUpdate];
    [topDetail showControlsForSelected];
}


-(void)exposureCenter {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setExposureMode:0];
    [topDetail showControlsForSelected];
    [topBar update];
    [self positionReticles];
    [topDetail showControlsForSelected];
}

-(void)exposureReticle {
  [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setExposureMode:1];
    [topDetail showControlsForSelected];
    [topBar update];
    [self positionReticles];
    [topDetail showControlsForSelected];
}

-(void)audioMonitoringDisable {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setAudioMonitoring:NO];
    [topDetail showControlsForSelected];
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
}

-(void)audioMonitoringEnable {
  [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setAudioMonitoring:YES];
    [topDetail showControlsForSelected];
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
}

-(void)audioAACEncodingDisable {
  [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setAudioOutputEncodingIsAAC:NO];
    [topDetail showControlsForSelected];
     [topBar update];
    [topDetail showControlsForSelected];
}

-(void)audioAACEncodingEnable {
  [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setAudioOutputEncodingIsAAC:YES];
    [topDetail showControlsForSelected];
     [topBar update];
    [topDetail showControlsForSelected];
}

-(void)audioCaptureSampleRateIncrement {
    [self setLastInteractionTimeToNow];
    double rate = [[SettingsTool settings] audioSamplerate];
    double newRate = 48000.0f;
    
    if (rate <= 8000.0f) {
        newRate = 11025.0f;
    } else if (rate == 11025.0f) {
        newRate = 16000.0f;
    } else if (rate == 16000.0f) {
        newRate = 22050.0f;
    } else if (rate == 22050.0f) {
        newRate = 32000.0f;
    } else if (rate == 32000.0f) {
        newRate = 44100.0f;
    } else if (rate > 44100.0f) {
        newRate = 48000.0f;
    }
    
    [[SettingsTool settings] setAudioSamplerate:newRate];
    [videoVC updateAudioCaptureSampleRate];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
    
}

-(void)audioCaptureSampleRateDecrement {
    [self setLastInteractionTimeToNow];
    double rate = [[SettingsTool settings] audioSamplerate];
    double newRate = 48000.0f;
    
    if (rate >= 48000.0f) {
        newRate = 44100.0f;
    } else if (rate == 44100.0f) {
        newRate = 32000.0f;
    } else if (rate == 32000.0f) {
        newRate = 22050.0f;
    } else if (rate == 22050.0f) {
        newRate = 16000.0f;
    } else if (rate == 16000.0f) {
        newRate = 11025.0f;
    } else {
        newRate = 8000.0f;
    }
    
    [[SettingsTool settings] setAudioSamplerate:newRate];
    [videoVC updateAudioCaptureSampleRate];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}


-(void)focusAuto {
    [self setLastInteractionTimeToNow];
        //stored in camera; not saved
    [videoVC setFocusLock:NO];
    topDetail.focusLocked = NO;
    [topDetail showControlsForSelected];
    [topBar update];
    [self positionReticles];
    [self delayedUpdate];
    [topDetail showControlsForSelected];
}

-(void)focusLock {
    [self setLastInteractionTimeToNow];
        //stored in camera; not saved
    [videoVC setFocusLock:YES];
    topDetail.focusLocked = YES;
    [topDetail showControlsForSelected];
    [topBar update];
    [self positionReticles];
    [self delayedUpdate];
    [topDetail showControlsForSelected];
}

-(void)focusCenter {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFocusMode:0];
    [topDetail showControlsForSelected];
    [topBar update];
    [self positionReticles];
    [topDetail showControlsForSelected];
}

-(void)focusReticle {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFocusMode:1];
    [topDetail showControlsForSelected];
    [topBar update];
    [self positionReticles];
    [topDetail showControlsForSelected];
}

-(void)focusRangeOff {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFocusRange:0];
    [videoVC setFocusRange:0];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)focusRangeNear {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFocusRange:1];
    [videoVC setFocusRange:1];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)focusRangeFar {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFocusRange:2];
    [videoVC setFocusRange:2];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)focusSpeedSmooth {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFocusSpeedSmooth:YES];
    [videoVC setFocusSpeedSmooth:YES];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)focusSpeedFast {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFocusSpeedSmooth:NO];
    [videoVC setFocusSpeedSmooth:NO];
    [topBar update];
    [topDetail showControlsForSelected];
}



-(void)cameraFront {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setCameraIsBack:NO];
    [[SettingsTool settings] setFastCaptureMode:NO];
    if ([[SettingsTool settings] isiPhone4] || [[SettingsTool settings] isiPhone4S] || [[SettingsTool settings] isiPad2] || [[SettingsTool settings] isiPad3]) {
        //640x480 camera; map it to 640x360
       [[SettingsTool settings] setCaptureOutputResolution:360];
    } else {
       [[SettingsTool settings] setCaptureOutputResolution:720];
    }
    
    
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)cameraBack {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setCameraIsBack:YES];
    if (![[SettingsTool settings] cameraIsBack]) {
        [[SettingsTool settings] setCaptureOutputResolution:[[SettingsTool settings] lastBackVideoCameraResolution]];
    }

    [videoVC restartCamera];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)cameraISDisable {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setCameraISEnabled:NO];
    [videoVC updateStabilization];
    [topDetail showControlsForSelected];
    [topDetail showControlsForSelected];
}

-(void)cameraISEnable {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setCameraISEnabled:YES];
    [videoVC updateStabilization];
    [topDetail showControlsForSelected];
    [topDetail showControlsForSelected];
}

-(void)cameraFlipDisable {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setCameraFlipEnabled:NO];
     [videoVC restartCamera];
    [topDetail showControlsForSelected];
    [topDetail showControlsForSelected];
}

-(void)cameraFlipEnable {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setCameraFlipEnabled:YES];
     [videoVC restartCamera];
    [topDetail showControlsForSelected];
    [topDetail showControlsForSelected];
}

-(void)rotationLockDisable {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setLockRotation:NO];
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!videoVC.isRecording) {
        appD.allowRotation = YES;
    }
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)rotationLockEnable {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setLockRotation:YES];
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = NO;
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}
-(void)captureFrameRateSet:(NSNotification *)n {
   [self setLastInteractionTimeToNow];
    NSInteger res = [n.object integerValue];
    
    
    if (res<1) {
        res = 1;
    } if (res > 120) {
        res = 120;
    }
    
    [[SettingsTool settings] setVideoCameraFrameRate:res];
    [videoVC updateFrameRate];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)captureFrameRateDecrement {
    [self setLastInteractionTimeToNow];
    NSInteger res = [[SettingsTool settings] videoCameraFrameRate];
    
    res--;
    
    if (res<1) {
        res = 1;
    }
    
    [[SettingsTool settings] setVideoCameraFrameRate:res];
    [videoVC updateFrameRate];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)captureFrameRateIncrement {
   [self setLastInteractionTimeToNow];
    NSInteger rate = [[SettingsTool settings] videoCameraFrameRate];
    
    rate++;
    
    if ([[SettingsTool settings] fastCaptureMode]) {
        if ([[SettingsTool settings] currentMaxFrameRate] < rate) {
            rate = [[SettingsTool settings] currentMaxFrameRate];
        }
    } else if (rate > 30) {
        rate = 30;
    }
    
    [[SettingsTool settings] setVideoCameraFrameRate:rate];
    [videoVC updateFrameRate];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(float)videoRateForOutputRes:(NSInteger)res {
   [self setLastInteractionTimeToNow];
    float rate = 0.0f;
    if ([[SettingsTool settings] fastCaptureMode]) {
        rate = [[SettingsTool settings] videoCameraVideoDataRateFastCaptureMode];
    } else {
        switch (res) {
            case 1080:
                rate = [[SettingsTool settings] videoCameraVideoDataRate1080];
                break;
            case 720:
                rate = [[SettingsTool settings] videoCameraVideoDataRate720];
                break;
            case 576:
                rate = [[SettingsTool settings] videoCameraVideoDataRate576];
                break;
            case 540:
                rate = [[SettingsTool settings] videoCameraVideoDataRate540];
                break;
            case 480:
                rate = [[SettingsTool settings] videoCameraVideoDataRate480];
                break;
            case 360:
                rate = [[SettingsTool settings] videoCameraVideoDataRate360];
                break;
        }
    }
    return rate;
}

-(void)setVideoRate:(float)rate forOutputResolution:(NSInteger)res {
    [self setLastInteractionTimeToNow];
    if ([[SettingsTool settings] fastCaptureMode]) {
        [[SettingsTool settings] setVideoCameraVideoDataRateFastCaptureMode:rate];
    } else {
        switch (res) {
            case 1080:
                [[SettingsTool settings] setVideoCameraVideoDataRate1080:rate];
                break;
            case 720:
                [[SettingsTool settings] setVideoCameraVideoDataRate720:rate];
                break;
            case 576:
                [[SettingsTool settings] setVideoCameraVideoDataRate576:rate];
                break;
            case 540:
                [[SettingsTool settings] setVideoCameraVideoDataRate540:rate];
                break;
            case 480:
                [[SettingsTool settings] setVideoCameraVideoDataRate480:rate];
                break;
            case 360:
                [[SettingsTool settings] setVideoCameraVideoDataRate360:rate];
                break;
        }
    }
}

-(void)captureVideoRateSetDefault {
   [self setLastInteractionTimeToNow];
    NSInteger res = [[SettingsTool settings] captureOutputResolution];
    [self setVideoRate:[[SettingsTool settings] defaultBitRateForResolution:res] forOutputResolution:res];
    
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];

}


-(void)captureVideoRateDecrement {
    [self setLastInteractionTimeToNow];
    NSInteger resolution = [[SettingsTool settings] captureOutputResolution];
    
    float rate = [self videoRateForOutputRes:resolution];
 
    float amount = 0.1f;
    if (resolution > 720) {
        amount = 0.5f;
    }
    
    rate -= amount * 1000000;
    
    if (rate < 100000) {
        rate = 100000;
    }
    
    [self setVideoRate:rate forOutputResolution:resolution];
    
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)captureVideoRateIncrement {
    
    [self setLastInteractionTimeToNow];
    NSInteger resolution = [[SettingsTool settings] captureOutputResolution];
    
    float rate = [self videoRateForOutputRes:resolution];
    
    float amount = 0.1f;
    if (resolution > 720) {
        amount = 0.5f;
    }

    rate += amount * 1000000;
    
    float maxRate = [[SettingsTool settings] maxBitRateForResolution:resolution];
    
    if (rate > maxRate) {
        rate = maxRate;
    }
    
    [self setVideoRate:rate forOutputResolution:resolution];

    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)captureOutputResolutionDecrement {
   [self setLastInteractionTimeToNow];
    NSInteger res = [[SettingsTool settings] captureOutputResolution];
    
    switch (res) {
        case 1080:
            res = 720;
            break;
        case 720:
            res = 576;
            break;
        case 576:
            res = 540;
            break;
        case 540:
            res = 480;
            break;
        case 480:
            res = 360;
            break;
            break;
    }
    
    [[SettingsTool settings] setCaptureOutputResolution:res];
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];

    
}

-(void)restartCameraForFeatureChange:(NSNotification *)n {
    [videoVC restartCamera];
    [topBar update];
}


-(void)captureOutputResolutionSet:(NSNotification *)n {
    [self setLastInteractionTimeToNow];
    NSInteger newRes = [(NSNumber *)n.object integerValue];
    NSInteger res = [[SettingsTool settings] captureOutputResolution];
    
    switch (newRes) {
        case 360:
            res = 360;
            break;
        case 480:
            res = 480;
            break;
        case 540:
            res = 540;
            break;
        case 576:
            res = 576;
            break;
        case 720:
            res = 1080;
            break;
        case 1080:
            res = 1080;
            break;

    }
    
    [[SettingsTool settings] setCaptureOutputResolution:res];
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}



-(void)captureOutputResolutionIncrement {
   [self setLastInteractionTimeToNow];
    NSInteger res = [[SettingsTool settings] captureOutputResolution];
    
    
    switch (res) {
        case 360:
            res = 480;
            break;
        case 480:
            res = 540;
            break;
        case 540:
            res = 576;
            break;
        case 576:
            res = 720;
            break;
        case 720:
            res = 1080;
            break;
    }
    
    [[SettingsTool settings] setCaptureOutputResolution:res];
    [videoVC restartCamera];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}


-(void)positionElements {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
                // NSLog(@"iPad landscape");
            self.view.frame = CGRectMake(0,0,1024,768);
        }
    }
    
    CGRect f = self.view.frame;
    
    CGRect g = CGRectZero; //videoVC.frame
    CGRect t = CGRectZero; //topBar.frame
    CGRect d = CGRectZero; // topDetail.frame
    CGRect z = CGRectZero; // zoomBar.frame;
    
    if (interfaceHidden) {
        switch ((NSInteger)f.size.width) {
            case 1024:
            {
                g = CGRectMake(0,97,1024,574);
                
                z = CGRectMake(0,768-50,1024,50);
                t = CGRectMake(0,0,1024,50);
                d = CGRectMake(0,0,1024,768 - 90);
            }
                break;
            case 568:
            {
                g = CGRectMake(0,0,568,320);
                t = CGRectMake(0,0,568,30);
                d = CGRectMake(0,20,568,250);
                z = CGRectMake(0,320-44,568,44);
               
                
            }
                break;
            case 480:
            {
                g = CGRectMake(0,25,480,270);
                t = CGRectMake(0,0,480,30);
                d = CGRectMake(0,20,480,250);
                z = CGRectMake(0,320-44,480,44);
            }
                break;
        }

    } else {
        switch ((NSInteger)f.size.width) {
            case 1024:
            {
                g = [[SettingsTool settings] iPadVideoViewRect];

                
            
                z = CGRectMake(0,768-50,1024,50);
                t = CGRectMake(0,0,568,50);
                d = CGRectMake(0,40,1024,768 - 90);
            }
                break;
            case 568:
            {
                g = CGRectMake(2,20,438,246);
                t = CGRectMake(0,0,568,30);
              
                d = CGRectMake(0,20,568,260);
                z = CGRectMake(0,321,568,25);
            }
                break;
            case 480:
            {
                g = CGRectMake(2,45,350,197);
                t = CGRectMake(0,0,480,30);
        
                d = CGRectMake(0,20,480,260);
                z = CGRectMake(0,321,480,25);
            }
                break;
        }
    }
    
    videoVC.frame = g;
    topBar.frame = t;
  
    topDetail.frame = d;
    reticlePane.frame = g;
    zoomBar.frame = z;
    
    [videoVC updateInterfaceHidden:interfaceHidden];
    
    if (interfaceHidden) {
        [configureButton removeFromSuperview];
        [libraryButton removeFromSuperview];
        [engineButton removeFromSuperview];
        [helpButton removeFromSuperview];
        [optionScroller removeFromSuperview];
        [self.view bringSubviewToFront:zoomBar];
    } else {
        if (!videoVC.isRecording) {
            [self.view addSubview:configureButton];
            [self.view addSubview:libraryButton];
            [self.view addSubview:engineButton];
            [self.view addSubview:helpButton];
            
            [self.view bringSubviewToFront:configureButton];
            [self.view bringSubviewToFront:libraryButton];
            [self.view bringSubviewToFront:engineButton];
            [self.view bringSubviewToFront:helpButton];
            if (reviewView) {
                [self.view bringSubviewToFront:reviewView];
            }
           
            configureButton.hidden = NO;
            libraryButton.hidden = NO;
            engineButton.hidden = NO;
            helpButton.hidden = NO;
        }
       
        [self.view addSubview:optionScroller];
        [self.view bringSubviewToFront:optionScroller];
        optionScroller.hidden = NO;
    }
    
    if (interfaceHidden) {
        zoomBar.supportsZoom = [videoVC zoomSupported];
        [zoomBar updateSize];
    }
    [self performSelector:@selector(checkZoomBar) withObject:nil afterDelay:2.0f];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        optionScroller.frame = CGRectMake(5,5,optionScroller.bounds.size.width, optionScroller.bounds.size.height);
        [iPadDetailButtonTray addSubview:optionScroller];
        
        
        libraryButton.frame = CGRectMake(10,50,libraryButton.bounds.size.width, libraryButton.bounds.size.height);
        configureButton.frame = CGRectMake(120,50,libraryButton.bounds.size.width, libraryButton.bounds.size.height);
        engineButton.frame = CGRectMake(230,50,libraryButton.bounds.size.width, libraryButton.bounds.size.height);
        helpButton.frame = CGRectMake(340,50,libraryButton.bounds.size.width, libraryButton.bounds.size.height);
        
        [iPadMainButtonTray addSubview:libraryButton];
        [iPadMainButtonTray addSubview:configureButton];
        [iPadMainButtonTray addSubview:engineButton];
        [iPadMainButtonTray addSubview:helpButton];
        
        iPadMainButtonTray.hidden = interfaceHidden;
        iPadDetailButtonTray.hidden = interfaceHidden;
        iPadDetailTray.hidden = interfaceHidden;
        iPadHistogramTray.hidden = interfaceHidden;
        
        iPadMainButtonTray.hidden = interfaceHidden || videoVC.isRecording;
       
        [self.view bringSubviewToFront:iPadHistogramTray];
        [self.view bringSubviewToFront:iPadDetailTray];
        [self.view bringSubviewToFront:iPadDetailButtonTray];
        [self.view bringSubviewToFront:iPadMainButtonTray];
     
        
        zoomBar.hidden = NO;
        [self.view bringSubviewToFront:zoomBar];
        
        [iPadHistogramTray addSubview:[topDetail histogramView]];
        topDetail.histogramView.frame = CGRectMake(0,0,256,100);
        
    }
    [topBar update];
}

-(void)setInterfaceHidden {
     [self hideInterface:interfaceHidden];
    [self positionElements];
}

-(void)checkZoomBar {
    zoomBar.supportsZoom = [videoVC zoomSupported];
    [zoomBar updateSize];
    
    [self setupZoomButtons];
}

-(void)positionReticles {
    
    NSInteger focusMode = [[SettingsTool settings] focusMode];
    
    if (focusMode == 1) {
        if (!focusReticle) {
            CGRect f = CGRectMake(150,50,50,50);
            focusReticle = [[FocusReticleView alloc] initWithFrame:f];
            UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:videoVC action:@selector(focusReticleTapped:)];
            UIPanGestureRecognizer *panG = [[UIPanGestureRecognizer alloc] initWithTarget:videoVC action:@selector(focusReticlePanned:)];
            [focusReticle addGestureRecognizer:tapG];
            [focusReticle addGestureRecognizer:panG];
        }
        if (focusReticle.superview != reticlePane) {
            [reticlePane addSubview:focusReticle];
        }
        
    } else {
        if (focusReticle) {
            [focusReticle removeFromSuperview];
            focusReticle = nil;
        }
    }
    
    
    NSInteger exposureMode = [[SettingsTool settings] exposureMode];
    if (exposureMode == 1) {
        if (!exposureReticle) {
            CGRect f = CGRectMake(350,50,50,50);
            exposureReticle = [[ExposureReticleView alloc] initWithFrame:f];
            UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:videoVC action:@selector(exposureReticleTapped:)];
            UIPanGestureRecognizer *panG = [[UIPanGestureRecognizer alloc] initWithTarget:videoVC action:@selector(exposureReticlePanned:)];
            [exposureReticle addGestureRecognizer:tapG];
            [exposureReticle addGestureRecognizer:panG];
        }
        if (exposureReticle.superview != reticlePane) {
            [reticlePane addSubview:exposureReticle];
        }
    } else {
        if (exposureReticle) {
            [exposureReticle removeFromSuperview];
            exposureReticle = nil;
        }
    }
    [self.view bringSubviewToFront:reticlePane];
    [self.view bringSubviewToFront:zoomBar];
}

-(void)spritImage:(NSNotification *)n {
    UIImage *i = (UIImage *)n.object;
    UIImageView *iv = (UIImageView *)[self.view viewWithTag:9999];
    iv.image =i;
}

-(void)viewDidAppear:(BOOL)animated {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [super viewDidAppear:animated];
   
    if ([[RemoteBrowserManager manager] isRunning]) {
        [[RemoteBrowserManager manager] stopSession];
        if ([[SettingsTool settings] engineRemote]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [NSThread sleepForTimeInterval:1.0f];
                dispatch_async(dispatch_get_main_queue(), ^{
                     [appD handleRemoteSessionSetup];
                });
            });
        }
    }
    
    [self updateForiPadOrientation];
    
    if ( (![videoVC isRunning]) && (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) ) {
        [videoVC startCamera];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanup" object:nil];
    
    if (1 == 2) {
        if (!spriteTitlingTool) {
            spriteTitlingTool = [[SpriteTitlingTool alloc] init];
        }
        [spriteTitlingTool setupWithDict:nil];
        [spriteTitlingTool presentInView:self.view];
        NSString *mPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[UtilityBag bag] pathForNewResourceWithExtension:@"mov"]];
        [spriteTitlingTool recordToPath:mPath forLength:10];
        
        UIImageView *i = [[UIImageView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:i];
        i.contentMode = UIViewContentModeScaleAspectFit;
        i.tag = 9999;
        i.frame = CGRectZero;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spritImage:) name:@"spriteFrame" object:nil];
        
        
    }
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ) {
        if (!firstStartupCompleted) {
             appD.allowRotation = NO;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),  ^{
                [NSThread sleepForTimeInterval:3.0f];
                dispatch_async(dispatch_get_main_queue(), ^{
                    appD.allowRotation = YES;
                });
            });
        }
    }
    
    
    
    
    firstStartupCompleted = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   
    [self setupRightHandButtons];
    
    [self performSelector:@selector(setupZoomButtons) withObject:nil afterDelay:1.0];
    self.view.alpha = 0.02f;
    self.view.alpha = 1.00f;
    [self performSelector:@selector(positionElements) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(fixAlpha) withObject:nil afterDelay:1.01];
    [self.view bringSubviewToFront:zoomBar];
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        UIView *rotationBanner = [self.view viewWithTag:99999];
        rotationBanner.alpha = 0.05f;
    }
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    if (!interfaceHidden) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            iPadDetailTray.hidden = NO;
            iPadMainButtonTray.hidden = NO;
            iPadDetailButtonTray.hidden = NO;
            iPadHistogramTray.hidden = NO;
        } else {
            engineButton.hidden = NO;
            libraryButton.hidden = NO;
            configureButton.hidden = NO;
            helpButton.hidden = NO;
            optionScroller.hidden = NO;
        }
        [topDetail showControlsForSelected];
    }
    
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = ![[SettingsTool settings] lockRotation];
                          
}

-(void)fixAlpha {
    self.view.alpha = 1.0f;
}

-(void)updateTopBarStatusInfo {

    topBar.displayAdvancedControls = ([[SettingsTool settings] engineHistogram] || [[SettingsTool settings] advancedFiltersAvailable]);
    
    topBar.recording = [videoVC isRecording];
    
    [topBar update];
    
    [topDetail setSelected:topBar.selected];
   
    topDetail.isRecording = videoVC.isRecording;
    [topDetail setNeedsDisplay];
    
    topDetail.supportsFrontCamera = [videoVC frontCameraSupported];
    
    [topDetail performSelector:@selector(showControlsForSelected) withObject:nil afterDelay:0.01];
    
}

- (BOOL)shouldAutorotate  {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return appD.allowRotation;
}

- (NSUInteger)supportedInterfaceOrientations  {
    NSInteger supported = UIInterfaceOrientationMaskAll;
    return supported;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [videoVC dontUpdateVideoView:@(YES)];
    
    if (popoverController) {
        [popoverController dismissPopoverAnimated:NO];
        popoverController = nil;
    }
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [videoVC performSelector:@selector(dontUpdateVideoView:) withObject:@(NO) afterDelay:1.0f];
        UIView *v = [self.view viewWithTag:99999];
        if (v) {
            v.alpha = 0.02f;
        }
    } else {
        self.view.alpha = 0.02f;
        [self performSelector:@selector(fixAlpha) withObject:nil afterDelay:1.02];
    }
}


-(void)updateForiPadOrientation {
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        return;
    }
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        [self removeRotationBanner];
        if (!interfaceHidden) {
            iPadMainButtonTray.hidden = NO;
            iPadDetailButtonTray.hidden = NO;
            iPadDetailTray.hidden = NO;
            iPadHistogramTray.hidden = NO;
        }
        focusReticle.hidden = NO;
        exposureReticle.hidden = NO;
    } else {
        [self addRotationBanner];
        if (!interfaceHidden) {
            iPadMainButtonTray.hidden = YES;
            iPadDetailButtonTray.hidden = YES;
            iPadDetailTray.hidden = YES;
            iPadHistogramTray.hidden = YES;
        }
        focusReticle.hidden = YES;
        exposureReticle.hidden = YES;
    }
    
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"rotate");
    
    if ([self.navigationController.viewControllers count] > 1) {
        return;
    }
    
    [self setLastInteractionTimeToNow];
    [self positionElements];
    [videoVC didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
  
    [self updateForiPadOrientation];
    
}


-(void)addRotationBanner {
    UIView *v = [self.view viewWithTag:99999];
    if (v) {
        [v removeFromSuperview];
    }
    
    v = [[UIView alloc] initWithFrame:self.view.bounds];
    v.tag = 99999;
    v.backgroundColor = [UIColor blackColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,v.bounds.size.width,50)];
    l.backgroundColor = [UIColor whiteColor];
    l.text = @"Rotate Device For Camera";
    l.textAlignment = NSTextAlignmentCenter;
    l.textColor = [UIColor blackColor];
    l.font = [UIFont boldSystemFontOfSize:30];
    l.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [v addSubview:l];
    
  
    
    GradientAttributedButton *lButton = [self buttonWithSetup:@{  @"tag" : @2,
                                              @"selected" : @NO,
                                              @"text" : @"Library",
                                              @"frame" : [NSValue valueWithCGRect:CGRectMake(100,800,140,50)]
                                              }];
    
    GradientAttributedButton *hButton = [self buttonWithSetup:@{  @"tag" : @4,
                                           @"selected" : @NO,
                                           @"text" : @"Help",
                                           @"frame" : [NSValue valueWithCGRect:CGRectMake(528,800,140,50)]
                                           }];
    
    lButton.delegate = self;
    hButton.delegate = self;
    
    [lButton update];
    [hButton update];
    
    [v addSubview:lButton];
    [v addSubview:hButton];
    
    
    
    UIView *batteryContainer = [[UIView alloc] initWithFrame:CGRectMake(256-40, 200, 80, 500)];
    UIView *diskContainer = [[UIView alloc] initWithFrame:CGRectMake(512-40, 200, 80, 500)];
    batteryContainer.clipsToBounds = NO;
    diskContainer.clipsToBounds = NO;
    
    batteryContainer.layer.borderColor = [UIColor darkGrayColor].CGColor;
    batteryContainer.layer.borderWidth = 3.0f;
    batteryContainer.layer.masksToBounds = NO;
   
    diskContainer.layer.borderColor = [UIColor darkGrayColor].CGColor;
    diskContainer.layer.borderWidth = 3.0f;
    diskContainer.layer.masksToBounds = NO;
    
    UILabel *batteryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 500, 80, 30)];
    batteryLabel.backgroundColor = [UIColor clearColor];
    batteryLabel.textColor = [UIColor whiteColor];
    batteryLabel.textAlignment = NSTextAlignmentCenter;
    batteryLabel.text = @"Battery";
    [batteryContainer addSubview:batteryLabel];
    
    UILabel *diskLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 500, 80, 30)];
    diskLabel.backgroundColor = [UIColor clearColor];
    diskLabel.textColor = [UIColor whiteColor];
    diskLabel.textAlignment = NSTextAlignmentCenter;
    diskLabel.text = @"Storage";
    [diskContainer addSubview:diskLabel];
    
    
    CGFloat batHeight = 500.0 * [[StatusReporter manager] battery];
    CGFloat diskHeight = 500.0 * [[StatusReporter manager] disk];
    
    UILabel *batSpace = [[UILabel alloc] initWithFrame:CGRectMake(0, 500 - batHeight, 80, batHeight)];
    UILabel *diskSpace = [[UILabel alloc] initWithFrame:CGRectMake(0, 500 - diskHeight, 80, diskHeight)];
    batSpace.backgroundColor = [UIColor greenColor];
    diskSpace.backgroundColor = [UIColor greenColor];
    
    [batteryContainer addSubview:batSpace];
    [diskContainer addSubview:diskSpace];
   
    
    [v addSubview:batteryContainer];
    [v addSubview:diskContainer];
    
    
    
    
    
    
    
    v.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:v];
    
}

-(void)userTappedLibraryFromPortrait {
    
}

-(void)removeRotationBanner {
    BOOL found = YES;
    BOOL hasRestarted = NO;
    while ( found) {
        UIView *v = [self.view viewWithTag:99999];
        found = (v != nil);
        [v removeFromSuperview];
        if (!hasRestarted) {
            hasRestarted = YES;
            [self positionElements];
            [self restartCameraForFeatureChange:Nil];
            [videoVC positionVideoPreview];
            [videoVC dontUpdateVideoView:@(NO)];
        }
        
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





// Contrast ranges from 0.0 to 4.0 (max contrast), with 1.0 as the normal level
// Saturation ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 1.0 as the normal level
// Brightness ranges from -1.0 to 1.0, with 0.0 as the normal level


-(void)contrastDecrement {
    [self setLastInteractionTimeToNow];
    float oVal = [[SettingsTool settings] videoContrast];
    
    float val = oVal;
    
    val -= 0.05f;
    
    if (val < 0.0f) {
        val = 0.0f;
    }
    
    if (oVal != val) {
        [videoVC updateContrast:val];
        [[SettingsTool settings] setVideoContrast:val];
    }
    
    [topDetail showControlsForSelected];
    [topBar update];
    
}

-(void)contrastDefault {
   [self setLastInteractionTimeToNow];
    [videoVC updateContrast:1.0f];
    [[SettingsTool settings] setVideoContrast:1.0f];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)contrastIncrement {
    [self setLastInteractionTimeToNow];
    float oVal = [[SettingsTool settings] videoContrast];
    
    float val = oVal;
    
    val += 0.05f;
    
    if (val > 4.0f) {
        val = 4.0f;
    }
    
    if (oVal != val) {
        [videoVC updateContrast:val];
        [[SettingsTool settings] setVideoContrast:val];
    }
    [topDetail showControlsForSelected];
    [topBar update];
}


-(void)saturationDecrement {
   [self setLastInteractionTimeToNow];
    float oVal = [[SettingsTool settings] videoSaturation];
    
    float val = oVal;
    
    val -= 0.05f;
    
    if (val < 0.0f) {
        val = 0.0f;
    }
    
    if (oVal != val) {
        [videoVC updateSaturation:val];
        [[SettingsTool settings] setVideovideoSaturation:val];
    }
    
    [topDetail showControlsForSelected];
    [topBar update];

}

-(void)saturationDefault {
    [self setLastInteractionTimeToNow];
    [videoVC updateSaturation:1.0f];
    [[SettingsTool settings] setVideovideoSaturation:1.0f];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)saturationIncrement {
   [self setLastInteractionTimeToNow];
    float oVal = [[SettingsTool settings] videoSaturation];
    
    float val = oVal;
    
    val += 0.05f;
    
    if (val > 2.0f) {
        val = 2.0f;
    }
    
    if (oVal != val) {
        [videoVC updateSaturation:val];
        [[SettingsTool settings] setVideovideoSaturation:val];
    }
    [topDetail showControlsForSelected];
    [topBar update];

}



-(void)brightnessDecrement {
   [self setLastInteractionTimeToNow];
    float oVal = [[SettingsTool settings] videoBrightness];
    
    float val = oVal;
    
    val -= 0.05f;
    
    if (val < -1.0f) {
        val = -1.0f;
    }
    
    if (oVal != val) {
        [videoVC updateBrightness:val];
        [[SettingsTool settings] setVideoBrightness:val];
    }
    
    [topDetail showControlsForSelected];
    [topBar update];

}

-(void)brightnessDefault {
  [self setLastInteractionTimeToNow];
    [videoVC updateBrightness:0.0f];
    [[SettingsTool settings] setVideoBrightness:0.0f];
    [topDetail showControlsForSelected];
    [topBar update];
}

-(void)brightnessIncrement {
   [self setLastInteractionTimeToNow];
    float oVal = [[SettingsTool settings] videoBrightness];
    
    float val = oVal;
    
    val += 0.05f;
    
    if (val > 1.0f) {
        val = 1.0f;
    }
    
    if (oVal != val) {
        [videoVC updateBrightness:val];
        [[SettingsTool settings] setVideoBrightness:val];
    }
    [topDetail showControlsForSelected];
    [topBar update];

}

-(void)torchOff {
    [self setLastInteractionTimeToNow];
    [videoVC extinguishTorch];
    topDetail.torchLevel = [videoVC torchSetting];
    topDetail.torchActive = ([videoVC torchSetting] > 0.0f);
    
    [self performSelector:@selector(delayedUpdate) withObject:nil afterDelay:0.1];
    [topDetail showControlsForSelected];
}

-(void)torchOn {
   [self setLastInteractionTimeToNow];
    float torchLevel = [[SettingsTool settings] torchLevelRequested];
    [videoVC lightTorch:torchLevel];
    topDetail.torchLevel = [videoVC torchSetting];
    topDetail.torchActive = ([videoVC torchSetting] > 0.0f);
    
    
   [self performSelector:@selector(delayedUpdate) withObject:nil afterDelay:0.1];
    [topDetail showControlsForSelected];
}

-(void)torchLevelDecrement {
    [self setLastInteractionTimeToNow];
    float torchLevel = [[SettingsTool settings] torchLevelRequested];
    torchLevel -= 0.1;
    if (torchLevel <0.1) {
        torchLevel = 0.1;
    }
    
    [[SettingsTool settings] setTorchLevelRequested:torchLevel];
    
    if ([videoVC torchSetting] > 0.0f) {
        [videoVC lightTorch:torchLevel];
    }
    
    [videoVC lightTorch:torchLevel];

    
    [self performSelector:@selector(delayedUpdate) withObject:nil afterDelay:0.1];
    [topDetail showControlsForSelected];
}

-(void)delayedUpdate {


    topDetail.focusLocked = [videoVC currentFocusLock];
    topDetail.exposureLocked = [videoVC currentExposureLock];
    topDetail.whiteBalanceLocked = [videoVC currentWhiteBalanceLock];

    topDetail.torchLevel = [videoVC torchSetting];
    topDetail.torchActive = ([videoVC torchSetting] > 0.0f);
    
    [topDetail showControlsForSelected];
    [topBar update];
    
    focusReticle.locked = topDetail.focusLocked;
    exposureReticle.locked = topDetail.exposureLocked;
    
    [focusReticle update];
    [exposureReticle update];
    
    [self.view bringSubviewToFront:reticlePane];
    [self.view bringSubviewToFront:zoomBar];
    
}


-(void)torchLevelMiddle {
    [self setLastInteractionTimeToNow];
    CGFloat torchLevel = 0.5;

    [[SettingsTool settings] setTorchLevelRequested:torchLevel];
    
    if ([videoVC torchSetting] > 0.0f) {
         [videoVC lightTorch:torchLevel];
    }
    
    [self performSelector:@selector(delayedUpdate) withObject:nil afterDelay:0.1];
    [topDetail showControlsForSelected];
}

-(void)torchLevelIncrement {
   [self setLastInteractionTimeToNow];
    float torchLevel = [[SettingsTool settings] torchLevelRequested];
    torchLevel += 0.1;
    if (torchLevel > 1.0) {
        torchLevel = 1.0;
    }
    
    [[SettingsTool settings] setTorchLevelRequested:torchLevel];
    if ([videoVC torchSetting] > 0.0f) {
        [videoVC lightTorch:torchLevel];
    }
    
   [self performSelector:@selector(delayedUpdate) withObject:nil afterDelay:0.1];

 [topDetail showControlsForSelected];
}

-(void)horizonGuideOff {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setHorizonGuide:NO];
    [videoVC showGuidePaneHorizon:NO];
    [topDetail showControlsForSelected];
    [[LocationHandler tool] sendMotionUpdates:NO];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)horizonGuideOn {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setHorizonGuide:YES];
    [videoVC showGuidePaneHorizon:YES];
    [topDetail showControlsForSelected];
    [[LocationHandler tool] sendMotionUpdates:YES];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)thirdsGuideOff {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setThirdsGuide:NO];
    [videoVC updateThirdsGuide:NO];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)thirdsGuideOn {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setThirdsGuide:YES];
    [videoVC updateThirdsGuide:YES];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)framingGuideOff {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFramingGuide:0];
    [videoVC updateFramingGuide:0];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)framingGuide43 {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFramingGuide:1];
    [videoVC updateFramingGuide:1];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)framingGuide11 {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setFramingGuide:2];
    [videoVC updateFramingGuide:2];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}




-(void)zoomPosition1Unset {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setZoomPosition1:0.0f];
    [videoVC updateZoomUI];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)zoomPosition1Set {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setZoomPosition1:[videoVC currentZoomLevel] / [videoVC maxZoomLevel]];
    [videoVC updateZoomUI];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)zoomPosition2Unset {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setZoomPosition2:0.0f];
    [videoVC updateZoomUI];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)zoomPosition2Set {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setZoomPosition2:[videoVC currentZoomLevel] / [videoVC maxZoomLevel]];
    [videoVC updateZoomUI];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)zoomPosition3Unset {
    [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setZoomPosition3:0.0f];
    [videoVC updateZoomUI];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)zoomPosition3Set {
   [self setLastInteractionTimeToNow];
    [[SettingsTool settings] setZoomPosition3:[videoVC currentZoomLevel] / [videoVC maxZoomLevel]];
    [videoVC updateZoomUI];
    [topDetail showControlsForSelected];
    [topBar update];
    [topDetail showControlsForSelected];
}

-(void)zoomSpeedIncrement {
   [self setLastInteractionTimeToNow];
    float rate = [[SettingsTool settings] zoomRate];
    rate += 0.1;
    if (rate > 4.0f) {
        rate = 4.0f;
    }
    [[SettingsTool settings] setZoomRate:rate];
    [videoVC setZoomRate:rate];
    repeatDelay = 0.2;
    [self showZoomSpeedLabel:rate];
}

-(void)showZoomSpeedLabel:(float)rate {
    
    if (!zoomSpeedLabel) {
        CGRect f = self.view.frame;
        
        zoomSpeedLabel = [[UILabel alloc] initWithFrame:CGRectMake((f.size.width/2) - 30, f.size.height - 100, 60,40)];
        zoomSpeedLabel.backgroundColor = [UIColor whiteColor];
        zoomSpeedLabel.textColor = [UIColor blackColor];
        zoomSpeedLabel.textAlignment = NSTextAlignmentCenter;
        zoomSpeedLabel.layer.cornerRadius = 5;
        zoomSpeedLabel.layer.masksToBounds = YES;
    }
    
    zoomSpeedLabel.text = [NSString stringWithFormat:@"%0.1f%%", rate * 25.0f];
    [self.view addSubview:zoomSpeedLabel];
}

-(void)hideZoomSpeedLabel {
    [zoomSpeedLabel removeFromSuperview];
    zoomSpeedLabel = nil;
}


-(void)zoomSpeedDecrement {
    [self setLastInteractionTimeToNow];
    float rate = [[SettingsTool settings] zoomRate];
    rate -= 0.1f;
    if (rate < 0.1f) {
        rate = 0.1f;
    }
    [[SettingsTool settings] setZoomRate:rate];
    [videoVC setZoomRate:rate];
    repeatDelay = 0.2;
    [self showZoomSpeedLabel:rate];
}


-(void)zoomBarZoomOutDown {
  [self setLastInteractionTimeToNow];
    [videoVC zoomToLevel:1 withSpeed:[[SettingsTool settings] zoomRate]];
}

-(void)zoomBarZoomOutUp {
  [self setLastInteractionTimeToNow];
    [videoVC stopZoomingImmediately];
}

-(void)zoomBarZoomSpeedLessDown {
    [self setLastInteractionTimeToNow];
    zoomSpeedDirection = 1;
    [self zoomSpeedDecrement];
    
}

-(void)zoomBarZoomSpeedLessUp {
    [self setLastInteractionTimeToNow];
    zoomSpeedDirection = 0;
    repeatDelay = 0.0f;
    [self performSelector:@selector(hideZoomSpeedLabel) withObject:nil afterDelay:0.1];
}


-(void)zoomBarPicDown {
    
}

-(void)zoomBarPicUp {
    
}

-(void)handleStillImageRequest:(NSNotification *)n {
    [self setLastInteractionTimeToNow];
    
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        return;
    }
    
    if ([[SettingsTool settings] isOldDevice]) {
        [videoVC takeStill];
    } else if ([[SettingsTool settings] fastCaptureMode]) {
        [videoVC takeStill];
    } else {
        //if ([videoVC isRecording]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"handleVideoStillImageRequest" object:nil];
        //} else {
        //    [videoVC takeStill];
        //}
    }
}



-(void)zoomBarZoomSpeedMoreDown {
    [self setLastInteractionTimeToNow];
    zoomSpeedDirection = 2;
    [self zoomSpeedIncrement];
}

-(void)zoomBarZoomSpeedMoreUp {
    [self setLastInteractionTimeToNow];
    zoomSpeedDirection = 0;
    repeatDelay = 0.0f;
    [self performSelector:@selector(hideZoomSpeedLabel) withObject:nil afterDelay:0.1];
}


-(void)zoomBarZoomInDown {
    [self setLastInteractionTimeToNow];
    float maxZoom = [videoVC maxZoomLevel];
     [videoVC zoomToLevel:maxZoom withSpeed:[[SettingsTool settings] zoomRate]];
}

-(void)zoomBarZoomInUp {
    [self setLastInteractionTimeToNow];
    [videoVC stopZoomingImmediately];
}

-(void)moveClipToCameraRoll:(NSNotification *)n {
    NSString *videoPath = (NSString *)n.object;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (moveClipView)  {
            [self removeMoveClipView];
        }
        
        moveClipView = [[UILabel alloc] initWithFrame:CGRectMake(0,50,200,13)];
        
        NSDictionary *stdDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[[[UtilityBag bag] standardFontBold] fontWithSize:13],[UIColor greenColor], [[UtilityBag bag] getBlackShadowForText], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, nil]];
      
        moveClipView.attributedText = [[NSAttributedString alloc] initWithString:@"Moving Clip To Camera Roll" attributes:stdDrawAttrbs];
     
        [videoVC addSubview:moveClipView];
        
        moveClipIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        CGRect r = moveClipView.frame;
        moveClipIndicator.frame = CGRectMake(r.origin.x + r.size.width + 10, r.origin.y, 13,13);
        [videoVC addSubview:moveClipIndicator];
        [moveClipIndicator startAnimating];
        
    });
    
    [[AssetManager manager] performSelectorInBackground:@selector(moveClipToAlbum:) withObject:videoPath];
}

-(void)removeMoveClipView {
    [moveClipView removeFromSuperview];
    moveClipView = nil;
    [moveClipIndicator stopAnimating];
    [moveClipIndicator removeFromSuperview];
    moveClipIndicator = nil;
}

-(void)clipMoveReport:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [videoVC dontUpdateVideoView:@(NO)];
        if (moveClipView) { //not when in activity view move clip
            if ([[args objectAtIndex:1] boolValue] == YES) {
                NSDictionary *stdDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[[[UtilityBag bag] standardFontBold] fontWithSize:13],[UIColor greenColor], [[UtilityBag bag] getBlackShadowForText], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, nil]];
                
                moveClipView.attributedText = [[NSAttributedString alloc] initWithString:@"Complete" attributes:stdDrawAttrbs];
                [self performSelector:@selector(removeMoveClipView) withObject:nil afterDelay:1.0f];
            } else {
                NSDictionary *stdDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[[[UtilityBag bag] standardFontBold] fontWithSize:13],[UIColor redColor], [[UtilityBag bag] getBlackShadowForText], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, nil]];
                
                moveClipView.attributedText = [[NSAttributedString alloc] initWithString:[args objectAtIndex:2] attributes:stdDrawAttrbs];
                [self performSelector:@selector(removeMoveClipView) withObject:nil afterDelay:10.0f];
            }
        }
        if (!videoVC.isRunning) {
            [videoVC startCamera];
        }
    });
}


-(void)resetAfterModalDialog:(NSNotification *)n {
    interfaceHidden = YES;
    [self setPaneTapMode:YES];
    
    [self setLastInteractionTimeToNow];
    [videoVC addSettleTime:3.5f];
    
    [self positionElements];
    reticlePane.hidden = NO;
    optionScroller.hidden = NO;
    [videoVC removeGestureRecognizer:paneTapG];
    [reticlePane addGestureRecognizer:paneTapG];
    [self.view sendSubviewToBack:videoVC];
    [topDetail showControlsForSelected];
    [self updateTopBarStatusInfo];
    [topBar update];
    
    if (!videoVC.isRunning) {
        [videoVC startCamera];
    }

}

-(BOOL)cameraIsRunning {
    return videoVC.isRunning;
}

-(void)reloadAfterPresetChange:(NSNotification *)n {
    
    [videoVC stopCamera];
    
    if ([[SettingsTool settings] lockRotation]) {
        [self rotationLockEnable];
    } else {
        [self rotationLockDisable];
    }
    
    [[LocationHandler tool] shutdown];
    
    [[LocationHandler tool] performSelector:@selector(startup) withObject:nil afterDelay:1.0f];
    
    if ([[SettingsTool settings] horizonGuide]) {
        [self horizonGuideOn];
    } else {
        [self horizonGuideOff];
    }
    
    switch ([[SettingsTool settings] framingGuide]) {
        case  0:
            [self framingGuideOff];
            break;
        case  1:
            [self framingGuide43];
            break;
        case  2:
            [self framingGuide11];
    }
    
    if ([[SettingsTool settings] thirdsGuide]) {
        [self thirdsGuideOn];
    } else {
        [self thirdsGuideOff];
    }
    
    if ([[SettingsTool settings] framingGuide]) {
        [self horizonGuideOn];
    } else {
        [self horizonGuideOff];
    }

    [videoVC startCamera];
    
    [topBar update];
    
    [self positionElements];
    
    if (!interfaceHidden) {
        [videoVC performSelector:@selector(positionVideoPreview) withObject:nil afterDelay:0.05f];
        [videoVC performSelector:@selector(positionVideoPreview) withObject:nil afterDelay:1.0f];
    }
    
    
}

-(void)resetAfterActivityDialog:(NSNotification *)n {
    /*
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    dispatch_async(dispatch_get_main_queue(), ^{
            [_libraryNavController.view removeFromSuperview];
            _libraryNavController = nil;
        
            GridCollectionViewController *libraryVC = [[GridCollectionViewController alloc] initWithNibName:@"GridCollectionViewController" bundle:nil];
            _libraryNavController = [[UINavigationController alloc] initWithRootViewController:libraryVC];
            _libraryNavController.navigationBar.barStyle = UIBarStyleBlack;
            [libraryVC setAlreadyPromptedForClipMove];
            float w = [[UIScreen mainScreen] bounds].size.height;
            float h = [[UIScreen mainScreen] bounds].size.width;
            _libraryNavController.view.frame = CGRectMake(0, 0, w, h);
            [appD.landscapeVC.view addSubview:_libraryNavController.view];
    });
     */
}

-(void)begForReview {
    if (reviewView) {
        return;
    }
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    reviewView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200,-200,400,200)];
    [self.view addSubview:reviewView];
    
    reviewView.backgroundColor = [UIColor blackColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,400,50)];
    l.backgroundColor = [UIColor whiteColor];
    l.textColor = [UIColor blackColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Please Rate and Review This App";
    l.tag = 1;
    [reviewView addSubview:l];
    
    
    UILabel *r = [[UILabel alloc] initWithFrame:CGRectMake(0,50,400,100)];
    r.backgroundColor = [UIColor clearColor];
    r.textColor = [UIColor whiteColor];
    r.textAlignment = NSTextAlignmentCenter;
    r.lineBreakMode = NSLineBreakByWordWrapping;
    r.numberOfLines = 0;
    r.text = @"Your ratings and reviews are a key component to our success. Please take the time to rate this app and consider writing a review. We would really appreciate it.";
    r.tag = 2;
    [reviewView addSubview:r];

    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ reviewView] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ reviewView ] ];
    CGFloat y = self.view.frame.size.height - 50;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = (self.view.frame.size.height / 2.0f) - 100;
    }
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    
    
    UIButton *rate = [[UIButton alloc] initWithFrame:CGRectMake(0,150,200,50)];
    UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake(200,150,200,50)];

    [rate setTitle:@"Rate/Review" forState:UIControlStateNormal];
    [close setTitle:@"Close" forState:UIControlStateNormal];
    
    [rate addTarget:self action:@selector(begForReviewEvent:) forControlEvents:UIControlEventTouchUpInside];
    [close addTarget:self action:@selector(begForReviewEvent:) forControlEvents:UIControlEventTouchUpInside];
    
    rate.tag = 1;
    close.tag = 2;
    
    [reviewView addSubview:rate];
    [reviewView addSubview:close];
    
    
}

-(void)begForReviewEvent:(id)sender {
    UIButton *b = (UIButton *)sender;
    
    switch (b.tag) {
        case 1:
        {
            [[UtilityBag bag] performSelector:@selector(rateApp) withObject:nil afterDelay:0.5];
        }
            break;
        case 2:
        {
            
        }
            break;
    }
    
    [animator removeAllBehaviors];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ reviewView] ];
    [animator addBehavior:gravity];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:2.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            animator = nil;
            [reviewView removeFromSuperview];
            reviewView = nil;
        });
    });
}
/*
#ifdef CCFREE
- (void)greystripeAdClickedThrough:(id<GSAd>)a_ad {
    NSLog(@"Greystripe ad was clicked.");
}
- (void)greystripeWillPresentModalViewController {
    NSLog(@"Greystripe opening fullscreen.");
}
- (void)greystripeWillDismissModalViewController {
    NSLog(@"Greystripe will close fullscreen.");
}
- (void)greystripeDidDismissModalViewController {
    NSLog(@"Greystripe closed fullscreen.");
    [myFullscreenAd fetch];
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = ![[SettingsTool settings] lockRotation];
}
- (void)greystripeAdFetchSucceeded:(id<GSAd>)a_ad {
    if (a_ad == myFullscreenAd) {
        NSLog(@"Fullscreen ad successfully fetched.");
            // Add code on success
    }
}

- (void)greystripeAdFetchFailed:(id<GSAd>)a_ad withError:(GSAdError)a_error {
    NSString *errorString =  @"";
    
    switch(a_error) {
        case kGSNoNetwork:
            errorString = @"Error: No network connection available.";
            break;
        case kGSNoAd:
            errorString = @"Error: No ad available from server.";
            break;
        case kGSTimeout:
            errorString = @"Error: Fetch request timed out.";
            break;
        case kGSServerError:
            errorString = @"Error: Greystripe returned a server error.";
            break;
        case kGSInvalidApplicationIdentifier:
            errorString = @"Error: Invalid or missing application identifier.";
            break;
        case kGSAdExpired:
            errorString = @"Error: Previously fetched ad expired.";
            break;
        case kGSFetchLimitExceeded:
            errorString = @"Error: Too many requests too quickly.";
            break;
        case kGSUnknown:
            errorString = @"Error: An unknown error has occurred.";
            break;
        default:
            errorString = @"An invalid error code was returned. Thats really bad!";
    }
    NSLog(@"Greystripe failed with error: %@",errorString);
}
#endif
 */
@end
