//
//  ImportImageViewController.h
//  Capture
//
//  Created by Gary Barnett on 10/16/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImportImageViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, GradientAttributedButtonDelegate>
@property (nonatomic, assign) BOOL popToRootWhenDone;
@property(nonatomic, copy) NSString *notifyStr;
@property (nonatomic, assign) BOOL saveForMovie;
@end
