//
//  PhotoAlbumActivityViewController.h
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PhotoAlbumActivityViewControllerDelegate;

@interface PhotoAlbumActivityViewController : UIViewController

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, weak) id<PhotoAlbumActivityViewControllerDelegate> delegate;

-(void)userDidTapCancelButton:(id)sender;
@end

@protocol PhotoAlbumActivityViewControllerDelegate <NSObject>
- (void)photoAlbumDidFinish:(BOOL)completed;
@end