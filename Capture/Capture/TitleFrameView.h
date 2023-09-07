//
//  TitleFrameView.h
//  Capture
//
//  Created by Gary Barnett on 10/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TitleFrameView : UIView
@property (nonatomic, strong) UIImage *bgImage;
@property (nonatomic, strong) NSDictionary *titleDict;
@property (nonatomic, assign) BOOL flip;
@property (nonatomic, assign) BOOL horizFlip;
-(void)updateWithSize:(CGSize)s;

@end
