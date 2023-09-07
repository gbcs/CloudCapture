//
//  AppLibraryActivityViewController.h
//  Capture
//
//  Created by Gary Barnett on 11/27/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol AppLibraryActivityViewControllerDelegate;

@interface AppLibraryActivityViewController : UIViewController

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, weak) id<AppLibraryActivityViewControllerDelegate> delegate;

-(IBAction)userDidTapCancelButton:(id)sender;
@end

@protocol AppLibraryActivityViewControllerDelegate <NSObject>
- (void)appLibraryDidFinish:(BOOL)completed;
@end