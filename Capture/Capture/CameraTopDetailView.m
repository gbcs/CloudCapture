//
//  CameraTopDetailView.m
//  Capture
//
//  Created by Gary Barnett on 7/6/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CameraTopDetailView.h"
#import "AppDelegate.h"
#import "LabeledButton.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>


@implementation CameraTopDetailView {
   UIColor *selectionLineColor;
    CGPoint topLeftForContent;
    CGSize sizeForContent;
    
  NSMutableArray *buttonCommandMap;

    CGPoint originalPanCenter;
    NSTimer *panTimer;
    NSInteger panDirection;
    NSInteger panStatus;
    
    UIView *panelView;
    UIDynamicAnimator *featureAnimator;
    UIView *featureView;
    UITableView *featureViewTV;
    
    BOOL titleChoiceIsEnd;
    NSInteger textEditChoice;
    NSString *selectedPreset;
    NSString *addPresetName;
    GPUImageView *histogramView;
    BOOL processingHistogram;
}

-(void)dealloc {
    //NSLog(@"%s", __func__);
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }

    histogramView = nil;
    selectionLineColor = nil;
    buttonCommandMap = nil;

    panTimer = nil;
   
    panelView = nil;
    featureAnimator = nil;
    featureView = nil;
    featureViewTV = nil;
    
    selectedPreset = nil;
    addPresetName = nil;
}

-(UIView *)histogramView {
    return histogramView;
}

-(GradientAttributedButton *)makeButtonAtRect:(CGRect)rect withTitle:(NSString *)title andTag:(NSInteger)tag beginColor:(NSString *)bColor endColor:(NSString *)eColor largeFont:(BOOL)largeFont {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              largeFont ? [[UtilityBag bag] standardFontBold] : [[UtilityBag bag] standardFont], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    
    if ([title isEqualToString:@"-"] || [title isEqualToString:@"+"]) {
       strAttr = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                    [[[UtilityBag bag] standardFontBold] fontWithSize:24], NSFontAttributeName,
                                    paragraphStyle, NSParagraphStyleAttributeName, nil
                                    ];
    }
    
    GradientAttributedButton *button = [self installButtonAtRect:rect andTag:tag];
    NSAttributedString *buttonTitle =[[NSAttributedString alloc] initWithString:title attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = YES;
    [button update];
    [panelView addSubview:button];

    return button;
}




