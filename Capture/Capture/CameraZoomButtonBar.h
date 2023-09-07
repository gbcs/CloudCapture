//
//  CameraZoomButtonBar.h
//  Capture
//
//  Created by Gary Barnett on 7/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraZoomButtonBar : UIView
@property (nonatomic, assign) BOOL supportsZoom;
-(void)updateSize;
-(void)startRecording;
-(void)stopRecording;
@end
