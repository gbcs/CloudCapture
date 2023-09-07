//
//  AddAudioViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AddAudioViewController.h"
#import "AudioLibraryViewController.h"
#import "AppDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>


@interface AddAudioViewController () {
    
    NSMutableArray *selectedEntries;
    
    NSInteger lastTapRow;
    IBOutlet UICollectionView *collectionViewPack;
    
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *addButton;
    
}


@end

@implementation AddAudioViewController

static NSString * const kCellReuseIdentifier = @"audioLibraryCollectionViewCell";

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
        //NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    selectedEntries = nil;
    collectionViewPack = nil;
    
    addButton = nil;
    cancelButton = nil;
  
}


-(void)reloadCollection {
    if (collectionViewPack) {
        [collectionViewPack reloadData];
    }
}

-(void)updateAssetManagerAndReload {
    [[AudioBrowser manager] update];
    [self performSelector:@selector(waitOnLibraryForAudioLibrary) withObject:nil afterDelay:0.55];
}

- (void)viewDidLoad
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLibraryCloseButtonForOrientation:) name:@"updateLibraryCloseButtonForOrientation" object:nil];
    
    selectedEntries = [[NSMutableArray alloc] initWithCapacity:5];
    
    [collectionViewPack registerNib:[UINib nibWithNibName: @"AudioLibraryCollectionViewItem" bundle:nil] forCellWithReuseIdentifier:kCellReuseIdentifier];
    collectionViewPack.backgroundColor = [UIColor blackColor];
    
    [collectionViewPack registerNib:[UINib nibWithNibName:@"AudioLibraryHeaderViewItem" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"audioLibraryHeader"];
    
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    [flowLayout setItemSize:CGSizeMake(100, 75)];
    self.automaticallyAdjustsScrollViewInsets = YES;
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [collectionViewPack setCollectionViewLayout:flowLayout];
    [collectionViewPack setAllowsSelection:YES];
    
    lastTapRow = -1;
    
    collectionViewPack.allowsMultipleSelection = YES;
    
    addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedAddButton:)];
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancelButton:)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = addButton;
    
    self.navigationItem.title = @"Add Audio";
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];
    
}

-(void)waitOnLibraryForAudioLibrary {
    if ([[AudioBrowser manager] isReady]) {
        collectionViewPack.delegate=self;
        [selectedEntries removeAllObjects];
        lastTapRow = -1;
        [self reloadCollection];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    } else {
        [self performSelector:@selector(waitOnLibraryForAudioLibrary) withObject:nil afterDelay:0.25];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;

    addButton.enabled = NO;

    [self updateAssetManagerAndReload];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numFound = 0;
    numFound = [[AudioBrowser manager] songCountForArtistAtIndex:section];
    return numFound;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[[AudioBrowser manager] artists] count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    CGSize s = CGSizeMake(self.view.frame.size.width,40);
    
    return s;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"audioLibraryHeader" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.text = [[[AudioBrowser manager] artists] objectAtIndex:indexPath.section];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:101];
    imageView.image = [[AudioBrowser manager] artworkForArtistAtIndex:indexPath.section withSize:imageView.bounds.size];
    
    
    if ( (imageView.image) && (indexPath.section > 0) ) {
        imageView.frame = CGRectMake(5,4,32,32);
        titleLabel.frame = CGRectMake(40, 0, self.view.frame.size.width - 45, 40);
    } else {
        imageView.frame = CGRectZero;
        titleLabel.frame = CGRectMake(5, 0, self.view.frame.size.width - 10, 40);
    }
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *durationLabel = (UILabel *)[cell viewWithTag:101];
    
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    durationLabel.textColor = [UIColor whiteColor];
    durationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSTimeInterval seconds = -1;
    if (indexPath.section == 0) {
        titleLabel.text = [[AudioBrowser manager] entryforAppLibraryAtIndex:indexPath.item];
        seconds = [[AudioBrowser manager] durationforAppLibraryAtIndex:indexPath.item];
    } else {
        MPMediaItem *item = [[AudioBrowser manager] entryForArtistAtIndex:indexPath.section atEntryIndex:indexPath.item];
        titleLabel.text = [item valueForProperty:MPMediaItemPropertyTitle];
        
        NSNumber *duration = [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
        seconds = [duration doubleValue];
    }
    
    durationLabel.text = [self durationStr:seconds];
    
    cell.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    UIView *bgView = [[UIView alloc] initWithFrame:cell.bounds];
    bgView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    cell.selectedBackgroundView  = bgView;
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:cell.bounds];
    cell.layer.masksToBounds = NO;
    cell.layer.shadowColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
    cell.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    cell.layer.shadowOpacity = 0.3f;
    cell.layer.shadowRadius = 2.0f;
    cell.layer.shadowPath = shadowPath.CGPath;
    
    return cell;
}

-(NSString *)durationStr:(NSInteger )seconds {
    NSString *str = @"--:--:--";
    if (seconds >= 0) {
        NSInteger hours = seconds / (60 * 60);
        NSInteger mins = (seconds - (hours * 60*60)) / 60;
        NSInteger secs = seconds - (hours * 60 * 60) - (mins * 60);
        str = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)mins, (long)secs];
    }
    return str;
}

#pragma mark - delegate methods

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    lastTapRow = -1;
    
    if ([selectedEntries indexOfObject:indexPath] != NSNotFound) {
        [selectedEntries removeObject:indexPath];
    }
    
    if ([selectedEntries count]<1) {
        addButton.enabled = NO;
    }
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger curRow = indexPath.row;
    
    lastTapRow = curRow;
    
    if ([selectedEntries indexOfObject:indexPath] == NSNotFound) {
        [selectedEntries addObject:indexPath];
    }
    
    addButton.enabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}


- (IBAction)userTappedAddButton:(id)sender {
    if ([selectedEntries count] > 0) {
        NSMutableArray *clipList = [[NSMutableArray alloc] initWithCapacity:[selectedEntries count]];
        for (NSIndexPath *ip in selectedEntries) {
            if (ip.section == 0) {
                NSString *filename = [[AudioBrowser manager] entryforAppLibraryAtIndex:ip.item];
                NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:filename]];
                NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
                AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
                [clipList addObject:songAsset];
            } else {
                MPMediaItem *item = [[AudioBrowser manager] entryForArtistAtIndex:ip.section atEntryIndex:ip.item];
                NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
                if (assetURL) {
                    NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
                    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
                    [clipList addObject:songAsset];
                }
            }
        }
        [_delegate userSelectedAudiolist:[clipList copy]];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)userTappedCancelButton:(id)sender {
   [self.navigationController popViewControllerAnimated:YES];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}


- (NSUInteger)supportedInterfaceOrientations  {
    NSInteger supported = UIInterfaceOrientationMaskAll;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        supported  = UIInterfaceOrientationMaskLandscape;
    }
    return supported;
}



- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
}

@end