-(void)showControlsForSelected  {
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if (self.selected != 5) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"handleHistogramDelegate" object:nil];
        }
    }
    
    if (self.selected == -1) {
        if (panelView) {
            [panelView removeFromSuperview];
            panelView = nil;
        }
        if (featureView) {
            [self closeFeatureView];
        }
        return;
    }
    
    if (!panelView) {
        CGFloat width = 120.0f;
        //if ([[UIScreen mainScreen] bounds].size.height == 568.0f) {
        //    width += 88.0f;
       // }
        
        panelView = [[UIView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.height - 125,10,width, 235)];
        //panelView.layer.shadowColor = [UIColor whiteColor].CGColor;
        //[panelView.layer setShadowOpacity:0.4];
        //[panelView.layer setShadowRadius:1.0];
        //[panelView.layer setShadowOffset:CGSizeMake(-1.0, -1.0)];
        //panelView.layer.cornerRadius = 8;
        //panelView.layer.masksToBounds = NO;
        panelView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            panelView.frame = CGRectMake(0, 40, 308, 235);
            [self.iPadDetailSled addSubview:panelView];
        } else {
             [self addSubview:panelView];
        }
        
        
        
    }
    
    while ([panelView.subviews count] >0) {
        UIView *v = [panelView.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    CGSize buttonSize = CGSizeMake(70,44);
    
    NSArray *yOffsets = @[ [NSNumber numberWithFloat:20],
                           [NSNumber numberWithFloat:72],
                           [NSNumber numberWithFloat:127],
                           [NSNumber numberWithFloat:185]
                           ];
    
    NSArray *xOffsets = @[ [NSNumber numberWithFloat:1.5],
                           [NSNumber numberWithFloat:74],
                           [NSNumber numberWithFloat:147.5],
                        
                           ];
    
    if ([[UIScreen mainScreen] bounds].size.height > 480) {
        xOffsets =   @[ [NSNumber numberWithFloat:5],
                        [NSNumber numberWithFloat:154 - 45],
                        [NSNumber numberWithFloat:308 - 95],
                        
                        ];
       buttonSize = CGSizeMake(90,44);
    }
    
    
    
    NSString *optionColorBegin = @"#666666";
    NSString *optionColorEnd = @"#333333";
  
    NSString *valueColorBegin = @"#006600";
    NSString *valueColorEnd = @"#003300";

    switch (self.selected) {
        case 0: {
            [self installPanelHeaderAtIndex:0 withTitle:@"Camera"];
           
            if ( (![[SettingsTool settings] isOldDevice]) && (![[SettingsTool settings] fastCaptureMode]) && self.supportsFrontCamera ) {
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"Front" andTag:0 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
            }
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:[[SettingsTool settings] cameraIsBack] ? @"Back" : @"Front" andTag:1 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
          
            if ( (![[SettingsTool settings] isOldDevice]) && (![[SettingsTool settings] fastCaptureMode]) ) {
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"Back" andTag:2 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
            }
            
            if (![[SettingsTool settings] isOldDevice]) {
                
                [self installPanelHeaderAtIndex:1 withTitle:@"Image Stabilization"];
                
                
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"Off" andTag:3 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[[SettingsTool settings] cameraISEnabled] ? @"On" : @"Off" andTag:4 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"On" andTag:5 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
            }
            
            if ( (![[SettingsTool settings] isOldDevice]) && (![[SettingsTool settings] fastCaptureMode]) ) {
                [self installPanelHeaderAtIndex:2 withTitle:@"Image Flip"];
                
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"Off" andTag:6 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[[SettingsTool settings] cameraFlipEnabled] ? @"On" : @"Off" andTag:7 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"On" andTag:8 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
            }
            
            [self installPanelHeaderAtIndex:3 withTitle:@"Rotation Lock"];
        
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Off" andTag:9 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:[[SettingsTool settings] lockRotation] ? @"On" : @"Off" andTag:10 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
        
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"On" andTag:11 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            
        }
            break;
        case 1: {
            
            
            float videoRate = 0.0f;
            
            BOOL fastCaptureMode = [[SettingsTool settings] fastCaptureMode];
            
            NSInteger maxCapture = 1080;
            
            if ([[SettingsTool settings] isOldDevice]) {
                maxCapture = 720;
            } else if ([[SettingsTool settings] isiPhone4S]) {
                maxCapture = 1080;
            }
            
            if (fastCaptureMode) {
                maxCapture = 720;
            }
            
            
            BOOL backCamera = [[SettingsTool settings] cameraIsBack];
            
            if (!backCamera) {
                if ([[SettingsTool settings] isiPhone4] || [[SettingsTool settings] isiPhone4S] || [[SettingsTool settings] isiPad2] || [[SettingsTool settings] isiPad3]) {
                    maxCapture = 360;
                } else {
                    maxCapture = 720;
                }
            }
            
            NSInteger currentOutput = [[SettingsTool settings] captureOutputResolution];
            
            if (currentOutput > maxCapture) {
                currentOutput = maxCapture;
                [[SettingsTool settings] setCaptureOutputResolution:currentOutput];
            }
            
    
            CGSize frameSize = CGSizeZero;
            
            switch (currentOutput) {
                case 1080:
                    frameSize = CGSizeMake(1920,1080);
                    videoRate = [[SettingsTool settings] videoCameraVideoDataRate1080];
                    break;
                case 720:
                    frameSize = CGSizeMake(1280,720);
                    if (fastCaptureMode) {
                        videoRate = [[SettingsTool settings] videoCameraVideoDataRateFastCaptureMode];
                    } else {
                        videoRate = [[SettingsTool settings] videoCameraVideoDataRate720];
                    }
                    break;
                case 576:
                    frameSize = CGSizeMake(1024,576);
                    videoRate = [[SettingsTool settings] videoCameraVideoDataRate576];
                    break;
                case 540:
                    frameSize = CGSizeMake(960,540);
                    videoRate = [[SettingsTool settings] videoCameraVideoDataRate540];
                    break;
                case 480:
                    frameSize = CGSizeMake(854,480);
                    videoRate = [[SettingsTool settings] videoCameraVideoDataRate480];
                    break;
                case 360:
                    frameSize = CGSizeMake(640,360);
                    videoRate = [[SettingsTool settings] videoCameraVideoDataRate360];
                    break;
            }
            
            NSString *curCapStr = [NSString stringWithFormat:@"%0.0fx\n%0.0f", frameSize.width, frameSize.height];
            
            
            
            [self installPanelHeaderAtIndex:0 withTitle:@"Video Resolution"];
            
            if ( (![[SettingsTool settings] isOldDevice]) && (!fastCaptureMode) ){
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"-" andTag:100 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
            }
            
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:curCapStr andTag:101 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            if ( (![[SettingsTool settings] isOldDevice]) && (!fastCaptureMode) ){
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"+" andTag:102 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
            }
            
            if ( (![[SettingsTool settings] isOldDevice]) && (!fastCaptureMode) ) {
                NSString *rateLine = [NSString stringWithFormat:@"Video Data Rate @%@%@",
                                      [[SettingsTool settings] textForOutputResolution:[[SettingsTool settings] captureOutputResolution]],
                                      [[SettingsTool settings] fastCaptureMode] ? @" (fast-capture)" : @""];
                [self installPanelHeaderAtIndex:1 withTitle:rateLine];
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"-" andTag:103 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[NSString stringWithFormat:@"%0.1f", videoRate / 1000000.0f] andTag:104 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"+" andTag:105 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }

            }
            
            
            [self installPanelHeaderAtIndex:2 withTitle:@"Frames Per Second"];
           
            NSInteger currentRate =  [[SettingsTool settings] videoCameraFrameRate];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"-" andTag:106 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:[NSString stringWithFormat:@"%02ld", (long)currentRate] andTag:107 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"+" andTag:108 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self installPanelHeaderAtIndex:3 withTitle:@"Common Frame Rates"];
            
            if ([[SettingsTool settings] fastCaptureMode]) {
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"48" andTag:112 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"60" andTag:113 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                
                if ([[SettingsTool settings] currentMaxFrameRate] >= 120) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                          withTitle:@"120" andTag:114 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
            
            } else {
                
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"24" andTag:109 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"25" andTag:110 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"30" andTag:111 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                

            }
            
          
            }
            break;

        case 2: {
           
            NSInteger focusMode = [[SettingsTool settings] focusMode];
            NSInteger focusRange = [[SettingsTool settings] focusRange];
            

            
            [self installPanelHeaderAtIndex:0 withTitle:@"Focus Lock"];
           
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"Off" andTag:300 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
           
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:self.focusLocked ? @"On" : @"Off" andTag:301 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
          
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"On" andTag:302 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
           
            
            
            [self installPanelHeaderAtIndex:1 withTitle:@"Focus Reticle"];
         
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Center" andTag:303 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:focusMode == 0 ? @"Center" : @"Reticle" andTag:304 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
         
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Reticle" andTag:305 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            
            
            [self installPanelHeaderAtIndex:2 withTitle:@"Focus Range Restrict"];
      
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"None" andTag:306 beginColor:focusRange == 0 ? valueColorBegin : optionColorBegin endColor:focusRange == 0 ? valueColorEnd :optionColorEnd largeFont:NO];
           
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Near" andTag:307 beginColor:focusRange == 1 ? valueColorBegin : optionColorBegin endColor:focusRange == 1 ? valueColorEnd :optionColorEnd largeFont:YES];
      
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Far" andTag:308 beginColor:focusRange == 2 ? valueColorBegin : optionColorBegin endColor:focusRange == 2 ? valueColorEnd :optionColorEnd largeFont:NO];
           
            
            BOOL focusSpeedSmooth = [[SettingsTool settings] focusSpeedSmooth];
            
            [self installPanelHeaderAtIndex:3 withTitle:@"Focus Speed"];
           
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Smooth" andTag:309 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:focusSpeedSmooth ? @"Smooth" : @"Fast" andTag:310 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
           
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Fast" andTag:311 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            
            
        }
            break;
        case 3: {
            
            NSInteger exposureMode = [[SettingsTool settings] exposureMode];
            
            

            [self installPanelHeaderAtIndex:0 withTitle:@"Exposure Lock"];
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Off" andTag:400 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:self.exposureLocked ? @"On" : @"Off" andTag:401 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"On" andTag:402 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            if ( (![[SettingsTool settings] isOldDevice]) && (![[SettingsTool settings] fastCaptureMode]) ) {
                [self installPanelHeaderAtIndex:1 withTitle:@"ISO Lock"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"Auto" andTag:409 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                NSInteger isoLock = [[SettingsTool settings] isoLock];
                
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:isoLock == 0 ? @"Auto" : [NSString stringWithFormat:@"%ld", (long)isoLock] andTag:410 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"Set" andTag:411 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            }
            
            [self installPanelHeaderAtIndex:2 withTitle:@"Exposure Reticle"];
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Center" andTag:403 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:exposureMode == 0 ? @"Center" : @"Reticle" andTag:404 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Reticle" andTag:405 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            
            
            [self installPanelHeaderAtIndex:3 withTitle:@"White Balance Lock"];
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Off" andTag:406 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:self.whiteBalanceLocked ? @"On" : @"Off" andTag:407 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"On" andTag:408 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
           
            
        }
            break;

        case 4: {
            
            BOOL thirdsGuide = [[SettingsTool settings] thirdsGuide];
            NSInteger framingMode = [[SettingsTool settings] framingGuide];
            BOOL horizonGuide = [[SettingsTool settings] horizonGuide];
            
            
            
            [self installPanelHeaderAtIndex:1 withTitle:@"Thirds Guide"];
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Off" andTag:500 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:thirdsGuide ? @"On" : @"Off" andTag:501 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"On" andTag:502 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            
            
            [self installPanelHeaderAtIndex:2 withTitle:@"Framing Guide"];
            
            BOOL stat = (framingMode == 0);
            
            BOOL cropStillsToGuide = [[SettingsTool settings] cropStillsToGuide];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Off" andTag:503 beginColor:stat ? valueColorBegin : optionColorBegin endColor:stat ? valueColorEnd : optionColorEnd largeFont:stat];
            stat = (framingMode == 1);
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"4:3" andTag:504 beginColor:stat ? valueColorBegin : optionColorBegin endColor:stat ? valueColorEnd : optionColorEnd largeFont:stat];
            stat = (framingMode == 2);
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"1:1" andTag:505 beginColor:stat ? valueColorBegin : optionColorBegin endColor:stat ? valueColorEnd : optionColorEnd largeFont:stat];
            
            [self installPanelHeaderAtIndex:3 withTitle:@"Crop Stills to Framing Guide"];
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Off" andTag:509 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:cropStillsToGuide ? @"On" : @"Off" andTag:510 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"On" andTag:511 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            if (![[SettingsTool settings] isOldDevice]) {
                [self installPanelHeaderAtIndex:0 withTitle:@"Leveling Guide"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"Off" andTag:506 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:horizonGuide ? @"On" : @"Off" andTag:507 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"On" andTag:508 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            }
        }
            break;
        case 5: {
            
            NSString *torchStr = @"N/A";
            
            if (!self.torchActive) {
                torchStr = [NSString stringWithFormat:@"%0.0f", [[SettingsTool settings] torchLevelRequested] * 10.0f];
            } else if (self.torchLevel > 0.0) {
                torchStr = [NSString stringWithFormat:@"%0.0f",self.torchLevel * 10.0f];
            }
            
            [self installPanelHeaderAtIndex:0 withTitle:@"Torch Control"];
            
             [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Off" andTag:600 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:self.torchActive ? @"On" : @"Off" andTag:601 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"On" andTag:602 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
           
            [self installPanelHeaderAtIndex:1 withTitle:@"Torch Level Adjust"];
            
            
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"-" andTag:603 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            
            [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:torchStr andTag:604 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"+" andTag:605 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
    
            NSString *histogramTitle = @"Histogram";
            if (![[SettingsTool settings] engineHistogram]) {
                [self installPanelHeaderAtIndex:2 withTitle:histogramTitle];
                [self installPanelHeaderAtIndex:3 withTitle:@"This feature is currently bypassed."];
            } else if ([[SettingsTool settings] fastCaptureMode]) {
                [self installPanelHeaderAtIndex:2 withTitle:histogramTitle];
                [self installPanelHeaderAtIndex:3 withTitle:@"Not available in fast capture mode."];
            } else if ([[SettingsTool settings] isOldDevice] || [[SettingsTool settings] isiPhone4S]) {
                [self installPanelHeaderAtIndex:2 withTitle:histogramTitle];
                [self installPanelHeaderAtIndex:3 withTitle:@"Not available on this device."];
            } else {
                switch ([[SettingsTool settings] engineHistogramType]) {
                    case 0:
                        histogramTitle = [histogramTitle stringByAppendingString:@" - Red"];
                        break;
                    case 1:
                        histogramTitle = [histogramTitle stringByAppendingString:@" - Green"];
                        break;
                    case 2:
                        histogramTitle = [histogramTitle stringByAppendingString:@" - Blue"];
                        break;
                    case 3:
                        histogramTitle = [histogramTitle stringByAppendingString:@" - RGB"];
                        break;
                    case 4:
                        histogramTitle = [histogramTitle stringByAppendingString:@" - Luminance"];
                        break;
                }
                
                [self installPanelHeaderAtIndex:2 withTitle:histogramTitle];
                
                if ( ([[SettingsTool settings] engineHistogram]) && (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) ) {
                    [panelView addSubview:histogramView];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"handleHistogramDelegate" object:self];
            }
        }
            break;

        case 6: {

            if ([[SettingsTool settings] isOldDevice] || [[SettingsTool settings] isIPadMini] || [[SettingsTool settings] isiPad2]) {
                [self installPanelHeaderAtIndex:0 withTitle:@"Zoom"];
                [self installPanelHeaderAtIndex:1 withTitle:@"Not supported on this device."];
            } else {
                
                [self installPanelHeaderAtIndex:0 withTitle:@"Zoom Speed"];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[NSString stringWithFormat:@"%0.1f%%", [[SettingsTool settings] zoomRate] * 25.0f] andTag:710 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self installPanelHeaderAtIndex:1 withTitle:@"Stored Position #1"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"0.0%" andTag:700 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[NSString stringWithFormat:@"%0.1f%%", [[SettingsTool settings] zoomPosition1] * 100.0f] andTag:701 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"Set" andTag:702 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                
                
                [self installPanelHeaderAtIndex:2 withTitle:@"Stored Position #2"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"0.0%" andTag:703 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[NSString stringWithFormat:@"%0.1f%%", [[SettingsTool settings] zoomPosition2] * 100.0f] andTag:704 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"Set" andTag:705 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                
                [self installPanelHeaderAtIndex:3 withTitle:@"Stored Position #3"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"0.0%" andTag:706 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[NSString stringWithFormat:@"%0.1f%%", [[SettingsTool settings] zoomPosition3] * 100.0f] andTag:707 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:@"Set" andTag:708 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            }
        }
            break;
        case 7: {
            [self installPanelHeaderAtIndex:0 withTitle:@"Chroma Key"];
           
            if ([[SettingsTool settings] isOldDevice]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"Not supported on this device."];
            } else if ([[SettingsTool settings] fastCaptureMode]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"Not available in fast-capture mode."];
            } else if (![[SettingsTool settings] engineChromaKey]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"This filter is currently bypassed."];
            } else {
                NSArray *ckVal = [[SettingsTool settings] engineChromaKeyValues];

                [self installPanelHeaderAtIndex:1 withTitle:@"Hue"];
                if (!_isRecording) {
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"-" andTag:1100 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:[NSString stringWithFormat:@"%0.2f", [ckVal[0] floatValue]] andTag:1101 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                if (!_isRecording) {
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"+" andTag:1102 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
                
                
                [self installPanelHeaderAtIndex:2 withTitle:@"Sensitivity"];
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"-" andTag:1103 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                }
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                             withTitle:[NSString stringWithFormat:@"%0.2f", [ckVal[1] floatValue]] andTag:1104 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                if (!_isRecording) {
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                 withTitle:@"+" andTag:1105 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                    
                }
                
            }

        }
            break;
        case 8:
        {
            [self installPanelHeaderAtIndex:0 withTitle:@"Image Effect"];
            
         
            if ([[SettingsTool settings] isOldDevice]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"Not supported on this device."];
            } else if ([[SettingsTool settings] fastCaptureMode]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"Not available in fast-capture mode."];
            } else if (![[SettingsTool settings] engineImageEffect]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"This filter is currently bypassed."];
            } else {
                CGFloat w =  buttonSize.width * 3 + 25;
                
                if ([[SettingsTool settings] isiPhone4S]) {
                    w -= 20;
                }
                
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], w , buttonSize.height)
                                      withTitle:[[SettingsTool settings] imageEffectStr] andTag:801 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
           
                NSString *effectStr = [[SettingsTool settings] imageEffectStr];
                if ([effectStr isEqualToString:@"Vignette"]) {
                    NSDictionary *attributes = [[SettingsTool settings] imageEffectParameters:effectStr];
                    
                    [self installPanelHeaderAtIndex:1 withTitle:@"Intensity"];
                    [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                          withTitle:@"-" andTag:2000 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                    
                    [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                          withTitle:[NSString stringWithFormat:@"%0.2f", [[attributes objectForKey:@"inputIntensity"] floatValue]] andTag:2001 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                    
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                          withTitle:@"+" andTag:2002 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];

                    
                    [self installPanelHeaderAtIndex:2 withTitle:@"Radius"];
                    [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                          withTitle:@"-" andTag:2003 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                    
                    [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                          withTitle:[NSString stringWithFormat:@"%0.2f", [[attributes objectForKey:@"inputRadius"] floatValue]] andTag:2004 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                    
                    [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                          withTitle:@"+" andTag:2005 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                    

                } else if ([effectStr isEqualToString:@"Noir"]) {
                    
                } else if ([effectStr isEqualToString:@"Chrome"]) {
                    
                } else if ([effectStr isEqualToString:@"Fade"]) {
                    
                } else if ([effectStr isEqualToString:@"Instant"]) {
                    
                } else if ([effectStr isEqualToString:@"Mono"]) {
                    
                } else if ([effectStr isEqualToString:@"Tonal"]) {
                    
                } else if ([effectStr isEqualToString:@"Transfer"]) {
                    
                }             
            
            }
            
        }
            break;
        case 9: {
            [self installPanelHeaderAtIndex:0 withTitle:@"Color Controls"];
            
            if ([[SettingsTool settings] isOldDevice]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"Not supported on this device."];
            } else if ([[SettingsTool settings] fastCaptureMode]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"Not available in fast-capture mode."];
            } else if (![[SettingsTool settings] engineColorControl]) {
                [self installPanelHeaderAtIndex:1 withTitle:@"This filter is currently bypassed."];
            } else {
                [self installPanelHeaderAtIndex:1 withTitle:@"Brightness"];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"-" andTag:900 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:[NSString stringWithFormat:@"%0.2f", [[SettingsTool settings] videoBrightness]] andTag:901 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"+" andTag:902 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                
                
                [self installPanelHeaderAtIndex:2 withTitle:@"Saturation"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"-" andTag:903 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:[NSString stringWithFormat:@"%0.2f", [[SettingsTool settings] videoSaturation]] andTag:904 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"+" andTag:905 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                
                [self installPanelHeaderAtIndex:3 withTitle:@"Contrast"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"-" andTag:906 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:[NSString stringWithFormat:@"%0.2f", [[SettingsTool settings] videoContrast]] andTag:907 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"+" andTag:908 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];

            }
            
        }
            break;
            
        case 10: {
              if ([[SettingsTool settings] isOldDevice]) {
                [self installPanelHeaderAtIndex:0 withTitle:@"Titling"];
                [self installPanelHeaderAtIndex:1 withTitle:@"Not supported on this device."];
              } else if ([[SettingsTool settings] fastCaptureMode]) {
                  [self installPanelHeaderAtIndex:0 withTitle:@"Titling"];
                  [self installPanelHeaderAtIndex:1 withTitle:@"Not available in fast-capture mode."];
            } else if (![[SettingsTool settings] engineTitling]) {
                [self installPanelHeaderAtIndex:0 withTitle:@"Titling"];
                [self installPanelHeaderAtIndex:1 withTitle:@"This filter is currently bypassed."];
            } else {
                
                CGFloat w =  buttonSize.width * 3 + 25;
                
                if ([[SettingsTool settings] isiPhone4S]) {
                    w -= 20;
                }

                [self installPanelHeaderAtIndex:0 withTitle:@"Title"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], w, buttonSize.height)
                                      withTitle:[[SettingsTool settings] engineTitlingTitle] andTag:1001 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self installPanelHeaderAtIndex:1 withTitle:@"Author"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], w, buttonSize.height)
                                      withTitle:[[SettingsTool settings] engineTitlingAuthor] andTag:1011 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self installPanelHeaderAtIndex:2 withTitle:@"Scene"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], w, buttonSize.height)
                                      withTitle:[[SettingsTool settings] engineTitlingScene] andTag:1021 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self installPanelHeaderAtIndex:3 withTitle:@"Take"];
                [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"-" andTag:1030 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:[NSString stringWithFormat:@"%ld", (long)[[SettingsTool settings] engineTitlingTake]] andTag:1031 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
                
                [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"+" andTag:1032 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            }
        }
            break;
        case 11:
        { //presets
            selectedPreset = [[PresetHandler tool] currentPreset];
            [self installShortPanelHeaderAtIndex:0 withTitle:@"Current Preset"];
            [self installShortPanelHeaderAtIndex:1 withTitle:@"Available Presets"];
            
            CGFloat presetTVWidth =buttonSize.width * 2 + 20;
            if (self.bounds.size.width < 568.0f) {
                presetTVWidth = buttonSize.width * 2 - 10;
            }
            
            [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], presetTVWidth + 10, buttonSize.height)
                                      withTitle:selectedPreset andTag:-1 beginColor:valueColorBegin endColor:valueColorEnd largeFont:YES];
          
       
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"Save" andTag:5001 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
                
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                                      withTitle:@"Load" andTag:5000 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
           
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Add" andTag:5002 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                                  withTitle:@"Delete" andTag:5003 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
            
            CGFloat startingY =[yOffsets[1] floatValue] +5;
            
            UITableView *tv = [[UITableView alloc] initWithFrame:CGRectMake(10,startingY, presetTVWidth, ([yOffsets[3] floatValue] + buttonSize.height + -5) - startingY)];
            [tv setTintColor:[UIColor blackColor]];
            tv.tag = 2;
            tv.delegate = self;
            tv.dataSource = self;
            [panelView addSubview:tv];
        }
            break;
    }
}

