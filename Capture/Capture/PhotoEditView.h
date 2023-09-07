//
//  PhotoEditView.h
//  Capture
//
//  Created by Gary  Barnett on 3/26/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoEditView : UIView
@property (nonatomic, assign) CGImageRef image;

-(void)useImage:(CGImageRef )updatedImage;

@end
