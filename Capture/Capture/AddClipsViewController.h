//
//  AddClipsViewController.h
//  Capture
//
//  Created by Gary Barnett on 9/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddClipsViewControllerDelegate <NSObject>
-(void)userSelectedCliplist:(NSArray *)list;
@end

@interface AddClipsViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate, UIActionSheetDelegate>
@property (nonatomic, weak) NSObject <AddClipsViewControllerDelegate> *delegate;
- (IBAction)userTappedClose:(id)sender;

@end