-(void)reloadTitleTV {
    [featureViewTV reloadData];
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    switch (tag) {
        case 0:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraFront" object:nil];
            break;
        case 1:
            [self showFeatureViewForOption:@"infoCamera"];
            break;
        case 2:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraBack" object:nil];
            break;
        case 3:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraISDisable" object:nil];
            break;
        case 4:
            [self showFeatureViewForOption:@"infoStabilization"];
            break;
        case 5:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraISEnable" object:nil];
            break;
        case 6:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraFlipDisable" object:nil];
            break;
        case 7:
            [self showFeatureViewForOption:@"infoFlip"];
            break;
        case 8:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraFlipEnable" object:nil];
            break;
        case 9:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"rotationLockDisable" object:nil];
            break;
        case 10:
            [self showFeatureViewForOption:@"infoRotationLock"];
            break;
        case 11:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"rotationLockEnable" object:nil];
            break;
        case 100:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionDecrement" object:nil];
            break;
        case 101:
        {
            if (self.isRecording) {
                return;
            }
            
            if ([[SettingsTool settings] cameraIsBack]) {
                [self showFeatureViewForOption:@"resolution"];
            }
        }
            break;
        case 102:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionIncrement" object:nil];
            break;
        case 103:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureVideoDataRateDecrement" object:nil];
            break;
        case 104:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureVideoRateSetDefault" object:nil];
            [self showFeatureViewForOption:@"infoDataRate"];
            break;
        case 105:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureVideoDataRateIncrement" object:nil];
            break;
        case 106:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateDecrement" object:nil];
            break;
        case 107:
            [self showFeatureViewForOption:@"infoFPS"];
            break;
        case 108:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateIncrement" object:nil];
            break;
        case 109:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@24];
            break;
        case 110:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@25];
            break;
        case 111:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@30];
            break;
        case 112:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@48];
            break;
        case 113:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@60];
            break;
        case 114:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@120];
            break;
        case 200:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateDecrement" object:nil];
            break;
        case 201:
            [self showFeatureViewForOption:@"infoFPS"];
            break;
        case 202:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateIncrement" object:nil];
            break;
        case 203:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@24];
            break;
        case 204:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@25];
            break;
        case 205:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@30];
            break;
        case 206:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@48];
            break;
        case 207:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@60];
            break;
        case 208:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@120];
            break;
        case 300:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusAuto" object:nil];
            break;
        case 301:
            [self showFeatureViewForOption:@"infoFocusLock"];
            break;
        case 302:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusLock" object:nil];
            break;
        case 303:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusCenter" object:nil];
            break;
        case 304:
            [self showFeatureViewForOption:@"infoFocusReticle"];
            break;
        case 305:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusReticle" object:nil];
            break;
        case 306:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusRangeOff" object:nil];
            break;
        case 307:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusRangeNear" object:nil];
            break;
        case 308:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusRangeFar" object:nil];
            break;
        case 309:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusSpeedSmooth" object:nil];
            break;
        case 310:
            [self showFeatureViewForOption:@"infoFocusSpeed"];
            break;
        case 311:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"focusSpeedFast" object:nil];
            break;
        case 400:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"exposureAuto" object:nil];
            break;
        case 401:
            [self showFeatureViewForOption:@"infoExposureLock"];
            break;
        case 402:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"exposureLock" object:nil];
            break;
        case 403:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"exposureCenter" object:nil];
            break;
        case 404:
            [self showFeatureViewForOption:@"infoExposureReticle"];
            break;
        case 405:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"exposureReticle" object:nil];
            break;
        case 406:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"whiteBalanceAuto" object:nil];
            break;
        case 407:
            [self showFeatureViewForOption:@"infoWhiteBalance"];
             break;
        case 408:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"whiteBalanceLock" object:nil];
            break;
        case 409:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"isoLockAuto" object:nil];
            break;
        case 410:
            [self showFeatureViewForOption:@"infoISOLock"];
            break;
        case 411:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"isoLockSet" object:nil];
            break;
        case 500:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"thirdsGuideOff" object:nil];
            break;
        case 501:
            [self showFeatureViewForOption:@"infoThirdsGuide"];
            break;
        case 502:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"thirdsGuideOn" object:nil];
            break;
        case 503:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"framingGuideOff" object:nil];
            break;
        case 504:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"framingGuide43" object:nil];
            break;
        case 505:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"framingGuide11" object:nil];
            break;
        case 506:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"horizonGuideOff" object:nil];
            break;
        case 507:
            [self showFeatureViewForOption:@"infoLevelingGuide"];
            break;
        case 508:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"horizonGuideOn" object:nil];
            break;
        case 509:
        {
            [[SettingsTool settings]  setCropStillsToGuide:NO];
            [self showControlsForSelected];
        }
            break;
        case 510:
        {
            [self showFeatureViewForOption:@"infoCropStills"];
        }
        case 511:
        {
            [[SettingsTool settings]  setCropStillsToGuide:YES];
            [self showControlsForSelected];
        }
            break;
        case 600:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"torchOff" object:nil];
            break;
        case 601:
            [self showFeatureViewForOption:@"infoTorchControl"];
            break;
        case 602:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"torchOn" object:nil];
            break;
        case 603:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"torchLevelDecrement" object:nil];
            break;
        case 604:
            [self showFeatureViewForOption:@"infoTorchLevel"];
            break;
        case 605:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"torchLevelIncrement" object:nil];
            break;
        case 700:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomPosition1Unset" object:nil];
            break;
        case 701:
            [self showFeatureViewForOption:@"infoZoomStoredPosition"];
            break;
        case 702:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomPosition1Set" object:nil];
            break;
        case 703:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomPosition2Unset" object:nil];
            break;
        case 704:
            [self showFeatureViewForOption:@"infoZoomStoredPosition"];
            break;
        case 705:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomPosition2Set" object:nil];
            break;
        case 706:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomPosition3Unset" object:nil];
            break;
        case 707:
            [self showFeatureViewForOption:@"infoZoomStoredPosition"];
            break;
        case 708:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomPosition3Set" object:nil];
            break;
        case 710:
            [self showFeatureViewForOption:@"infoZoomSpeed"];
            break;
        case 801:
            [self showFeatureViewForOption:@"imageEffect"];
            break;
        case 901:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoBrightnessDefault" object:nil];
            break;
        case 902:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoBrightnessIncrement" object:nil];
            break;
        case 903:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoSaturationDecrement" object:nil];
            break;
        case 904:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoSaturationDefault" object:nil];
            break;
        case 905:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoSaturationIncrement" object:nil];
            break;
        case 906:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoContrastDecrement" object:nil];
            break;
        case 907:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoContrastDefault" object:nil];
            break;
        case 908:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoContrastIncrement" object:nil];
            break;
        case 999:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"userWantsEngine" object:nil];
            break;
        case 1001:
        {
            textEditChoice = 1;
            [self showFeatureViewForOption:@"textEdit"];
        }
            break;
        case 1011:
        {
            textEditChoice = 2;
            [self showFeatureViewForOption:@"textEdit"];
        }
            break;
        case 1021:
        {
            textEditChoice = 3;
            [self showFeatureViewForOption:@"textEdit"];
        }
            break;
        case 1030:
        {
            NSInteger take = [[SettingsTool settings] engineTitlingTake];
            take--;
            if (take < 1) {
                take = 1;
            }
            [[SettingsTool settings]  setEngineTitlingTake:take];
            [self showControlsForSelected];
        }
            break;
        case 1031:
        {
            [[SettingsTool settings]  setEngineTitlingTake:1];
            [self showControlsForSelected];
        }
            break;
        case 1032:
        {
            NSInteger take = [[SettingsTool settings] engineTitlingTake];
            take++;
            [[SettingsTool settings]  setEngineTitlingTake:take];
            [self showControlsForSelected];
        }
            break;
        case 1100: // chroma key hue -]
        {
            NSMutableArray *vals = [[[SettingsTool settings] engineChromaKeyValues] mutableCopy];
            CGFloat val = [[vals objectAtIndex:0] floatValue];
            val -= 0.01f;
            if (val < 0.0f) {
                val = 0.0f;
            }
            [vals replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:val]];
            [[SettingsTool settings]  setEngineChromaKeyValues:[vals copy]];
            [[NSNotificationCenter defaultCenter]  postNotificationName:@"chromaKeyValuesChanged" object:nil];
            [self showControlsForSelected];
        }
            break;
        case 1101: // chroma key hue default
        {

        }
            break;
        case 1102: // chroma key hue +
        {
            NSMutableArray *vals = [[[SettingsTool settings] engineChromaKeyValues] mutableCopy];
            CGFloat val = [[vals objectAtIndex:0] floatValue];
            val += 0.01f;
            if (val > 1.0f) {
                val = 1.0f;
            }
            [vals replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:val]];
            [[SettingsTool settings]  setEngineChromaKeyValues:[vals copy]];
            [[NSNotificationCenter defaultCenter]  postNotificationName:@"chromaKeyValuesChanged" object:nil];
            [self showControlsForSelected];
        }
            break;
        case 1103: // chroma key sensitivity
        {
            NSMutableArray *vals = [[[SettingsTool settings] engineChromaKeyValues] mutableCopy];
            CGFloat val = [[vals objectAtIndex:1] floatValue];
            val -= 0.01f;
            if (val < 0.0f) {
                val = 0.0f;
            }
            [vals replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:val]];
            [[SettingsTool settings]  setEngineChromaKeyValues:[vals copy]];
            [[NSNotificationCenter defaultCenter]  postNotificationName:@"chromaKeyValuesChanged" object:nil];
            [self showControlsForSelected];
        }
            break;
        case 1104: // chroma key sensitivity default
        {

        }
            break;
        case 1105: // chroma key sensitivity +
        {
            NSMutableArray *vals = [[[SettingsTool settings] engineChromaKeyValues] mutableCopy];
            CGFloat val = [[vals objectAtIndex:1] floatValue];
            val += 0.01f;
            if (val > 1.0f) {
                val = 1.0f;
            }
            [vals replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:val]];
            [[SettingsTool settings]  setEngineChromaKeyValues:[vals copy]];
            [[NSNotificationCenter defaultCenter]  postNotificationName:@"chromaKeyValuesChanged" object:nil];
            [self showControlsForSelected];
        }
            break;
        case 2002:
        {
            NSString *effectStr = [[SettingsTool settings] imageEffectStr];
            NSMutableDictionary *dict = [[[SettingsTool settings] imageEffectParameters:effectStr] mutableCopy];
            NSString *key = @"inputIntensity";
            CGFloat val = [[dict objectForKey:key] floatValue];
            val += 0.05f;
            if (val > 1.0f) {
                val = 1.0f;
            }
            [dict setObject:[NSNumber numberWithFloat:val] forKey:key];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateFilterAttributes" object:@[effectStr, [dict copy]]];
            [self showControlsForSelected];
        }
            break;
        case 2001:
        {
            NSString *effectStr = [[SettingsTool settings] imageEffectStr];
            NSMutableDictionary *dict = [[[SettingsTool settings] imageEffectParameters:effectStr] mutableCopy];
            NSString *key = @"inputIntensity";
            CGFloat val = 0.00f;
            [dict setObject:[NSNumber numberWithFloat:val] forKey:key];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateFilterAttributes" object:@[effectStr, [dict copy]]];
            [self showControlsForSelected];
        }
            break;
        case 2000:
        {
            NSString *effectStr = [[SettingsTool settings] imageEffectStr];
            NSMutableDictionary *dict = [[[SettingsTool settings] imageEffectParameters:effectStr] mutableCopy];
            NSString *key = @"inputIntensity";
            CGFloat val = [[dict objectForKey:key] floatValue];
            val -= 0.05f;
            if (val < -1.0f) {
                val = -1.0f;
            }
            [dict setObject:[NSNumber numberWithFloat:val] forKey:key];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateFilterAttributes" object:@[effectStr, [dict copy]]];
            [self showControlsForSelected];
        }
            break;
        case 2005:
        {
            NSString *effectStr = [[SettingsTool settings] imageEffectStr];
            NSMutableDictionary *dict = [[[SettingsTool settings] imageEffectParameters:effectStr] mutableCopy];
            NSString *key = @"inputRadius";
            CGFloat val = [[dict objectForKey:key] floatValue];
            val += 0.10f;
            if (val > 2.0f) {
                val = 2.0f;
            }
            [dict setObject:[NSNumber numberWithFloat:val] forKey:key];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateFilterAttributes" object:@[effectStr, [dict copy]]];
            [self showControlsForSelected];
        }
            break;
        case 2004:
        {
            NSString *effectStr = [[SettingsTool settings] imageEffectStr];
            NSMutableDictionary *dict = [[[SettingsTool settings] imageEffectParameters:effectStr] mutableCopy];
            NSString *key = @"inputRadius";
            CGFloat val = 1.0f;
            [dict setObject:[NSNumber numberWithFloat:val] forKey:key];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateFilterAttributes" object:@[effectStr, [dict copy]]];
            [self showControlsForSelected];
        }
            break;
        case 2003:
        {
            NSString *effectStr = [[SettingsTool settings] imageEffectStr];
            NSMutableDictionary *dict = [[[SettingsTool settings] imageEffectParameters:effectStr] mutableCopy];
            NSString *key = @"inputRadius";
            CGFloat val = [[dict objectForKey:key] floatValue];
            val -= 0.10f;
            if (val <  0.0f) {
                val = 0.0f;
            }
            [dict setObject:[NSNumber numberWithFloat:val] forKey:key];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateFilterAttributes" object:@[effectStr, [dict copy]]];
            [self showControlsForSelected];
        }
            break;
            
   
        case 10800:
        {
            if (textEditChoice == 4) {
                [[PresetHandler tool] addPresetWithName:addPresetName];
                selectedPreset = addPresetName;
                
            }
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
            
        case 20000 + 1080:
        {
            if ([[SettingsTool settings] captureOutputResolution] != 1080) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionSet" object:@1080];
            }
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;;
        case 20000 + 720:
        {
            if ([[SettingsTool settings] captureOutputResolution] != 720) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionSet" object:@720];
            }
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;

        case 20000 + 576:
        {
            if ([[SettingsTool settings] captureOutputResolution] != 576) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionSet" object:@576];
            }
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;

        case 20000 + 540:
        {
            if ([[SettingsTool settings] captureOutputResolution] != 540) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionSet" object:@540];
            }
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;

        case 20000 + 480:
        {
            if ([[SettingsTool settings] captureOutputResolution] != 480) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionSet" object:@480];
            }
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;

        case 20000 + 360:
        {
            if ([[SettingsTool settings] captureOutputResolution] != 360) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"captureOutputResolutionSet" object:@360];
            }
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
            
        case 4000 + 1:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@1];
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
        case 4000 + 24:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@24];
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
        case 4000 + 30:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@30];
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
        case 4000 + 48:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@48];
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
        case 4000 + 60:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@60];
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
        case 4000 + 120:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"captureFrameRateSet" object:@120];
            [self closeFeatureView];
            [self showControlsForSelected];
        }
            break;
        case 5000: //load preset
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];

            [[PresetHandler tool] loadPresetWithName:selectedPreset];
            [self showControlsForSelected];
        }
            break;
        case 5001: //save preset
        {
            [[PresetHandler tool] saveCurrentPreset];
        }
            break;
        case 5002: //add preset
        {
            textEditChoice = 4;
            [self showFeatureViewForOption:@"textEdit"];

        }
            break;
        case 5003: //del preset
        {
            if (selectedPreset && (![selectedPreset isEqualToString:@"1280x720@24fps"])) {
                [[PresetHandler tool] deletePresetWithName:selectedPreset];
                [self showControlsForSelected];
            }
        }
            break;
            
    }
}

