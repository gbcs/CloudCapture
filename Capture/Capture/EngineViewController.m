//
//  EngineViewController.m
//  Capture
//
//  Created by Gary Barnett on 7/27/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "EngineViewController.h"
#import "EngineLines.h"
#import "HelpViewController.h"
#import "AppDelegate.h"
#import "ImportImageViewController.h"
#import <ImageIO/ImageIO.h>
#import "RedXView.h"
#import "TitleEditViewController.h"

@interface EngineViewController () {
    BOOL setupComplete;
    BOOL changed;
    EngineLines *engineLines;
    UIView *detailView;
    UITableView *detailViewTV;
    UIDynamicAnimator *detailAnimator;
    UINavigationController *navController;
    RedXView *headphoneX;
    BOOL titleChoiceIsEnd;
    UIDynamicAnimator *featureAnimator;
    UIView *featureView;
    UITableView *featureViewTV;
    BOOL titlingSetupActive;
     NSDictionary *positionDict;
    NSDictionary *statusDict;
}

@end

@implementation EngineViewController

-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
        // NSLog(@"%@:%s", [self class], __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    

    engineLines = nil;
    detailView = nil;
    detailViewTV = nil;
    detailAnimator = nil;
    navController = nil;
    headphoneX = nil;
  
    featureAnimator = nil;
    featureView = nil;
    featureViewTV = nil;

    positionDict = nil;
    statusDict = nil;
}

-(void)installDetailHeaderAtIndex:(NSInteger)index  subView:(UIView *)v withTitle:(NSString *)title LMR:(NSInteger)lmr withyOffset:(CGFloat)y {
    
    CGFloat x = 0;
    CGFloat w = v.bounds.size.width;
    
    if (lmr > 0) { // left half
        w = ( v.bounds.size.width / 2.0f) - 10;
    }
    
    if (lmr == 2) {
        x =  (v.bounds.size.width / 2.0f);
    }
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, y + (55 *index), w, 25)];
    l.text = title;
    l.font = [[[UtilityBag bag] standardFont] fontWithSize:15];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    [v addSubview:l];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)showDetailViewForOption:(NSString *)whichOne {
    [self updateElements];
    
    if (detailAnimator) {
        [detailAnimator removeAllBehaviors];
        detailAnimator = nil;
    }
    if (detailView) {
        detailViewTV = nil;
        [detailView removeFromSuperview];
        detailView = nil;
    }
    [self makeDetailViewForOption:whichOne];
   
    detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
   
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView ] ];
    
    CGFloat bottomY = self.view.frame.size.height;
    [collision addBoundaryWithIdentifier:@"detailView" fromPoint:CGPointMake(0, bottomY) toPoint:CGPointMake(self.view.frame.size.width, bottomY)];
   
    [detailAnimator addBehavior:gravity];
    [detailAnimator addBehavior:collision];
    
    BOOL suppressDetailTap = NO;
    
    if ([whichOne isEqualToString:@"chromaKey"]) {
        suppressDetailTap = YES;
    } else if ([whichOne isEqualToString:@"imageEffect"]) {
        suppressDetailTap = YES;
    } else if ([whichOne isEqualToString:@"remote"]) {
        suppressDetailTap = YES;
    }

    if (!suppressDetailTap ) {
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedDetailView:)];
        [detailView addGestureRecognizer:tapG];
    }
}

-(void)userTappedDetailView:(UIGestureRecognizer *)g {
    if ((g) && (g.state != UIGestureRecognizerStateEnded) ) {
        return;
    }
    
    titlingSetupActive = NO;
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    
    [detailAnimator removeAllBehaviors];
    [detailAnimator addBehavior:gravity];
    
}

-(GradientAttributedButton *)installButtonAtRect:(CGRect)rect andTag:(NSInteger)tag {
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:rect];
    button.delegate = self;
    button.tag = tag;
    return button;
}

-(GradientAttributedButton *)makeButtonAtRect:(CGRect)rect withTitle:(NSString *)title andTag:(NSInteger)tag beginColor:(NSString *)bColor endColor:(NSString *)eColor largeFont:(BOOL)largeFont {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              largeFont ? [[[UtilityBag bag] standardFontBold] fontWithSize:15] : [[[UtilityBag bag] standardFont] fontWithSize:12] , NSFontAttributeName,
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
    
    return button;
}

-(void)rebuildTitlingSetupPage {
    UIView *dSub = [detailView.subviews objectAtIndex:0];
    
    GradientAttributedButton *button1 = (GradientAttributedButton *)[dSub viewWithTag:1000]; //begin name
    GradientAttributedButton *button2 = (GradientAttributedButton *)[dSub viewWithTag:1002]; //begin duration
    GradientAttributedButton *button3 = (GradientAttributedButton *)[dSub viewWithTag:1004]; // end name
    GradientAttributedButton *button4 = (GradientAttributedButton *)[dSub viewWithTag:1006]; //end duration
    
    
    NSString *optionColorBegin = @"#666666";
    NSString *optionColorEnd = @"#333333";
    
    NSString *valueColorBegin = @"#006600";
    NSString *valueColorEnd = @"#003300";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[UtilityBag bag] standardFont], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:[[SettingsTool settings] engineTitlingBeginName] attributes:strAttr];
    
    [button1 setTitle:str disabledTitle:str beginGradientColorString:optionColorBegin endGradientColor:optionColorEnd];
    
    str = [[NSAttributedString alloc] initWithString:[[SettingsTool settings] engineTitlingEndName] attributes:strAttr];
    
    [button3 setTitle:str disabledTitle:str beginGradientColorString:optionColorBegin endGradientColor:optionColorEnd];
    
    str = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld sec", (long)[[SettingsTool settings] engineTitlingBeginDuration]] attributes:strAttr];
    
    [button2 setTitle:str disabledTitle:str beginGradientColorString:valueColorBegin endGradientColor:valueColorEnd];
  
    str = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld sec", (long)[[SettingsTool settings] engineTitlingEndDuration]] attributes:strAttr];
    
    [button4 setTitle:str disabledTitle:str beginGradientColorString:valueColorBegin endGradientColor:valueColorEnd];
    

}

