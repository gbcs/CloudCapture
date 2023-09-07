//
//  CameraTopDetailView.h
//  Capture
//
//  Created by Gary Barnett on 7/6/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailPanelView.h"

#import "UIImage+NegativeImage.h"

@interface CameraTopDetailView : UIView <GradientAttributedButtonDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, FilterToolHistogramDelegate>
@property (nonatomic, assign) NSInteger selected;
@property (nonatomic, assign) NSInteger activeComponent;
@property (nonatomic, strong) NSString *header;
@property (nonatomic, assign) BOOL focusLocked;
@property (nonatomic, assign) BOOL whiteBalanceLocked;
@property (nonatomic, assign) BOOL exposureLocked;
@property (nonatomic, assign) float torchLevel;
@property (nonatomic, assign) BOOL torchActive;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, weak) UIView *iPadDetailSled;
@property (nonatomic, assign) BOOL supportsFrontCamera;


-(void)showControlsForSelected;
-(void)reloadTitleTV;
-(UIView *)histogramView;
@end