-(void)updateAudioLevel:(NSArray *)channels {
    
}

-(void)closeFeatureView {
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ featureView] ];
    
    UIView *dSub = [featureView.subviews objectAtIndex:0];
    
    for (UIView *v in dSub.subviews) {
        if ([v isKindOfClass:[UITextView class]]) {
            [v resignFirstResponder];
        }
    }
    
    [featureAnimator removeAllBehaviors];
    [featureAnimator addBehavior:gravity];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"paneTapMode" object:@(YES)];
    
}

-(GradientAttributedButton *)installButtonAtRect:(CGRect)rect andTag:(NSInteger)tag {
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:rect];
    button.delegate = self;
    button.tag = tag;
    return button;
}


-(void)installPanelHeaderAtIndex:(CGFloat)index withTitle:(NSString *)title {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 +(55 *index), panelView.bounds.size.width, 25)];
    l.text = title;
    l.font = [[UtilityBag bag] standardFont];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    [panelView addSubview:l];
}

-(void)installShortPanelHeaderAtIndex:(NSInteger)index withTitle:(NSString *)title {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 +(55 *index), panelView.bounds.size.width - 80, 25)];
    l.text = title;
    l.font = [[UtilityBag bag] standardFont];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    [panelView addSubview:l];
}


-(void)detailViewTapped:(UITapGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userTappedReticlePane" object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        selectionLineColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        buttonCommandMap = [[NSMutableArray alloc] initWithCapacity:10];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
          histogramView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, 256, 100)];
        } else {
            histogramView = [[GPUImageView alloc] initWithFrame:CGRectMake(26, 132, 256, 100)];
        }
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedHistogramType:)];
        [histogramView addGestureRecognizer:tapG];
    
    }
    return self;
}

