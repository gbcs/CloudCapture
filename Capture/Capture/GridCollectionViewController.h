//
//  GridCollectionViewController.h
//  iArchiver
//
//  Created by Gary Barnett on 5/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GridCollectionViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate, UIActionSheetDelegate, AssetCopyDelegate>
@property (nonatomic, copy) UINavigationController *navController;

-(void)reloadCollection;
-(void)updateAssetManagerAndReload;
- (IBAction)userTappedImport:(id)sender;
- (IBAction)userTappedClose:(id)sender;

- (IBAction)userTappedAction:(id)sender;
- (IBAction)userTappedPlay:(id)sender;
- (IBAction)userTappedTrim:(id)sender;
- (IBAction)userTappedTrash:(id)sender;
- (IBAction)userTappedAdd:(id)sender;

-(NSArray *)metadataForAsset:(AVAsset *)asset;

-(void)setAlreadyPromptedForClipMove;



@end
