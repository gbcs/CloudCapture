//
//  GridCollectionViewController.h
//  iArchiver
//
//  Created by Gary Barnett on 5/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoThumbImageView.h"
#import "VideoSourceStatusLabel.h"
#import "ButtonWithSourceID.h"
#import "ConnectionButtonWIthID.h"

@interface VideoSourcesCollectionViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate, UITextFieldDelegate>{
    IBOutlet UICollectionView *collectionViewPack;
}

@property(nonatomic,strong) IBOutlet UICollectionView *collectionViewPack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *libraryButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pictureButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)userTappedTrash:(id)sender;
- (IBAction)userTappedLibrary:(id)sender;
- (IBAction)userTappedPictureButton:(id)sender;
- (IBAction)userTappedStop:(id)sender;
- (IBAction)userTappedStart:(id)sender;

@end
