//
//  AddPhotoViewController.h
//  Capture
//
//  Created by Gary Barnett on 2/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddPhotoViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, GradientAttributedButtonDelegate>
@property (nonatomic, assign) BOOL popToRootWhenDone;
@property(nonatomic, copy) NSString *notifyStr;
@property (nonatomic, assign) BOOL saveForMovie;

@end
