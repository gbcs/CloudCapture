//
//  CameraTopBarView.h
//  Capture
//
//  Created by Gary Barnett on 7/5/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraTopBarView : UIView

@property (nonatomic, assign) NSInteger selected;

@property (nonatomic, assign) float batteryPercentage;
@property (nonatomic, assign) float diskPercentage;
@property (nonatomic, assign) float audioLPercentage;
@property (nonatomic, assign) float audioRPercentage;

@property (nonatomic, assign) NSInteger camera;
@property (nonatomic, assign) NSInteger resolution;
@property (nonatomic, assign) NSInteger frameRate;
@property (nonatomic, assign) BOOL recording;

@property (nonatomic, assign) NSInteger imageStabilizationMode;
@property (nonatomic, assign) NSInteger focusMode;
@property (nonatomic, assign) NSInteger whiteBalanceMode;
@property (nonatomic, assign) NSInteger exposureMode;
@property (nonatomic, assign) NSInteger brightnessMode;
@property (nonatomic, assign) NSInteger contrastMode;
@property (nonatomic, assign) NSInteger saturationMode;
@property (nonatomic, assign) NSInteger pictureMode;
@property (nonatomic, assign) NSInteger torchMode;
@property (nonatomic, assign) NSInteger zoomMode;
@property (nonatomic, assign) NSInteger x1Mode;
@property (nonatomic, assign) NSInteger x2Mode;
@property (nonatomic, assign) NSInteger x3Mode;
@property (nonatomic, assign) float zoomScale;

@property (nonatomic, assign) NSString *recordingTime;
@property (nonatomic, assign) NSString *statusField;
@property (nonatomic, assign) BOOL displayAdvancedControls;

-(void)update;
@end