-(void)userTappedHistogramType:(NSNotification *)n {
    NSInteger histogramType = [[SettingsTool settings] engineHistogramType];
    
    histogramType++;
    if (histogramType > 4) {
        histogramType = 0;
    }
    
    [[SettingsTool settings] setEngineHistogramType:histogramType];
    [self showControlsForSelected];
}


-(UIImageView *)createImageIconForDetailViewAtlocation:(CGRect )location image:(UIImage *)image notifyStr:(NSString *)notifyStr selected:(BOOL)iconSelected withRedX:(BOOL)drawRedX {
    
    
    UIImage *i2 = nil;
    
    if (iconSelected) {
        i2 = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationUp];
    } else {
        i2 = [image negativeImage];
    }
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:i2];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.layer.cornerRadius = 5;
    iv.layer.masksToBounds = YES;
    iv.userInteractionEnabled = YES;
    
    if (notifyStr) {
        iv.tag = [buttonCommandMap count];
        [buttonCommandMap addObject:notifyStr];
    } else {
        iv.tag = -1;
    }

    if (iconSelected) {
        iv.backgroundColor  = [UIColor whiteColor];
    } else {
        iv.backgroundColor  = [UIColor blackColor];
    }
    
    iv.frame =  location;
    
    if (drawRedX) {
        UIImageView *ivr = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redX2.png"]];
        ivr.alpha = 0.7;
        ivr.frame = CGRectMake(0,0,location.size.width, location.size.height);
        ivr.contentMode = UIViewContentModeScaleAspectFit;
        [iv addSubview:ivr];
    }
    
    if (drawRedX) {
        UIImageView *ivr = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"redX2.png"]];
        ivr.alpha = 0.7;
        ivr.frame = CGRectMake(0,0,location.size.width, location.size.height);
        ivr.contentMode = UIViewContentModeScaleAspectFit;
        [iv addSubview:ivr];
    }
    
    UITapGestureRecognizer  *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedButton:)];
    [iv addGestureRecognizer:tapG];
    
    return iv;
}