-(void)makeFeatureViewForOption:(NSString *)whichOne {
    
    if (featureView) {
            //NSLog(@"detail view already present");
        return;
    }
    
    CGRect f = CGRectMake((self.view.frame.size.width / 2.0f) - 175,0,350,250);
    
    featureView = [[UIView alloc] initWithFrame:CGRectMake(f.origin.x, 0 - f.size.height, f.size.width, f.size.height)];
    featureView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    
    if ([whichOne isEqualToString:@"titling"]) {
        
        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [featureView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Titling" LMR:0 withyOffset:0];
        
        featureViewTV = [[UITableView alloc] initWithFrame:CGRectMake(0,42,dSub.bounds.size.width,dSub.bounds.size.height - 42)];
        [featureViewTV setTintColor:[UIColor blackColor]];
        featureViewTV.tag = titleChoiceIsEnd ? 3 : 2;
        featureViewTV.delegate = self;
        featureViewTV.dataSource = self;
        [dSub addSubview:featureViewTV];
        
        
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
        
        button = [self installButtonAtRect:CGRectMake(5 ,0,80,40) andTag:10700];
        title = [[NSAttributedString alloc] initWithString:@"Done" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        button.tag = 1020;
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake(featureView.bounds.size.width - 85,0,80,40) andTag:10700];
        title = [[NSAttributedString alloc] initWithString:@"Add" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        button.tag = 1021;
        [dSub addSubview:button];
    }
    
    [self.view addSubview:featureView];
    [self.view bringSubviewToFront:featureView];
}


-(void)showFeatureViewForOption:(NSString *)whichOne {
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
    
    featureAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
   
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ featureView ] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ featureView ] ];
    
    //CGFloat midY = self.view.frame.size.height / 2.0f;
    // CGFloat bottomY = midY + (detailView.bounds.size.height / 2.0f);
    
    CGFloat bottomY = self.view.frame.size.height;
    [collision addBoundaryWithIdentifier:@"detailView" fromPoint:CGPointMake(0, bottomY) toPoint:CGPointMake(self.view.frame.size.width, bottomY)];
    
    [featureAnimator addBehavior:gravity];
    [featureAnimator addBehavior:collision];
    
    BOOL suppressDetailTap = NO;
    
    if ([whichOne isEqualToString:@"titling"]) {
        suppressDetailTap = YES;
    }
    
    if (!suppressDetailTap ) {
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedDetailView:)];
        [featureView addGestureRecognizer:tapG];
    }
    
    
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
    
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (tag == -1) {
        [detailAnimator removeAllBehaviors];
    }
    
    if (tag == 900) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];
        [[SettingsTool settings] setFastCaptureMode:NO];
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        [self performSelector:@selector(reloadEngine) withObject:nil afterDelay:0.5];
    } else if (tag == 901) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];
        
        [[SettingsTool settings] setFastCaptureMode:YES];
        [[SettingsTool settings] setVideoCameraFrameRate:60];
        if ([[SettingsTool settings] currentMaxFrameRate] > 60) {
           [[SettingsTool settings] setVideoCameraFrameRate:120];
        }
        [[SettingsTool settings] setCameraIsBack:YES];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        [self performSelector:@selector(reloadEngine) withObject:nil afterDelay:0.5];
    } else if ( (tag >=1000) && (tag < 1999)) {
        switch ( tag) {
            case 1000: //begin title
                titleChoiceIsEnd = NO;
                [self showFeatureViewForOption:@"titling"];
                break;
            case 1001: //duration minus
            {
                NSInteger duration = [[SettingsTool settings] engineTitlingBeginDuration];
                duration--;
                if (duration <1) {
                    duration = 1;
                }
                [[SettingsTool settings] setEngineTitlingBeginDuration:duration];
                [self rebuildTitlingSetupPage];
            }
                break;
            case 1002:
                break;
            case 1003: //duration plus
            {
                NSInteger duration = [[SettingsTool settings] engineTitlingBeginDuration];
                duration++;
                [[SettingsTool settings] setEngineTitlingBeginDuration:duration];
                [self rebuildTitlingSetupPage];
            }
                break;
            case 1004: // end title
                titleChoiceIsEnd = YES;
                [self showFeatureViewForOption:@"titling"];
                break;
            case 1005: //duration minus
            {
                NSInteger duration = [[SettingsTool settings] engineTitlingEndDuration];
                duration--;
                if (duration <1) {
                    duration = 1;
                }
                [[SettingsTool settings] setEngineTitlingEndDuration:duration];
                [self rebuildTitlingSetupPage];
            }
                break;
            case 1006:
                break;
            case 1007: //duration plus
            {
                NSInteger duration = [[SettingsTool settings] engineTitlingEndDuration];
                duration++;
                [[SettingsTool settings] setEngineTitlingEndDuration:duration];
                [self rebuildTitlingSetupPage];
            }
                break;
            case 1010: //edit begin title
            {
                titleChoiceIsEnd = NO;
                NSString *titleName =[[SettingsTool settings] engineTitlingBeginName];
                if ([titleName isEqualToString:@"None"]) {
                    [self showFeatureViewForOption:@"titling"];
                } else {
                    TitleEditViewController *configureVC = [[TitleEditViewController alloc] initWithNibName:@"TitleEditViewController" bundle:nil];
                    configureVC.pageToLoad =  [NSString stringWithFormat:@"%@.title",  titleName];
                    configureVC.isBeginTitle = !titleChoiceIsEnd;
                    [self.navigationController pushViewController:configureVC animated:YES];
                }
            }
                break;
            case 1011: //edit end title
            {
                titleChoiceIsEnd = YES;
                NSString *titleName =[[SettingsTool settings] engineTitlingEndName];
                if ([titleName isEqualToString:@"None"]) {
                    [self showFeatureViewForOption:@"titling"];
                } else {
                    TitleEditViewController *configureVC = [[TitleEditViewController alloc] initWithNibName:@"TitleEditViewController" bundle:nil];
                    configureVC.pageToLoad =  [NSString stringWithFormat:@"%@.title",  titleName];
                    configureVC.isBeginTitle = !titleChoiceIsEnd;
                    [self.navigationController pushViewController:configureVC animated:YES];
                }
            }
                break;
            case 1020: // title selector done
            {
                [self closeFeatureView];
                [self rebuildTitlingSetupPage];
            }
                break;
            case 1021: //title selector add
            {
                TitleEditViewController *configureVC = [[TitleEditViewController alloc] initWithNibName:@"TitleEditViewController" bundle:nil];
                configureVC.pageToLoad = nil;
                configureVC.isBeginTitle = !titleChoiceIsEnd;
                [self.navigationController pushViewController:configureVC animated:YES];
                [self closeFeatureView];
            }
                break;
        }
    } else if ( (tag >=10000) && (tag <= 10099)) { // microphone
        NSInteger index = tag - 10000;
        NSInteger count = [[[AVAudioSession sharedInstance] availableInputs] count];
        if (count <= index) {
            index = count -1;
        }
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        [[AudioManager manager] setMicrophoneIndex:index];
        
        [self performSelector:@selector(updateAudioInput:) withObject:[[[AVAudioSession sharedInstance] availableInputs] objectAtIndex:index] afterDelay:0.75];
        [self performSelector:@selector(showDetailViewForOption:) withObject:@"microphone" afterDelay:1.5];
    } else if ( (tag >=10100) && (tag <= 10199)) { // microphone
        NSInteger index = tag - 10100;
        
        AVAudioSessionPortDescription *port = [[[AVAudioSession sharedInstance] availableInputs] objectAtIndex:[[AudioManager manager] microphoneIndex]];
        NSInteger count = [port.dataSources count];
        
        if (count <= index) {
            index = count -1;
        }
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];

        [self performSelector:@selector(updateAudioSource:) withObject:[port.dataSources objectAtIndex:index] afterDelay:0.75];
        [self performSelector:@selector(showDetailViewForOption:) withObject:@"microphone" afterDelay:1.5];
    } else if ( (tag >=10200) && (tag <= 10299)) { // microphone
        NSInteger index = tag - 10200;
        
        AVAudioSessionPortDescription *port = [[[AVAudioSession sharedInstance] availableInputs] objectAtIndex:[[AudioManager manager] microphoneIndex]];
        AVAudioSessionDataSourceDescription *desc = port.selectedDataSource;
        
        NSInteger count = [[desc supportedPolarPatterns] count];
        
        if (count <= index) {
            index = count -1;
        }
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        [self performSelector:@selector(updatePolarPattern:) withObject:[[desc supportedPolarPatterns] objectAtIndex:index] afterDelay:0.75];
        [self performSelector:@selector(updateElements) withObject:nil afterDelay:1.5];
    } else if ( (tag >=10300) && (tag <= 10399)) { // microphone
        NSInteger index = tag - 10300;
        
        switch (index) {
            case 0:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioSampleRateSet" object:@8000.0f];
                break;
            case 1:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioSampleRateSet" object:@11025.0f];
                break;
            case 2:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioSampleRateSet" object:@16000.0f];
                break;
            case 3:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioSampleRateSet" object:@22050.0f];
                break;
            case 4:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioSampleRateSet" object:@32000.0f];
                break;
            case 5:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioSampleRateSet" object:@44100.0f];
                break;
            case 6:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioSampleRateSet" object:@48000.0f];
                break;
        }
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        [self performSelector:@selector(updateElements) withObject:nil afterDelay:0.5];
    } else if ( (tag >=10400) && (tag <= 10499)) { // microphone
        NSInteger index = tag - 10400;
        
        switch (index) {
            case 0:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioAACEncodingEnable" object:nil];
                [self performSelector:@selector(updateElements) withObject:nil afterDelay:0.5];
                break;
            case 1:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioAACEncodingDisable" object:nil];
                 [self performSelector:@selector(updateElements) withObject:nil afterDelay:0.5];
                break;
            case 2:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioAACQualityDecrement" object:nil];
                [self performSelector:@selector(showDetailViewForOption:) withObject:@"encoding" afterDelay:0.75];
                break;
            case 3:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"audioAACQualityIncrement" object:nil];
                [self performSelector:@selector(showDetailViewForOption:) withObject:@"encoding" afterDelay:0.75];
                break;
        }
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        
    } else if ( (tag >=10500) && (tag <= 10599)) { // mode
        NSInteger index = tag - 10500;
        
        switch (index) {
            case 0:
            {
                AVAudioSession *session = [AVAudioSession sharedInstance];
                NSError *error = nil;
                [session setMode:AVAudioSessionModeDefault error:&error];
            }
                break;
            case 1:
            {
                AVAudioSession *session = [AVAudioSession sharedInstance];
                NSError *error = nil;
                [session setMode:AVAudioSessionModeVideoRecording error:&error];
            }
                break;
            case 2:
            {
                AVAudioSession *session = [AVAudioSession sharedInstance];
                NSError *error = nil;
                [session setMode:AVAudioSessionModeMeasurement error:&error];
            }
                break;
        }
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        [self performSelector:@selector(updateElements) withObject:nil afterDelay:0.5];
    } else if ( (tag >=10600) && (tag <= 10699)) { // mode
        NSInteger index = tag - 10600;
    
        [[SettingsTool settings] setEngineOverlayType:[NSNumber numberWithInteger:index]];
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        
        [self performSelector:@selector(updateElements) withObject:nil afterDelay:0.5];
    } else if (tag == 10700) {
        ImportImageViewController *vc = [[ImportImageViewController alloc] initWithNibName:@"ImportImageViewController" bundle:nil];
        vc.popToRootWhenDone = NO;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (tag == 10701) {
        [self userTappedDetailView:nil];
    } else if (tag == 10800) {
        [self userTappedDetailView:nil];
    } else if (tag == 10900) {
        [self userTappedDetailView:nil];
    } else if (tag == 10901) {
    
    } else if (tag == 11000) {
        [self userTappedDetailView:nil];
        [self performSelector:@selector(showDetailViewForOption:) withObject:@"remote" afterDelay:1.5f];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [[SettingsTool settings] setEngineRemotePassword:[[RemoteAdvertiserManager manager] generatePassword]];
        });
    } else if (tag == 11001) {
        [[SettingsTool settings] setEngineRemoteShowPassword:NO];
         [self userTappedDetailView:nil];
        [self performSelector:@selector(showDetailViewForOption:) withObject:@"remote" afterDelay:1.5f];
    } else if (tag == 11002) {
        [[SettingsTool settings] setEngineRemoteShowPassword:YES];
         [self userTappedDetailView:nil];
        [self performSelector:@selector(showDetailViewForOption:) withObject:@"remote" afterDelay:1.5f];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.toolbarHidden = YES;
    if (titlingSetupActive ) {
        [self rebuildTitlingSetupPage];
    }

    self.directMode  = [[SettingsTool settings] fastCaptureMode];
    if ([[SettingsTool settings] isOldDevice]) {
        self.directMode = YES;
    }
    [self setupElements];
    [self updateElements];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateElements];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
    
    }];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


