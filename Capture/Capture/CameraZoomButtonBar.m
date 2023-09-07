//
//  CameraZoomButtonBar.m
//  Capture
//
//  Created by Gary Barnett on 7/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CameraZoomButtonBar.h"
#import "LabeledButton.h"

@implementation CameraZoomButtonBar {

    UIFont *normalFont;
    UIFont *boldFont;
    
    LabeledButton *exitButton;
    LabeledButton *zoomOut;
    LabeledButton *zoomSpeedLess;
    LabeledButton *recordButton;
    LabeledButton *stillButton;
    LabeledButton *zoomSpeedMore;
    LabeledButton *zoomIn;
    
    CGSize labelButtonSize;
}

-(void)updateSize {
    
    zoomOut.hidden = !self.supportsZoom;
    zoomIn.hidden = !self.supportsZoom;
    zoomSpeedMore.hidden = !self.supportsZoom;
    zoomSpeedLess.hidden = !self.supportsZoom;
    
    if (self.supportsZoom ) {
        float seperation = (self.frame.size.width - (labelButtonSize.width * 7.0f) ) / 7.0f;
        exitButton.frame = CGRectMake(seperation / 2.0f,0,labelButtonSize.width, labelButtonSize.height);
        zoomOut.frame = CGRectMake((seperation / 2.0f) + (1.0f * seperation)+ (1.0f * labelButtonSize.width) ,0,labelButtonSize.width, labelButtonSize.height);
        zoomIn.frame = CGRectMake((seperation / 2.0f) + (2.0f * seperation)+ (2.0f * labelButtonSize.width) ,0,labelButtonSize.width, labelButtonSize.height);
        zoomSpeedLess.frame = CGRectMake((seperation / 2.0f) + (3.0f * seperation) + (3.0f * labelButtonSize.width) ,0,labelButtonSize.width, labelButtonSize.height);
        zoomSpeedMore.frame = CGRectMake((seperation / 2.0f) + (4.0f * seperation)+ (4.0f * labelButtonSize.width) ,0,labelButtonSize.width, labelButtonSize.height);
        recordButton.frame = CGRectMake((seperation / 2.0f) + (5.0f * seperation)+ (5.0f * labelButtonSize.width) ,0,labelButtonSize.width, labelButtonSize.height);
        stillButton.frame = CGRectMake((seperation / 2.0f) + (6.0f * seperation)+ (6.0f * labelButtonSize.width) ,0,labelButtonSize.width, labelButtonSize.height);
    } else {
        exitButton.frame = CGRectMake(10,0,labelButtonSize.width, labelButtonSize.height);
        stillButton.frame = CGRectMake(self.frame.size.width - 20 - labelButtonSize.width - 20 - labelButtonSize.width ,0 ,labelButtonSize.width, labelButtonSize.height);
        recordButton.frame = CGRectMake(self.frame.size.width - 20 - labelButtonSize.width , 0, labelButtonSize.width, labelButtonSize.height);
    }
    
    stillButton.enabled = ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized);
    
    
}
-(void)dealloc {
    //NSLog(@"%s", __func__);
    //NSLog(@"%s", __func__);
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    normalFont = nil;
    boldFont = nil;
    
    zoomOut = nil;
    zoomSpeedLess = nil;
    recordButton = nil;
    stillButton = nil;
    zoomSpeedMore = nil;
    zoomIn = nil;
    exitButton = nil;
}


-(void)startRecording {
    recordButton.caption = @"Stop";
    [recordButton setNeedsDisplay];
}

-(void)stopRecording {
    recordButton.caption = @"Record";
    [recordButton setNeedsDisplay];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            normalFont = [UIFont fontWithName:@"LiquidCrystal-Regular" size:14];
            boldFont = [UIFont fontWithName:@"LiquidCrystal-Bold" size:14];
        } else {
            normalFont = [UIFont fontWithName:@"LiquidCrystal-Regular" size:14];
            boldFont = [UIFont fontWithName:@"LiquidCrystal-Bold" size:14];

        }
        
        labelButtonSize = CGSizeMake(60,44);
        exitButton = [[LabeledButton alloc] initWithFrame:CGRectMake(10,0,labelButtonSize.width, labelButtonSize.height)];
        
        zoomOut = [[LabeledButton alloc] initWithFrame:CGRectMake(10,0,labelButtonSize.width, labelButtonSize.height)];
        zoomSpeedLess = [[LabeledButton alloc] initWithFrame:CGRectMake(80,0,labelButtonSize.width, labelButtonSize.height)];
        recordButton = [[LabeledButton alloc] initWithFrame:CGRectMake(150,0,labelButtonSize.width, labelButtonSize.height)];
        stillButton = [[LabeledButton alloc] initWithFrame:CGRectMake(220,0,labelButtonSize.width, labelButtonSize.height)];
        zoomSpeedMore = [[LabeledButton alloc] initWithFrame:CGRectMake(290,0,labelButtonSize.width, labelButtonSize.height)];
        zoomIn = [[LabeledButton alloc] initWithFrame:CGRectMake(370,0,labelButtonSize.width, labelButtonSize.height)];
        
        zoomOut.notifyStringDown = @"zoomBarZoomOutDown";
        zoomOut.notifyStringUp = @"zoomBarZoomOutUp";
 
        zoomSpeedLess.notifyStringDown = @"zoomBarZoomSpeedLessDown";
        zoomSpeedLess.notifyStringUp = @"zoomBarZoomSpeedLessUp";
 
        recordButton.notifyStringUp = nil;
        recordButton.notifyStringDown = @"bottomBarButtonTappedrecordButtonDown";
       
        
        stillButton.notifyStringDown = @"handleStillImageRequest";
    
        stillButton.notifyStringUp = nil;
        
        zoomSpeedMore.notifyStringDown = @"zoomBarZoomSpeedMoreDown";
        zoomSpeedMore.notifyStringUp = @"zoomBarZoomSpeedMoreUp";
      
        zoomIn.notifyStringDown = @"zoomBarZoomInDown";
        zoomIn.notifyStringUp = @"zoomBarZoomInUp";
        
        
        exitButton.notifyStringUp = nil;
        exitButton.notifyStringDown = @"cameraExitButtonDown";
        
        
        zoomOut.caption = @"< ZOOM";
        zoomSpeedLess.caption = @"< SPEED";
        recordButton.caption = @"RECORD";
        stillButton.caption = @"PICTURE";
        zoomSpeedMore.caption = @"SPEED >";
        zoomIn.caption = @"ZOOM >";
        exitButton.caption = @"Exit";
        
        
        [self addSubview:zoomOut];
        [self addSubview:zoomSpeedLess];
        [self addSubview:recordButton];
        [self addSubview:stillButton];
        [self addSubview:zoomSpeedMore];
        [self addSubview:zoomIn];
        [self addSubview:exitButton];
    }
    return self;
}

@end