-(UIImageView *)createTextIconForDetailViewAtlocation:(CGRect )location text:(NSString *)text notifyStr:(NSString *)notifyStr selected:(BOOL)iconSelected withRedX:(BOOL)drawRedX {

    UIImageView *iv = [[UIImageView alloc] initWithImage:drawRedX ?  [UIImage imageNamed:@"redX2.png"] : nil] ;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.layer.cornerRadius = 5;
    iv.layer.masksToBounds = YES;
    iv.userInteractionEnabled = YES;
    
    if (notifyStr) {
        iv.tag = [buttonCommandMap count];
        [buttonCommandMap addObject:notifyStr];
    } else {
        iv.tag = -1;
    }
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,location.size.width,location.size.height)];
    l.text = text;
    l.font = [[[UtilityBag bag] standardFontBold] fontWithSize:20];

    l.textAlignment = NSTextAlignmentCenter;
    [iv addSubview:l];
    
    
    if (iconSelected) {
        iv.backgroundColor = drawRedX ? [UIColor colorWithWhite:1.0 alpha:1.0] : [UIColor clearColor];
        l.backgroundColor = drawRedX ? [UIColor clearColor] : [UIColor colorWithWhite:1.0 alpha:1.0] ;
        l.textColor = [UIColor blackColor];
    } else {
        l.backgroundColor = [UIColor clearColor];
        iv.backgroundColor = [UIColor blackColor];
        l.textColor = [UIColor whiteColor];
    }
    
    iv.frame =  location;
    
    UITapGestureRecognizer  *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedButton:)];
    [iv addGestureRecognizer:tapG];
    
    return iv;
}

-(void)userTappedButton:(UITapGestureRecognizer *)g {
    
    if (g.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
   
}

-(void)showFeatureViewForOption:(NSString *)whichOne {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"paneTapMode" object:@(NO)];
   
    if (featureAnimator) {
        [featureAnimator removeAllBehaviors];
        featureAnimator = nil;
    }
    if (featureView) {
        featureViewTV = nil;
        [featureView removeFromSuperview];
        featureView = nil;
    }
    [self makeFeatureViewForOption:whichOne];
    
    UIViewController *vc = [appD.navController.viewControllers lastObject];
    featureAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:vc.view];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ featureView ] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ featureView ] ];

    CGFloat bottomY = self.frame.size.height;
    if (self.frame.size.height > 568) {
        bottomY = 450;
    }
    [collision addBoundaryWithIdentifier:@"detailView" fromPoint:CGPointMake(0, bottomY) toPoint:CGPointMake(self.frame.size.width, bottomY)];
    
    [featureAnimator addBehavior:gravity];
    [featureAnimator addBehavior:collision];

   
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (tableView.tag) {
        case 0:
        {
           
        }
            break;
        case 1:
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            
            [[SettingsTool settings] setImageEffectStr:[[[SettingsTool settings] imageEffectList] objectAtIndex:indexPath.row]];
            [tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"restartCameraForFeatureChange" object:nil];
        }
            break;
        case 2:
        {
            selectedPreset = [[[PresetHandler tool] presetList] objectAtIndex:indexPath.row];
            [tableView reloadData];
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
            break;
            
    }
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 2) {
        return 36.0f;
    }
	return 60.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    
    switch (tableView.tag) {
        case 0:
           
            
            break;
        case 1:
            count = [[[SettingsTool settings] imageEffectList] count];
            break;
        case 2:
        {
            count = [[[PresetHandler tool] presetList] count];
        }
            break;

    }
    
	return count;
}

-(NSArray *)engineImageList {
    NSFileManager *fM = [[NSFileManager alloc] init];
    NSError *error = nil;
    
    NSArray *list = [fM  contentsOfDirectoryAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] error:&error];
    
    if (list) {
        return list;
    }
    
    return @[ ];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (tableView.tag == 0) {
        [tableView setTintColor:[UIColor blackColor]];
        NSString *picName = [[self engineImageList] objectAtIndex:indexPath.row];
        NSString *picPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] stringByAppendingPathComponent:picName];
        
        CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:picPath], NULL);
        CFDictionaryRef options = (CFDictionaryRef)CFBridgingRetain([[NSDictionary alloc] initWithObjectsAndKeys:
                                                                     (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                                                     (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                                                     (id)[NSNumber numberWithDouble:80], (id)kCGImageSourceThumbnailMaxPixelSize, nil
                                                                     ]);
        
        CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options); // Create scaled image
        CFRelease(options);
        CFRelease(src);
        
        cell.imageView.image = [UIImage imageWithCGImage:thumbnail];
        CGImageRelease(thumbnail);
        
        cell.accessoryType = [[[SettingsTool settings] chromaKeyImage] isEqualToString:picName] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.textLabel.text = picName;
    } else if (tableView.tag == 1) {
        NSString *this = [[[SettingsTool settings] imageEffectList] objectAtIndex:indexPath.row];
        cell.textLabel.text = this;
        cell.accessoryType = [[[SettingsTool settings] imageEffectStr] isEqualToString:this] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
    } else if (tableView.tag == 2) {
        NSString *this = [[[PresetHandler tool] presetList] objectAtIndex:indexPath.row];
        cell.textLabel.text = this;
        cell.textLabel.font = [cell.textLabel.font fontWithSize:12];
        cell.accessoryType = [selectedPreset isEqualToString:this] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}