-(void)updatePolarPattern:(NSString *)patternStr {
    NSError *error = nil;
        //NSLog(@"updatePolarPattern:%@", patternStr);
    
    AVAudioSessionPortDescription *port = [[[AVAudioSession sharedInstance] availableInputs] objectAtIndex:[[AudioManager manager] microphoneIndex]];
    AVAudioSessionDataSourceDescription *desc = port.selectedDataSource;
    
    [desc setPreferredPolarPattern:patternStr error:&error];
    if (error) {
        NSLog(@"updatePolarPattern:%@", [error localizedDescription]);
    }
}

-(void)updateAudioSource:(AVAudioSessionDataSourceDescription *)source {
    NSError *error = nil;
        //NSLog(@"updateAudioSource:%@", source);
    
    [[AVAudioSession sharedInstance] setInputDataSource:source error:&error];
    
    if (error) {
        NSLog(@"updateAudioSourceErr:%@", [error localizedDescription]);
    }
    AVAudioSessionPortDescription *port = [[[AVAudioSession sharedInstance] availableInputs] objectAtIndex:[[AudioManager manager] microphoneIndex]];
    
    [[AVAudioSession sharedInstance] setPreferredInput:port error:&error];
}

-(void)updateAudioInput:(AVAudioSessionPortDescription *)port {
    NSError *error = nil;
        //NSLog(@"updateAudioInput:%@", port);
   
    [[AVAudioSession sharedInstance] setPreferredInput:port error:&error];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (tableView.tag) {
        case 0:
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            [[SettingsTool settings] setChromaKeyImage:[[[UtilityBag bag] engineImageList] objectAtIndex:indexPath.row]];
            for (NSInteger x=0;x<[[[UtilityBag bag] engineImageList] count];x++) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:x inSection:0]];
                cell.accessoryType = (indexPath.row == x) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
        }
            break;
        case 2:
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            
            [[SettingsTool settings] setEngineTitlingBeginName:[[[SettingsTool settings] titlingPageList] objectAtIndex:indexPath.row]];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.01];
        }
            break;
        case 3:
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            
            [[SettingsTool settings] setEngineTitlingEndName:[[[SettingsTool settings] titlingPageList] objectAtIndex:indexPath.row]];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.01];
        }
            break;

    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    
    switch (tableView.tag) {
        case 0:
            count = [[[UtilityBag bag] engineImageList] count];
            break;
        case 2:
        case 3:
            count = [[[SettingsTool settings] titlingPageList] count];
            break;
    }
    
	return count;
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.font = [[[UtilityBag bag] standardFont] fontWithSize:15];
    
    if (tableView.tag == 0) {
        [tableView setTintColor:[UIColor blackColor]];
        NSString *picName = [[[UtilityBag bag] engineImageList] objectAtIndex:indexPath.row];
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
    } else if (tableView.tag == 2) {
        NSString *this = [[[SettingsTool settings] titlingPageList] objectAtIndex:indexPath.row];
        cell.textLabel.text = this;
        cell.accessoryType = ([this isEqualToString:[[SettingsTool settings] engineTitlingBeginName]]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
    } else if (tableView.tag == 3) {
        NSString *this = [[[SettingsTool settings] titlingPageList] objectAtIndex:indexPath.row];
        cell.textLabel.text = this;
        cell.accessoryType = ([this isEqualToString:[[SettingsTool settings] engineTitlingEndName]]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }

   
    
    return cell;
}

-(void)makeDetailViewForOption:(NSString *)whichOne {
    if (detailView) {
            // NSLog(@"detail view already present");
        return;
    }
    
    CGFloat midX = self.view.frame.size.width / 2.0f;

    detailView = [[UIView alloc] initWithFrame:CGRectMake(0,-self.view.frame.size.height,self.view.frame.size.width, self.view.frame.size.height)];
    detailView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    
    if ([whichOne isEqualToString:@"camera"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 125,64,250,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Camera Mode Selection" LMR:0 withyOffset:10];
        
        CGFloat yOffset = 40;
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bColorSel = @"#004400";
        NSString *eColorSel = @"#001100";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
    
        button = [self installButtonAtRect:CGRectMake(20 ,yOffset,210,44) andTag:900];
        title = [[NSAttributedString alloc] initWithString:@"Image Quality (default)" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:![[SettingsTool settings] fastCaptureMode] ? bColorSel : bColor endGradientColor:![[SettingsTool settings] fastCaptureMode] ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        
        button = [self installButtonAtRect:CGRectMake(20,yOffset + 75,210,44) andTag:901];
        
        NSInteger maxRate = 30;
        
        if ([[SettingsTool settings] isiPhone5] || [[SettingsTool settings] isIPadMini] || [[SettingsTool settings] isiPad3] || [[SettingsTool settings] isiPadAir]) {
            maxRate = 60;
        } else if ([[SettingsTool settings] isiPhone5S]) {
            maxRate = 120;
        }
        
        if (![[SettingsTool settings] isiPhone4S]) {
            NSString *frameRateStr = [NSString stringWithFormat:@"Fast Frame Rate (31-%ld fps)", (long)maxRate ];
            title = [[NSAttributedString alloc] initWithString:frameRateStr  attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:[[SettingsTool settings] fastCaptureMode] ? bColorSel : bColor endGradientColor:[[SettingsTool settings] fastCaptureMode] ?  eColorSel : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
        }
    } else if ([whichOne isEqualToString:@"remote"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 200,64,400,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Director" LMR:0 withyOffset:10];
        
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bsColor = @"#006600";
        NSString *esColor = @"#003300";
        
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        button = [self installButtonAtRect:CGRectMake(320 ,0,80,46) andTag:10701];
        title = [[NSAttributedString alloc] initWithString:@"Done" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        [self installDetailHeaderAtIndex:1 subView:dSub withTitle:@"Current Password" LMR:0 withyOffset:10];
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,100,400, 70)];
        l.backgroundColor = [UIColor whiteColor];
        l.textColor =[UIColor blackColor];
        l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline] size:30];
        l.text = [[SettingsTool settings] engineRemotePassword];
        [dSub addSubview:l];
        
        button = [self installButtonAtRect:CGRectMake(0 ,0,80,46) andTag:11000];
        title = [[NSAttributedString alloc] initWithString:@"Change Password" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        [self installDetailHeaderAtIndex:3 subView:dSub withTitle:@"Show Password on Device When Connecting" LMR:0 withyOffset:10];
        
        button = [self installButtonAtRect:CGRectMake(200 - 80 ,200,80,46) andTag:11001];
        title = [[NSAttributedString alloc] initWithString:@"No" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:![[SettingsTool settings] engineRemoteShowPassword] ? bsColor : bColor endGradientColor:![[SettingsTool settings] engineRemoteShowPassword] ? esColor : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake(200 + 40 ,200,80,46) andTag:11002];
        title = [[NSAttributedString alloc] initWithString:@"Yes" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:[[SettingsTool settings] engineRemoteShowPassword] ? bsColor : bColor endGradientColor:[[SettingsTool settings] engineRemoteShowPassword] ? esColor : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
    } else if ([whichOne isEqualToString:@"chromaKey"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 200,64,400,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Chroma Key Image Selection" LMR:0 withyOffset:10];
        
        detailViewTV = [[UITableView alloc] initWithFrame:CGRectMake(0,42,400,208)];
        detailViewTV.tag = 0;
        detailViewTV.delegate = self;
        detailViewTV.dataSource = self;
        [dSub addSubview:detailViewTV];
        
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
        
        button = [self installButtonAtRect:CGRectMake(320 ,0,80,40) andTag:10700];
        title = [[NSAttributedString alloc] initWithString:@"Add Image" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        button.tag = 10700;
        [dSub addSubview:button];
        
        
        button = [self installButtonAtRect:CGRectMake(5 ,0,80,40) andTag:10700];
        title = [[NSAttributedString alloc] initWithString:@"Done" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        button.tag = 10701;
        [dSub addSubview:button];
    } else if ([whichOne isEqualToString:@"overlay"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 125,64,250,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Overlay Selection" LMR:0 withyOffset:10];
        
        CGFloat yOffset = 40;
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bColorSel = @"#004400";
        NSString *eColorSel = @"#001100";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        NSInteger matteMode = [[[SettingsTool settings] engineOverlayType] integerValue];
        
        
        
        
        button = [self installButtonAtRect:CGRectMake(65 ,yOffset,120,44) andTag:10600];
        title = [[NSAttributedString alloc] initWithString:@"Matte: 2.20" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:matteMode == 0 ? bColorSel : bColor endGradientColor:matteMode == 0 ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake(65,yOffset + 50,120,44) andTag:10601];
        title = [[NSAttributedString alloc] initWithString:@"Matte: 2.35" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:matteMode == 1 ? bColorSel : bColor endGradientColor:matteMode == 1 ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake(65,yOffset + 100,120,44) andTag:10602];
        title = [[NSAttributedString alloc] initWithString:@"Matte: 2.40" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:matteMode == 2 ? bColorSel : bColor endGradientColor:matteMode == 2 ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake(65,yOffset + 150,120,44) andTag:10603];
        title = [[NSAttributedString alloc] initWithString:@"Time+Location" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:matteMode == 3 ? bColorSel : bColor endGradientColor:matteMode == 3 ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
    } else if ([whichOne isEqualToString:@"microphone"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 200,64,400,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Input Device" LMR:1 withyOffset:10];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Microphone" LMR:2 withyOffset:10];
        
        GradientAttributedButton *button = nil;
        CGFloat yOffset = 40;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bColorSel = @"#004400";
        NSString *eColorSel = @"#001100";


        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];

        AVAudioSessionPortDescription *currentPort = nil;
        
        NSInteger selectedAudioIndex = [[AudioManager manager] microphoneIndex];
        
        NSInteger index = 0;
        for (AVAudioSessionPortDescription *port in [[AVAudioSession sharedInstance] availableInputs]) {
            button = [self installButtonAtRect:CGRectMake(10,yOffset,180,44) andTag:0];
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:[port portName] attributes:strAttr];
            [button setTitle:title disabledTitle:title beginGradientColorString:(selectedAudioIndex == index) ? bColorSel : bColor endGradientColor:(selectedAudioIndex == index) ? eColorSel : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
            yOffset += 55;
            button.tag = 10000 + index;
            
            if (index == selectedAudioIndex) {
                currentPort = port;
            }
            
            index++;
        }
        
        index = 0;
        yOffset = 40;
        
        for (AVAudioSessionDataSourceDescription *desc in currentPort.dataSources) {
            button = [self installButtonAtRect:CGRectMake(210,yOffset,180,44) andTag:0];
           
            BOOL selected = [[desc dataSourceID] isEqual:[currentPort.selectedDataSource dataSourceID]];
            
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:[desc dataSourceName] attributes:strAttr];
            
            [button setTitle:title disabledTitle:title beginGradientColorString:selected ? bColorSel : bColor endGradientColor:selected ? eColorSel : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
            yOffset += 55;
            button.tag = 10100 + index;
            index++;
        }
    } else if ([whichOne isEqualToString:@"pattern"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 125,64,250,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Polar Pattern" LMR:0 withyOffset:10];
        
         AVAudioSessionPortDescription *port = [[[AVAudioSession sharedInstance] availableInputs] objectAtIndex:[[AudioManager manager] microphoneIndex]];
        AVAudioSessionDataSourceDescription *desc = port.selectedDataSource;
       
        GradientAttributedButton *button = nil;
        CGFloat yOffset = 40;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bColorSel = @"#004400";
        NSString *eColorSel = @"#001100";
        
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
    
        NSInteger index = 0;
        yOffset = 40;
        if (!desc.supportedPolarPatterns) {
            button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width / 2.0f) - 90,yOffset,180,44) andTag:0];
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Default" attributes:strAttr];
            
            [button setTitle:title disabledTitle:title beginGradientColorString:bColorSel  endGradientColor: eColorSel];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
            button.tag = -1;
        } else {
            for (NSString *patternStr in desc.supportedPolarPatterns) {
                button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width / 2.0f) - 90,yOffset,180,44) andTag:0];
                
                BOOL selected = [patternStr isEqualToString:desc.selectedPolarPattern];
                
                NSAttributedString *title = [[NSAttributedString alloc] initWithString:patternStr attributes:strAttr];
                
                [button setTitle:title disabledTitle:title beginGradientColorString:selected ? bColorSel : bColor endGradientColor:selected ? eColorSel : eColor];
                button.enabled = YES;
                [button update];
                [dSub addSubview:button];
                yOffset += 55;
                button.tag = 10200 + index;
                index++;
            }
        }
    } else if ([whichOne isEqualToString:@"sampleRate"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 200,64,400,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Sample Rate" LMR:0 withyOffset:10];
      
        NSArray *rates = @[ @8000.0f,
                            @11025.0f,
                            @16000.0f,
                            @22050.0f,
                            @32000.0f,
                            @44100.0f,
                            @48000.0f
                            ];
        
        GradientAttributedButton *button = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bColorSel = @"#004400";
        NSString *eColorSel = @"#001100";
        
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        NSInteger index = 0;
        CGFloat yOffset = 40;
        CGFloat xOffset = 10;
        
        
        for (NSNumber *rate in rates) {
            button = [self installButtonAtRect:CGRectMake(xOffset,yOffset,120,44) andTag:0];
            
            BOOL selected = [[SettingsTool settings] audioSamplerate] == [[rates objectAtIndex:index] doubleValue];
            
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%0.1f", [rate floatValue]] attributes:strAttr];
            
            [button setTitle:title disabledTitle:title beginGradientColorString:selected ? bColorSel : bColor endGradientColor:selected ? eColorSel : eColor];
            button.enabled = YES;
            [button update];
            [dSub addSubview:button];
            yOffset += 55;
            button.tag = 10300 + index;
            if (index == 2) {
                yOffset = 40;
                xOffset = 140;
            } else if (index == 5) {
                yOffset = 40;
                xOffset = 270;
            }
            index++;
            
        }
    } else if ([whichOne isEqualToString:@"encoding"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 250,64,400,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Audio Encoding Type" LMR:0 withyOffset:10];
        [self installDetailHeaderAtIndex:2 subView:dSub withTitle:@"AAC Quality" LMR:0 withyOffset:0];
        
        GradientAttributedButton *button = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bColorSel = @"#004400";
        NSString *eColorSel = @"#001100";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        CGFloat yOffset = 40;
       
        BOOL audioEncoding = [[SettingsTool settings] audioOutputEncodingIsAAC];
        NSInteger quality = [[SettingsTool settings] audioAACQuality];
        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.70f) - 70 ,yOffset,140,44) andTag:10400];
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"AAC" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:audioEncoding ?  bColorSel : bColor endGradientColor: audioEncoding ? eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.30f) - 70,yOffset,140,44) andTag:10401];
        title = [[NSAttributedString alloc] initWithString:@"PCM" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:!audioEncoding ?  bColorSel : bColor endGradientColor: !audioEncoding ? eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];

        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.50f) - 45,yOffset + 110,90,44) andTag:0];
        title = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)quality] attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColorSel endGradientColor: eColorSel];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.25f) - 45 ,yOffset + 110,90,44) andTag:10402];
        title = [[NSAttributedString alloc] initWithString:@"-" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor: eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.75f) - 45,yOffset + 110,90,44) andTag:10403];
        title = [[NSAttributedString alloc] initWithString:@"+" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor: eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
    } else if ([whichOne isEqualToString:@"mode"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 250,64,400,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Audio Processing Mode" LMR:0 withyOffset:10];
        
        CGFloat yOffset = 80;
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSString *bColorSel = @"#004400";
        NSString *eColorSel = @"#001100";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        NSString *modeStr = session.mode ? session.mode : AVAudioSessionModeDefault;
        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.50f) - 60,yOffset,120,44) andTag:10501];
        title = [[NSAttributedString alloc] initWithString:@"Video" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:[modeStr isEqualToString:AVAudioSessionModeVideoRecording] ? bColorSel : bColor endGradientColor:[modeStr isEqualToString:AVAudioSessionModeVideoRecording] ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.20f) - 60 ,yOffset,120,44) andTag:10500];
        title = [[NSAttributedString alloc] initWithString:@"Default" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:[modeStr isEqualToString:AVAudioSessionModeDefault] ? bColorSel : bColor endGradientColor:[modeStr isEqualToString:AVAudioSessionModeDefault] ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
        
        button = [self installButtonAtRect:CGRectMake((dSub.bounds.size.width * 0.80f) - 60,yOffset,120,44) andTag:10502];
        title = [[NSAttributedString alloc] initWithString:@"Measurement" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:[modeStr isEqualToString:AVAudioSessionModeMeasurement] ? bColorSel : bColor endGradientColor:[modeStr isEqualToString:AVAudioSessionModeMeasurement] ?  eColorSel : eColor];
        button.enabled = YES;
        [button update];
        [dSub addSubview:button];
  
    } else if ([whichOne isEqualToString:@"gain"]) {
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - 125,64,250,100)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Adjust Audio Gain" LMR:0 withyOffset:10];
        
        UISlider *s = [[UISlider alloc] initWithFrame:CGRectMake(10, 40, dSub.bounds.size.width - 20, 44)];
        s.minimumValue = 0.0f;
        s.maximumValue = 1.0f;
        [dSub addSubview:s];
        [s addTarget:self action:@selector(gainSliderEvent:) forControlEvents:UIControlEventValueChanged];
        s.value = [[AVAudioSession sharedInstance] inputGain];
    } else if ([whichOne isEqualToString:@"titlingSetup"]) {
        titlingSetupActive = YES;
        UIView *dSub = [[UIView alloc] initWithFrame:CGRectMake(midX - (282/2),64,282,250)];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [detailView addSubview:dSub];
        
        CGSize buttonSize = CGSizeMake(80,44);
        
        NSArray *yOffsets = @[ [NSNumber numberWithFloat:20],
                               [NSNumber numberWithFloat:72],
                               [NSNumber numberWithFloat:127],
                               [NSNumber numberWithFloat:185]
                               ];
        
        NSArray *xOffsets = @[ [NSNumber numberWithFloat:1.5],
                               [NSNumber numberWithFloat:110],
                               [NSNumber numberWithFloat:200.5],
                               ];
        
    
        
        NSString *optionColorBegin = @"#666666";
        NSString *optionColorEnd = @"#333333";
        
        NSString *valueColorBegin = @"#006600";
        NSString *valueColorEnd = @"#003300";
        
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Begin Clip With Title" LMR:0 withyOffset:0];
        CGFloat w =  [xOffsets[1] floatValue] + 80;
        
        NSString *titleStr = [[SettingsTool settings] engineTitlingBeginName];
        
        GradientAttributedButton *button = [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[0] floatValue], w , buttonSize.height)
                                                        withTitle:(titleStr && ([titleStr length]>0)) ? titleStr : @"None" andTag:1000 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
        button = [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[0] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:@"EDIT"  andTag:1010 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        [self installDetailHeaderAtIndex:1 subView:dSub  withTitle:@"Duration" LMR:0 withyOffset:0];
        button = [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:@"-"  andTag:1001 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        button = [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:[NSString stringWithFormat:@"%ld sec", (long)[[SettingsTool settings] engineTitlingBeginDuration]] andTag:1002 beginColor:valueColorBegin endColor:valueColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        button = [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[1] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:@"+"  andTag:1003 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        [self installDetailHeaderAtIndex:2 subView:dSub withTitle:@"End Clip With Title" LMR:0 withyOffset:0];
        
        titleStr = [[SettingsTool settings] engineTitlingEndName];
        
        
        button = [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[2] floatValue], w , buttonSize.height)
                              withTitle:(titleStr && ([titleStr length]>0)) ? titleStr : @"None" andTag:1004 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        button = [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[2] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:@"EDIT"  andTag:1011 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        [self installDetailHeaderAtIndex:3 subView:dSub withTitle:@"Duration" LMR:0 withyOffset:0];
        button = [self makeButtonAtRect:CGRectMake([xOffsets[0] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:@"-"  andTag:1005 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        button = [self makeButtonAtRect:CGRectMake([xOffsets[1] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:[NSString stringWithFormat:@"%ld sec", (long)[[SettingsTool settings] engineTitlingEndDuration]] andTag:1006 beginColor:valueColorBegin endColor:valueColorEnd largeFont:NO];
        [dSub addSubview:button];
        
        button = [self makeButtonAtRect:CGRectMake([xOffsets[2] floatValue], [yOffsets[3] floatValue], buttonSize.width, buttonSize.height)
                              withTitle:@"+"  andTag:1007 beginColor:optionColorBegin endColor:optionColorEnd largeFont:NO];
        [dSub addSubview:button];
    }

    
    [self.view addSubview:detailView];
    [self.view bringSubviewToFront:detailView];
}

-(void)gainSliderEvent:(id)sender {
    
    UISlider *slider = (UISlider *)sender;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (!session.inputGainSettable) {
        return;
    }
    
    NSError *error = nil;
    [session setInputGain:slider.value error:&error];
    
    [self updateElements];
}

-(void)updateLines {

    if (engineLines) {
        [engineLines removeFromSuperview];
        engineLines = nil;
    }
    

    
    engineLines = [[EngineLines alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height)];
    engineLines.directMode = self.directMode;
    engineLines.backgroundColor = [UIColor clearColor];
    engineLines.positionDict = positionDict;
    engineLines.statusDict = statusDict;
    [self.view addSubview:engineLines];
    [self.view sendSubviewToBack:engineLines];
}

-(void)reloadEngine {
    [self updateElements];

    [self performSelector:@selector(updateElements) withObject:nil afterDelay:1.0];
   
}

-(void)updateElements {
    self.directMode = [[SettingsTool settings] fastCaptureMode];
    
    if ([[SettingsTool settings] isOldDevice]) {
        self.directMode = YES;
    }
    
    CGSize elementSize = CGSizeMake(36,36);
    float topMargin = 75;
    
    if (self.audioControlsOnly) {
        topMargin = - 25;
    }
    
    CGRect cameraLoc = CGRectMake(20,topMargin + 25, elementSize.width, elementSize.height);
    CGRect histogramLoc = CGRectMake(20,topMargin + 75, elementSize.width, elementSize.height);
    
    CGRect diskLoc = CGRectMake(self.view.frame.size.width - 50,topMargin, elementSize.width, elementSize.height);
    CGRect previewLoc = CGRectMake(self.view.frame.size.width - 50,topMargin + 50, elementSize.width, elementSize.height);
    
    
    CGRect audioDiskLoc = CGRectMake(self.view.frame.size.width - 50, topMargin + 140, elementSize.width, elementSize.height);
    CGRect headphoneLoc = CGRectMake(self.view.frame.size.width - 50, topMargin + 190, elementSize.width, elementSize.height);
    
    NSInteger w = (self.view.frame.size.width - 100) / 7.0f;
    CGRect chromaKeyLoc = CGRectMake(20 + (w * 1), topMargin + 25, elementSize.width, elementSize.height);
    CGRect colorControlLoc = CGRectMake(20 + (w * 2), topMargin + 25, elementSize.width, elementSize.height);
    CGRect imageEffectLoc = CGRectMake(20 + (w * 3), topMargin + 25, elementSize.width, elementSize.height);
    CGRect matteLoc = CGRectMake(20 + (w * 4), topMargin + 25, elementSize.width, elementSize.height);
    CGRect titlingLoc = CGRectMake(20 + (w * 5), topMargin + 25, elementSize.width, elementSize.height);
    
    CGRect remoteLoc = CGRectMake(20 + (w * 6), topMargin + 25, elementSize.width, elementSize.height);
    
    CGRect chromaKeySetupLoc = CGRectMake(20 + (w * 1), topMargin + 65, elementSize.width, elementSize.height);
    CGRect overlaySetupLoc = CGRectMake(20 + (w * 4), topMargin + 65, elementSize.width, elementSize.height);
    CGRect titlingSetupLoc = CGRectMake(20 + (w * 5), topMargin + 65, elementSize.width, elementSize.height);
    CGRect remoteSetupLoc = CGRectMake(20 + (w * 6), topMargin + 65, elementSize.width, elementSize.height);
    
    NSInteger aw = (self.view.frame.size.width - 100) / 6.0f;
    CGRect microphoneLoc = CGRectMake(20 + (aw * 0), topMargin + 165, elementSize.width, elementSize.height);
    CGRect micProcessingTypeLoc = CGRectMake(20 + (aw * 1), topMargin + 165, elementSize.width, elementSize.height);
    CGRect micSampleRateLoc = CGRectMake(20 + (aw * 2), topMargin + 165, elementSize.width, elementSize.height);
    CGRect micOutputEncodingLoc = CGRectMake(20 + (aw * 3), topMargin + 165, elementSize.width, elementSize.height);
    CGRect micModeLoc = CGRectMake(20 + (aw * 4), topMargin + 165, elementSize.width, elementSize.height);
    CGRect micGainLoc = CGRectMake(20 + (aw * 5), topMargin + 165, elementSize.width, elementSize.height);
   
    
    for (UIView *v in self.view.subviews) {
        if ([[v class] isSubclassOfClass:[UILabel class]]) {
            [v removeFromSuperview];
        }
    }
    

    overlaySetup.hidden = (![[SettingsTool settings] engineOverlay]) || self.directMode;
    chromaKeySetup.hidden = (![[SettingsTool settings] engineChromaKey]) || self.directMode;
    remoteSetup.hidden = (![[SettingsTool settings] engineRemote]) || self.directMode;
    titlingSetup.hidden = (![[SettingsTool settings] engineTitling]) || self.directMode;
   
    chromaKey.hidden = self.directMode;
    colorControl.hidden = self.directMode;
    imageEffect.hidden = self.directMode;
    overlay.hidden = self.directMode;
    titling.hidden = self.directMode;
    remote.hidden =  self.directMode;
    histogram.hidden = self.directMode;
    if ([[SettingsTool settings] isOldDevice] || [[SettingsTool settings] isiPhone4S]) {
        histogram.hidden = YES;
    }

    [self hideControlsForAudioOnly];
    
    NSString *overlayStr = @"Off";
    
    BOOL engineOverlay = [[SettingsTool settings] engineOverlay];
    if (engineOverlay) {
        NSInteger matteVal = [[[SettingsTool settings] engineOverlayType] integerValue];
        switch (matteVal) {
            case 0:
                overlayStr = @"2.20";
                break;
            case 1:
                overlayStr = @"2.35";
                break;
            case 2:
                overlayStr = @"2.40";
                break;
            case 3:
                overlayStr = @"Time+Location";
                break;
        }
    }
    
    
  
    BOOL headphoneForceDisabled = ![[AudioManager manager] headphonesAvailable];
  
    NSString *cameraDetailStr = @"";
    if ([[SettingsTool settings] fastCaptureMode]) {
        cameraDetailStr = @"Fast\nCapture";
    }
    
    if ([[SettingsTool settings] isOldDevice]) {
        cameraDetailStr = @"";
    }
  
    [self updateElement:camera location:cameraLoc enabled:YES title:[[SettingsTool settings] cameraIsBack] ? @"Back\nCamera" : @"Front\nCamera" above:YES value: cameraDetailStr];
    
    NSString *chromaKeyVal = @"";
    
    if ([[SettingsTool settings] isIPadMini] || [[SettingsTool settings] isiPhone4S]) {
        chromaKeyVal = @"N/A";
        if ([[SettingsTool settings]  fastCaptureMode]) {
            chromaKeyVal = @"";
        }
        if (_audioControlsOnly) {
            chromaKeyVal = @"";
        }
        
    }
    
    [self updateElement:chromaKey location:chromaKeyLoc enabled:[[SettingsTool settings] engineChromaKey] title:@"Chroma\nKey" above:YES value:chromaKeyVal];
    [self updateElement:colorControl location:colorControlLoc enabled:[[SettingsTool settings] engineColorControl] title:@"Color\nAdjust" above:YES value:nil];
    [self updateElement:imageEffect location:imageEffectLoc enabled:[[SettingsTool settings] engineImageEffect] title:@"Image\nEffect" above:YES value:nil];
    [self updateElement:overlay location:matteLoc enabled:engineOverlay title:@"Overlay" above:YES value:nil];
    [self updateElement:titling location:titlingLoc enabled:[[SettingsTool settings] engineTitling] title:@"Titling" above:YES value:nil];
    [self updateElement:remote location:remoteLoc enabled:[[SettingsTool settings] engineRemote] title:@"Director" above:YES value:nil];
    [self updateElement:disk location:diskLoc enabled:YES title:@"Disk" above:YES value:nil];
    [self updateElement:preview location:previewLoc enabled:YES title:@"Preview" above:NO value:nil];
    [self updateElement:histogram location:histogramLoc enabled:[[SettingsTool settings] engineHistogram] title:@"Histogram" above:NO value:nil];
    [self updateElement:overlaySetup location:overlaySetupLoc enabled:YES title:overlayStr above:NO value:nil];
    [self updateElement:titlingSetup location:titlingSetupLoc enabled:YES title:@"" above:NO value:nil];
    
    AVAudioSessionPortDescription *port = [[[AVAudioSession sharedInstance] availableInputs] objectAtIndex:[[AudioManager manager] microphoneIndex]];
    [self updateElement:microphone location:microphoneLoc enabled:[[SettingsTool settings] engineMicrophone] title:@"Audio" above:YES value:[port portName]];
   
    BOOL audioEncoding = [[SettingsTool settings] audioOutputEncodingIsAAC];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSString *audioModeStr = @"Default";
    if ([session.mode isEqualToString:AVAudioSessionModeVideoRecording]) {
        audioModeStr = @"Video\nRecording";
    } else if ([session.mode isEqualToString:AVAudioSessionModeMeasurement]) {
        audioModeStr = @"Measurement";
    }
    
    NSString *inputGainStr = @"N/A";
    if (session.inputGainSettable) {
        inputGainStr = [NSString stringWithFormat:@"%0.2f%%", session.inputGain * 100.0f];
    }
    
    AVAudioSessionDataSourceDescription *desc = port.selectedDataSource;
    NSString *polarPatternStr = desc.selectedPolarPattern ? desc.selectedPolarPattern : @"Default";
    [self updateElement:pattern location:micProcessingTypeLoc enabled:[[SettingsTool settings] engineMicrophone] title:@"Pattern" above:YES value:polarPatternStr];
    
    double audioRate = [[AVAudioSession sharedInstance] sampleRate];
    [self updateElement:sampleRate location:micSampleRateLoc enabled:[[SettingsTool settings] engineMicrophone] title:@"Sample\nRate" above:YES value:[NSString stringWithFormat:@"%0.0f", audioRate]];
    [self updateElement:encoding location:micOutputEncodingLoc enabled:[[SettingsTool settings] engineMicrophone] title:@"Encoding" above:YES value:audioEncoding ? @"AAC" : @"PCM"];
    [self updateElement:mode location:micModeLoc enabled:[[SettingsTool settings] engineMicrophone] title:@"Mode" above:YES value:audioModeStr];
    [self updateElement:gain location:micGainLoc enabled:session.inputGainSettable && [[SettingsTool settings] engineMicrophone] title:@"Gain" above:YES value:inputGainStr];

    [self updateElement:audioDisk location:audioDiskLoc enabled:[[SettingsTool settings] engineMicrophone] title:@"Disk" above:YES value:nil];
    [self updateElement:headphone location:headphoneLoc enabled:[[SettingsTool settings] audioMonitoring] title:@"Headphones" above:NO value:nil];
    
    [self updateElement:chromaKeySetup location:chromaKeySetupLoc enabled:[[SettingsTool settings] engineChromaKey] title:@"" above:NO value:nil];
    [self updateElement:remoteSetup location:remoteSetupLoc enabled:[[SettingsTool settings] engineRemote] title:@"" above:NO value:nil];
    
    
    
    NSMutableDictionary *posDict = [[NSMutableDictionary alloc] initWithCapacity:20];
    [posDict setObject:[NSValue valueWithCGRect:cameraLoc] forKey:@"camera"];
    [posDict setObject:[NSValue valueWithCGRect:chromaKeyLoc] forKey:@"chromakey"];
    [posDict setObject:[NSValue valueWithCGRect:colorControlLoc] forKey:@"colorcontrol"];
    [posDict setObject:[NSValue valueWithCGRect:imageEffectLoc] forKey:@"imageeffect"];
    [posDict setObject:[NSValue valueWithCGRect:matteLoc] forKey:@"overlay"];
    [posDict setObject:[NSValue valueWithCGRect:titlingLoc] forKey:@"titling"];
    [posDict setObject:[NSValue valueWithCGRect:remoteLoc] forKey:@"remote"];
    [posDict setObject:[NSValue valueWithCGRect:diskLoc] forKey:@"disk"];
    [posDict setObject:[NSValue valueWithCGRect:previewLoc] forKey:@"preview"];
    [posDict setObject:[NSValue valueWithCGRect:histogramLoc] forKey:@"histogram"];
    [posDict setObject:[NSValue valueWithCGRect:overlaySetupLoc] forKey:@"matteType"];
    [posDict setObject:[NSValue valueWithCGRect:microphoneLoc] forKey:@"microphone"];
    [posDict setObject:[NSValue valueWithCGRect:audioDiskLoc] forKey:@"audioDisk"];
    [posDict setObject:[NSValue valueWithCGRect:headphoneLoc] forKey:@"headphone"];
    [posDict setObject:[NSValue valueWithCGRect:micModeLoc] forKey:@"mode"];
    [posDict setObject:[NSValue valueWithCGRect:micGainLoc] forKey:@"gain"];
    [posDict setObject:[NSValue valueWithCGRect:overlaySetupLoc] forKey:@"matteType"];
    [posDict setObject:[NSValue valueWithCGRect:titlingSetupLoc] forKey:@"titlingSetup"];
    
    NSMutableDictionary *statDict = [[NSMutableDictionary alloc] initWithCapacity:20];
    [statDict setObject:[NSNumber numberWithBool:YES] forKey:@"camera"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineChromaKey]] forKey:@"chromakey"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineColorControl]] forKey:@"colorcontrol"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineImageEffect]] forKey:@"imageeffect"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineOverlay]] forKey:@"overlay"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineTitling]] forKey:@"titling"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineRemote]] forKey:@"remote"];
    [statDict setObject:[NSNumber numberWithBool:YES] forKey:@"disk"];
    [statDict setObject:[NSNumber numberWithBool:YES] forKey:@"preview"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineHistogram]]forKey:@"histogram"];
    [statDict setObject:[[SettingsTool settings] engineOverlayType] forKey:@"matteType"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineMicrophone]] forKey:@"microphone"];
    [statDict setObject:[NSNumber numberWithBool:YES] forKey:@"mode"];
    [statDict setObject:[NSNumber numberWithBool:YES] forKey:@"gain"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineMicrophone]] forKey:@"audioDisk"];
    [statDict setObject:[NSNumber numberWithBool:([[SettingsTool settings] audioMonitoring] && (!headphoneForceDisabled))] forKey:@"headphone"];
    [statDict setObject:[NSNumber numberWithBool:[[SettingsTool settings] engineTitling]] forKey:@"titlingSetup"];
    [statDict setObject:@(self.audioControlsOnly) forKey:@"audioControlsOnly"];
    positionDict = [posDict copy];
    statusDict = [statDict copy];
   
    [headphoneX removeFromSuperview];
    headphoneX = nil;
  
    if (headphoneForceDisabled) {
        headphoneX = [[RedXView alloc] initWithFrame:headphoneLoc];
        [self.view addSubview:headphoneX];
        [self.view bringSubviewToFront:headphoneX];
    }
    
    [self updateLines];
    
    
    
    
}

