//
//  PhotoEditViewController.h
//  Capture
//
//  Created by Gary  Barnett on 3/26/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoEditView.h"

@interface PhotoEditViewController : UIViewController <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scroller;
@property (nonatomic, strong) PhotoEditView *editView;
@property (nonatomic, strong) ALAsset *asset;

@end