-(void)userTappedDetailView:(UIGestureRecognizer *)g {
    if ((g) && (g.state != UIGestureRecognizerStateEnded) ) {
        return;
    }
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ featureView] ];
    
    [featureAnimator removeAllBehaviors];
    [featureAnimator addBehavior:gravity];
    
}

-(void)installDetailHeaderAtIndex:(NSInteger)index  subView:(UIView *)v withTitle:(NSString *)title LMR:(NSInteger)lmr {
    
    CGFloat x = 0;
    CGFloat w = v.bounds.size.width;
    
    if (lmr > 0) { // left half
        w = ( v.bounds.size.width / 2.0f) - 10;
    }
    
    if (lmr == 2) {
        x =  (v.bounds.size.width / 2.0f);
    }
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, 8 + (75 *index), w, 25)];
    l.text = title;
    l.font = [[[UtilityBag bag] standardFont] fontWithSize:15];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    [v addSubview:l];
}

-(void)addDoneButtonToView:(UIView *)v {
    GradientAttributedButton *button = nil;
    NSAttributedString *title = nil;
    
    NSString *bColor = @"#666666";
    NSString *eColor = @"#333333";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[UtilityBag bag] standardFont], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    button = [self installButtonAtRect:CGRectMake(v.bounds.size.width - 80 ,0,80,40) andTag:10700];
    title = [[NSAttributedString alloc] initWithString:@"Done" attributes:strAttr];
    [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = YES;
    [button update];
    button.tag = 10800;
    [v addSubview:button];
}