-(void)hideControlsForAudioOnly {
    if (self.audioControlsOnly) {
        camera.hidden = YES;
        disk.hidden = YES;
        histogram.hidden = YES;
        preview.hidden = YES;
        chromaKey.hidden = YES;
        colorControl.hidden =YES;
        imageEffect.hidden = YES;
        overlay.hidden = YES;
        titling.hidden = YES;
        remote.hidden = YES;
        overlaySetup.hidden = YES;
        chromaKeySetup.hidden = YES;
        remoteSetup.hidden = YES;
        titlingSetup.hidden = YES;
    }
}

-(void)updateElement:(UIImageView *)i location:(CGRect )location enabled:(BOOL)enabled title:(NSString *)title above:(BOOL)above value:(NSString *)value {
    i.frame = location;
    i.backgroundColor = enabled ? [UIColor whiteColor] : [UIColor darkGrayColor];
    
    if (title && ([title length] >0) && (!i.hidden)) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(location.origin.x -26 , above ? location.origin.y - 30 -1: location.origin.y + location.size.height + 1, location.size.width + 50, 30)];
        
        l.text = title;
        l.numberOfLines = 2;
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            l.font = [[[UtilityBag bag] standardFont] fontWithSize:12];
        } else {
             l.font = [[UtilityBag bag] standardFont];
        }
       
        [self.view addSubview:l];
        [self.view sendSubviewToBack:l];
        
        if ([title isEqualToString:@"Headphones"]) {
            l.frame = CGRectMake(l.frame.origin.x -5, l.frame.origin.y, l.frame.size.width-5, l.frame.size.height-10);
        }
    }
    
    if (value) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(location.origin.x -26, !above ? location.origin.y - 30 : location.origin.y + location.size.height + 1, location.size.width + 55, 30)];
        
        l.text = value;
        l.numberOfLines = 2;
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            l.font = [[[UtilityBag bag] standardFont] fontWithSize:12];
        } else {
            l.font = [[UtilityBag bag] standardFont];
        }
        [self.view addSubview:l];
        [self.view sendSubviewToBack:l];
    }
}

