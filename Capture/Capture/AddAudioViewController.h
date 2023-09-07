//
//  AddAudioViewController.h
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddAudioViewControllerDelegate <NSObject>
-(void)userSelectedAudiolist:(NSArray *)list;
@end

@interface AddAudioViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, weak) NSObject <AddAudioViewControllerDelegate> *delegate;
@property (nonatomic, assign) BOOL portraitMode;
@end
