//
//  AddVideoPhotoView.h
//  Capture
//
//  Created by Gary  Barnett on 2/25/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPUserResizableView.h"
#import "MakeVideoFromImage.h"
#import "GPUMakeVideoFromImage.h"

@interface AddVideoPhotoView : UIView <GradientAttributedButtonDelegate, SPUserResizableViewDelegate, MakeVideoFromImageDelegate, GPUMakeVideoFromImageDelegate>
-(void)startup:(NSString *)fName;
@end