-(UILabel *)makeExplainViewForOption:(NSString *)whichOne withRect:(CGRect)f {
    UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
    dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
    [featureView addSubview:dSub];
    
    [self addDoneButtonToView:dSub];

    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,50,f.size.width, f.size.height - 50)];
    l.numberOfLines = 0;
    l.textColor = [UIColor blackColor];
    l.backgroundColor = [UIColor whiteColor];
    l.lineBreakMode = NSLineBreakByWordWrapping;
    l.textAlignment = NSTextAlignmentCenter;
    [dSub addSubview:l];
    
    if ([whichOne isEqualToString:@"infoCamera"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Camera" LMR:1];
    } else if ([whichOne isEqualToString:@"infoStabilization"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Image Stabilization" LMR:1];
    } else if ([whichOne isEqualToString:@"infoFlip"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Image Flip" LMR:1];
    } else if ([whichOne isEqualToString:@"infoRotationLock"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Rotation Lock" LMR:1];
    } else if ([whichOne isEqualToString:@"infoDataRate"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Video Data Rate" LMR:1];
    } else if ([whichOne isEqualToString:@"infoFPS"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Frame Rate" LMR:1];
    } else if ([whichOne isEqualToString:@"infoFocusLock"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Focus Lock" LMR:1];
    } else if ([whichOne isEqualToString:@"infoFocusReticle"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Focus Reticle" LMR:1];
    } else if ([whichOne isEqualToString:@"infoFocusRange"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Focus Range" LMR:1];
    } else if ([whichOne isEqualToString:@"infoFocusSpeed"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Focus Speed" LMR:1];
    } else if ([whichOne isEqualToString:@"infoExposureLock"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Exposure Lock" LMR:1];
    } else if ([whichOne isEqualToString:@"infoExposureReticle"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Exposure Reticle" LMR:1];
    } else if ([whichOne isEqualToString:@"infoISOLock"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"ISO Lock" LMR:1];
    } else if ([whichOne isEqualToString:@"infoWhiteBalance"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"White Balance" LMR:1];
    } else if ([whichOne isEqualToString:@"infoLevelingGuide"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Leveling Guide" LMR:1];
    } else if ([whichOne isEqualToString:@"infoThirdsGuide"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Thirds Guide" LMR:1];
    } else if ([whichOne isEqualToString:@"infoFramingGuide"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Framing Guide" LMR:1];
    } else if ([whichOne isEqualToString:@"infoCropStills"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Crop Stills" LMR:1];
    } else if ([whichOne isEqualToString:@"Torch Control"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Torch Control" LMR:1];
    } else if ([whichOne isEqualToString:@"infoTorchLevel"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Torch Level" LMR:1];
    } else if ([whichOne isEqualToString:@"infoZoomSpeed"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Zoom Speed" LMR:1];
    } else if ([whichOne isEqualToString:@"infoZoomStoredPosition"]) {
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Zoom Positions" LMR:1];
    }
    
    return l;
}


-(void)makeFeatureViewForOption:(NSString *)whichOne {

    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (featureView) {
        NSLog(@"detail view already present");
        return;
    }

    CGRect f = panelView.frame;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        featureView = [[UIView alloc] initWithFrame:CGRectMake(512 - (f.size.width / 2.0f), 0 - f.size.height, f.size.width, f.size.height)];
    } else {
        featureView = [[UIView alloc] initWithFrame:CGRectMake(f.origin.x, 0 - f.size.height, f.size.width, f.size.height)];
    }
    
    featureView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
  
    
    
    if ([whichOne isEqualToString:@"infoCamera"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option allows the selection of the front or back camera.";
    } else if ([whichOne isEqualToString:@"infoStabilization"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option removes unwanted shaking effects by reducing the visible field of view and continually adjusting the now smaller frame to compensate.";
    } else if ([whichOne isEqualToString:@"infoFlip"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"External lens adapters and accessories can present an upside-down image to the camera. This option flips the incoming image to compensate.";
    } else if ([whichOne isEqualToString:@"infoRotationLock"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"The camera will not rotate while recording. When enabled and not recording, this option stops the camera from rotating.";
    } else if ([whichOne isEqualToString:@"infoDataRate"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option controls the size of recorded video.  The settings modifies the average data rate in mbit/sec for recorded video at the current resolution.";
    } else if ([whichOne isEqualToString:@"infoFPS"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"The number of video frames stored each second.  Match your frame rate selection to a shutter speed for optimal results. 24 FPS is the most common rate.";
    } else if ([whichOne isEqualToString:@"infoFocusLock"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When set, locks the focus at the current setting. This value is not retained when the camera restarts.";
    } else if ([whichOne isEqualToString:@"infoFocusReticle"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When set to reticle mode, the focus mechanism uses the reticle position. When set to center mode, the focus mechansim uses the center of the screen.";
    } else if ([whichOne isEqualToString:@"infoFocusRange"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option restrics the focus mechansim to operate with a range. Near and Far restrict the focus mechanism; None does not.";
    } else if ([whichOne isEqualToString:@"infoFocusSpeed"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When set to fast, large changes in focus are seen in short time intervals. Smooth reduces the visual impact of focus changes, though it operates slower.";
    } else if ([whichOne isEqualToString:@"infoExposureLock"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When set, locks the exposure at the current setting. This value is not retained when the camera restarts.";
    } else if ([whichOne isEqualToString:@"infoExposureReticle"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When set to reticle mode, the exposure mechanism uses the reticle position. When set to center mode, the exposure mechansim uses the center of the screen.";
    } else if ([whichOne isEqualToString:@"infoISOLock"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When set, the camera will prompt to be pointed at a light source such that it can automatically regain the saved iso/exposure setting.";
    } else if ([whichOne isEqualToString:@"infoWhiteBalance"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When locked, the white balance mechansim will lock at it's current setting. This value is not retained when the camera restarts.";
    } else if ([whichOne isEqualToString:@"infoLevelingGuide"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option presents a leveling aid; three parallel lines on the screen, along with a continually updated set of parallel lines that are always level.";
    } else if ([whichOne isEqualToString:@"infoThirdsGuide"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option presents a presents a guide that shows a 3x3 grid over the video preview as a visual aid.";
    } else if ([whichOne isEqualToString:@"infoFramingGuide"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option presents a presents 4:3 or 1:1 guide for framing guide as a visual aid.";
    } else if ([whichOne isEqualToString:@"infoCropStills"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"When On, this option will automatically crop pictures to the area shown inside the 4:3 or 1:1 framing guide.";
    } else if ([whichOne isEqualToString:@"infoTorchControl"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option controls the built-in LED flash/torch.";
    } else if ([whichOne isEqualToString:@"infoTorchLevel"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option controls the intensity of the torch.";
    } else if ([whichOne isEqualToString:@"infoZoomSpeed"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"This option shows the current zoom speed. The two controls marked 'Speed' on the main camera interface control the speed setting.";
    } else if ([whichOne isEqualToString:@"infoZoomStoredPosition"]) {
        UILabel *descLabel = [self makeExplainViewForOption:whichOne withRect:f];
        descLabel.text = @"Zoom in/out to a desired position, tap the 'Set' button to mark it, use the main camera interface Z1 - Z3 buttons to return to marked positions.";
    } else if ([whichOne isEqualToString:@"imageEffect"]) {
        
        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [featureView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Image Effect" LMR:0];
        
        featureViewTV = [[UITableView alloc] initWithFrame:CGRectMake(0,42,dSub.bounds.size.width,dSub.bounds.size.height - 42)];
        [featureViewTV setTintColor:[UIColor blackColor]];
        featureViewTV.tag = 1;
        featureViewTV.delegate = self;
        featureViewTV.dataSource = self;
        [dSub addSubview:featureViewTV];
        
        [self addDoneButtonToView:dSub];
    } else if ([whichOne isEqualToString:@"textEdit"]) {

        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [featureView addSubview:dSub];
        
        NSString *choiceStr = @"Title";
        NSString *choiceTextStr = @"";
        if (textEditChoice == 1) {
            choiceStr = @"Title";
            choiceTextStr = [[SettingsTool settings] engineTitlingTitle];
        } else if (textEditChoice == 2) {
            choiceStr = @"Author";
            choiceTextStr = [[SettingsTool settings] engineTitlingAuthor];
        } else if (textEditChoice == 3) {
            choiceStr = @"Scene";
            choiceTextStr = [[SettingsTool settings] engineTitlingScene];
        } else if (textEditChoice == 4) {
            choiceStr = @"New Preset Name";
            choiceTextStr = [[SettingsTool settings] engineTitlingScene];
        }
        
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:[NSString stringWithFormat:@"%@", choiceStr] LMR:0];
        
        [self addDoneButtonToView:dSub];
        
        UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(0,42,dSub.bounds.size.width,80)];
        tv.delegate = self;
        tv.text = choiceTextStr;
        [dSub addSubview:tv];
        [tv performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0f];
    } else if ([whichOne isEqualToString:@"resolution"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [featureView addSubview:dSub];
        
        [self addDoneButtonToView:dSub];

        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Resolution" LMR:0];
        
        CGSize buttonSize = CGSizeMake(70,44);
        
        NSArray *yOffsets = @[ [NSNumber numberWithFloat:20],
                               [NSNumber numberWithFloat:72],
                               [NSNumber numberWithFloat:127],
                               [NSNumber numberWithFloat:185]
                               ];
        
        NSArray *xOffsets = @[ [NSNumber numberWithFloat:1.5],
                               [NSNumber numberWithFloat:74],
                               [NSNumber numberWithFloat:147.5],
                               
                               ];
        
        if ([[UIScreen mainScreen] bounds].size.height >= 568.0f) {
            xOffsets =   @[ [NSNumber numberWithFloat:5],
                            [NSNumber numberWithFloat:154 - 45],
                            [NSNumber numberWithFloat:308 - 95],
                            
                            ];
            buttonSize = CGSizeMake(90,44);
        }

        
        
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *sbColor = @"#006600";
        NSString *seColor = @"#003300";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSInteger res = [[SettingsTool settings] captureOutputResolution];
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
       
        if (![[SettingsTool settings] fastCaptureMode]) {
            button = [self installButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height) andTag:20000 + 540];
            title = [[NSAttributedString alloc] initWithString:@"960x540" attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:res == 540 ? sbColor : bColor endGradientColor:res == 540 ? seColor : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
        }
        
        button = [self installButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height) andTag:20000 + 720];
        title = [[NSAttributedString alloc] initWithString:@"1280x720" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:res == 720 ? sbColor : bColor endGradientColor:res == 720 ? seColor : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        if ( (![[SettingsTool settings] isOldDevice]) && (![[SettingsTool settings] fastCaptureMode]) ) {
            button = [self installButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height) andTag:20000 + 1080];
            title = [[NSAttributedString alloc] initWithString:@"1920x1080" attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:res == 1080 ? sbColor : bColor endGradientColor:res == 1080 ? seColor : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];

            
            button = [self installButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height) andTag:20000 + 480];
            title = [[NSAttributedString alloc] initWithString:@"854x480" attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:res == 480 ? sbColor : bColor endGradientColor:res == 480 ? seColor : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
            
            button = [self installButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height) andTag:20000 + 576];
            title = [[NSAttributedString alloc] initWithString:@"1024x576" attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:res == 576 ? sbColor : bColor endGradientColor:res == 576 ? seColor : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
            
            button = [self installButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height) andTag:20000 + 360];
            title = [[NSAttributedString alloc] initWithString:@"640x360" attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:res == 360 ? sbColor : bColor endGradientColor:res == 360 ? seColor : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
        
        }
        
    } else if ([whichOne isEqualToString:@"frameRate"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [featureView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Frame Rate" LMR:0];
        
        CGSize buttonSize = CGSizeMake(70,44);
        
        NSArray *yOffsets = @[ [NSNumber numberWithFloat:20],
                               [NSNumber numberWithFloat:74],
                               [NSNumber numberWithFloat:127],
                               [NSNumber numberWithFloat:185]
                               ];
        
        NSArray *xOffsets = @[ [NSNumber numberWithFloat:1.5],
                               [NSNumber numberWithFloat:74],
                               [NSNumber numberWithFloat:147.5],
                               
                               ];
        
        if ([[UIScreen mainScreen] bounds].size.height >= 568.0f) {
            xOffsets =   @[ [NSNumber numberWithFloat:5],
                            [NSNumber numberWithFloat:154 - 45],
                            [NSNumber numberWithFloat:308 - 95],
                            
                            ];
            buttonSize = CGSizeMake(90,44);
        }
        
        
        
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *sbColor = @"#006600";
        NSString *seColor = @"#003300";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSInteger res = [[SettingsTool settings] videoCameraFrameRate];
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        button = [self installButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height) andTag:4001];
        title = [[NSAttributedString alloc] initWithString:@"1" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:res == 1 ? sbColor : bColor endGradientColor:res == 1 ? seColor : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height) andTag:4024];
        title = [[NSAttributedString alloc] initWithString:@"24" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:res == 24 ? sbColor : bColor endGradientColor:res == 24 ? seColor : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height) andTag:4030];
        title = [[NSAttributedString alloc] initWithString:@"30" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:res == 30 ? sbColor : bColor endGradientColor:res == 30 ? seColor : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        if ([[SettingsTool settings] fastCaptureMode]) {
            button = [self installButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height) andTag:4048];
            title = [[NSAttributedString alloc] initWithString:@"48" attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:res == 48 ? sbColor : bColor endGradientColor:res == 48 ? seColor : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
            
            NSInteger maxRate = [[SettingsTool settings] currentMaxFrameRate];
            
            if (maxRate >= 90) {
                button = [self installButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height) andTag:4060];
                title = [[NSAttributedString alloc] initWithString:@"60" attributes:strAttr];
                [button setTitle:title disabledTitle:title beginGradientColorString:res == 60 ? sbColor : bColor endGradientColor:res == 60 ? seColor : eColor];
                button.enabled = YES;
                [button update];
                [dSub addSubview:button];
            }
            
            if (maxRate >= 120) {
                button = [self installButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height) andTag:4120];
                title = [[NSAttributedString alloc] initWithString:@"120" attributes:strAttr];
                [button setTitle:title disabledTitle:title beginGradientColorString:res == 120 ? sbColor : bColor endGradientColor:res == 120 ? seColor : eColor];
                button.enabled = YES;
                [button update];
                [dSub addSubview:button];
            }
        }
    }
    UIViewController *vc = [appD.navController.viewControllers lastObject];
    [vc.view addSubview:featureView];
    [vc.view bringSubviewToFront:featureView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    NSString *textStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    switch (textEditChoice) {
        case 1:
            [[SettingsTool settings] setEngineTitlingTitle:textStr];
            [self showControlsForSelected];
            break;
        case 2:
            [[SettingsTool settings] setEngineTitlingAuthor:textStr];
            [self showControlsForSelected];
            break;
        case 3:
            [[SettingsTool settings] setEngineTitlingScene:textStr];
            [self showControlsForSelected];
            break;
        case 4:
        {
            addPresetName = textStr;
            [self showControlsForSelected];
        }
            break;
    }
    
    return YES;
}

-(BOOL)isReadyForImage {
    BOOL ready = YES;
    
    if ([self isRecording]) {
        ready = NO;
    }

    if (processingHistogram) {
        ready = NO;
    }
    
    if (!histogramView.superview) {
        ready = NO;
    }
    
    return ready;
}

-(void)didGenerateHistogram:(GPUImageOutput *)histogram withPicture:(GPUImagePicture *)picture {
    processingHistogram = YES;
    [histogram addTarget:histogramView];
    [picture processImageWithCompletionHandler:^{
        processingHistogram = NO;
        [picture removeAllTargets];
    }];
}

@end
