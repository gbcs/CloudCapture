//
//  ThumbnailView.h
//  Capture
//
//  Created by Gary Barnett on 9/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThumbnailView : UIView

-(CGImageRef )currentImage;
-(void)setImage:(CGImageRef )image;

@end