-(void)setupElement:(UIImageView *)i {
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedElement:)];
    [i addGestureRecognizer:tapG];
    i.userInteractionEnabled = YES;
}

-(void)setupElements {
    if (setupComplete) {
        return;
    }
    
    setupComplete = YES;
    
    [self updateLines];
    
    [self setupElement:camera];
    [self setupElement:disk];
    [self setupElement:preview];
    
    [self setupElement:microphone];
    [self setupElement:audioDisk];
    [self setupElement:headphone];
    
    [self setupElement:chromaKey];
    [self setupElement:colorControl];
    [self setupElement:imageEffect];
    [self setupElement:overlay];
    [self setupElement:titling];
    [self setupElement:remote];
    
    [self setupElement:histogram];
    [self setupElement:overlaySetup];
    [self setupElement:mode];
    [self setupElement:gain];
    [self setupElement:titlingSetup];
    
    [self setupElement:pattern];
    [self setupElement:sampleRate];
    [self setupElement:encoding];
    
    [self setupElement:remoteSetup];
    
    [self setupElement:chromaKeySetup];
    [self setupElement:overlaySetup];
    
    [self.view sendSubviewToBack:engineLines];
    
    
}


-(void)userTappedElement:(UITapGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    BOOL changeDoesNotRequireCameraReset = NO;
    if ([g.view isEqual:camera]) {
        if (![[SettingsTool settings] isOldDevice]) {
          [self showDetailViewForOption:@"camera"];
        }
    } else if ([g.view isEqual:chromaKey]) {
        if ([[SettingsTool settings] isIPadMini] || [[SettingsTool settings] isiPhone4S]) {
            return;
        }
        [[SettingsTool settings] setEngineChromaKey:![[SettingsTool settings] engineChromaKey]];
    } else  if ([g.view isEqual:colorControl]) {
        [[SettingsTool settings] setEngineColorControl:![[SettingsTool settings] engineColorControl]];
    } else  if ([g.view isEqual:imageEffect]) {
        [[SettingsTool settings] setEngineImageEffect:![[SettingsTool settings] engineImageEffect]];
    } else  if ([g.view isEqual:overlay]) {
        [[SettingsTool settings] setEngineOverlay:![[SettingsTool settings] engineOverlay]];
    } else  if ([g.view isEqual:titling]) {
        [[SettingsTool settings] setEngineTitling:![[SettingsTool settings] engineTitling]];
    } else  if ([g.view isEqual:remote]) {
        [[SettingsTool settings] setEngineRemote:![[SettingsTool settings] engineRemote]];
    } else  if ([g.view isEqual:histogram]) {
        [[SettingsTool settings] setEngineHistogram:![[SettingsTool settings] engineHistogram]];
    } else if ([g.view isEqual:headphone]) {
        [[SettingsTool settings] setAudioMonitoring:![[SettingsTool settings] audioMonitoring]];
        [[AudioManager manager] updateAudioUnit];
         changeDoesNotRequireCameraReset = YES;
    } else if ([g.view isEqual:audioDisk]) {
        [[SettingsTool settings] setEngineMicrophone:![[SettingsTool settings] engineMicrophone]];
    } else if ([g.view isEqual:microphone]) {
        [self showDetailViewForOption:@"microphone"];
        changeDoesNotRequireCameraReset = YES;
    } else if ([g.view isEqual:chromaKeySetup]) {
        [self showDetailViewForOption:@"chromaKey"];
    } else if ([g.view isEqual:remoteSetup]) {
        [self showDetailViewForOption:@"remote"];
    } else if ([g.view isEqual:overlaySetup]) {
        [self showDetailViewForOption:@"overlay"];
    } else if ([g.view isEqual:pattern]) {
        [self showDetailViewForOption:@"pattern"];
        changeDoesNotRequireCameraReset = YES;
    } else if ([g.view isEqual:sampleRate]) {
        [self showDetailViewForOption:@"sampleRate"];
        if (!([[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode])) {
            changeDoesNotRequireCameraReset = YES;
        }
    } else if ([g.view isEqual:encoding]) {
        [self showDetailViewForOption:@"encoding"];
        if (!([[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode])) {
            changeDoesNotRequireCameraReset = YES;
        }
    } else if ([g.view isEqual:mode]) {
        [self showDetailViewForOption:@"mode"];
        changeDoesNotRequireCameraReset = YES;
    } else if ([g.view isEqual:gain]) {
        [self showDetailViewForOption:@"gain"];
        changeDoesNotRequireCameraReset = YES;
    } else if ([g.view isEqual:titlingSetup]) {
        [self showDetailViewForOption:@"titlingSetup"];
    }
    if (changeDoesNotRequireCameraReset == NO) {
        if (UI_USER_INTERFACE_IDIOM() ==UIUserInterfaceIdiomPad) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];
        }
        changed = YES;
    }
  
    [self updateElements];
}

-(void)userTappedHelpButton:(id)sender {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.title = @"Audio/Video Pipeline";
    
    if (self.audioControlsOnly) {
        self.navigationItem.title = @"Audio Pipeline";
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.preferredContentSize = CGSizeMake(568,320);
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.navigationItem.rightBarButtonItems = nil;
        self.navigationItem.leftBarButtonItems = nil;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelpButton:)];
    }
    

    if (self.audioControlsOnly) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateEngineDetailList) name:@"updateEngineDetailList" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadEngine) name:@"reloadEngine" object:nil];

    [self hideControlsForAudioOnly];

}

-(void)updateEngineDetailList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:0.51];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateElements];
            [detailViewTV reloadData];
        });
    });
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateElements];
    [engineLines setNeedsDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)userTappedClose:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    if (changed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"restartCameraForFeatureChange" object:nil];
    }
    [self performSelector:@selector(dealloc2) withObject:nil afterDelay:0.4];
}

@end
