//
//  GridCollectionViewController.m
//  iArchiver
//
//  Created by Gary Barnett on 5/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "GridCollectionViewController.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "CutClipViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HelpViewController.h"
#import "PhotoLibraryViewController.h"
#import "PhotoAlbumActivity.h"
#import "YoutubeActivity.h"
#import "AppLibraryActivity.h"
#import "GSDropboxActivity.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AudioLibraryViewController.h"
#import "DailyMotionActivity.h"
#import "S3UploaderActivity.h"
//#import "RESTActivity.h"
#import "AzureActivity.h"
#import "LinkShareViewController.h"
#import "AddVideoViewController.h"
#import "AddPhotoListViewController.h"

@interface GridCollectionViewController () {
    NSArray *videoList;
    NSArray *assetLibraryGroupList;
    
    NSMutableArray *selectedEntries;

    __weak IBOutlet UIToolbar *toolBar;
    
    NSInteger lastTapRow;
    IBOutlet UICollectionView *collectionViewPack;
 
    __weak IBOutlet UIBarButtonItem *actionButton;
    __weak IBOutlet UIBarButtonItem *playButton;
    __weak IBOutlet UIBarButtonItem *trimButton;
    __weak IBOutlet UIBarButtonItem *trashButton;
    
    BOOL deleteMode;
 
     UIView *progressContainer;
    UIBarButtonItem *importButton;
    
    BOOL pictureMode;
    BOOL firstMove;
    
    NSURL *urlForUploadedMovie;
    NSDictionary *dictForUploadedMovie;
    UIView *detailView;
    UIDynamicAnimator *animator;
    ALAssetRepresentation *detailAsset;

}


@end

@implementation GridCollectionViewController

static NSString * const kCellReuseIdentifier = @"collectionViewCell";

-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
        //NSLog(@"%@:%s", [self class], __func__);
    [[AssetManager manager] cleanup];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    videoList = nil;
    assetLibraryGroupList = nil;
    
    selectedEntries = nil;
    
    toolBar = nil;

    collectionViewPack = nil;
    
    actionButton = nil;
    playButton = nil;
    trimButton = nil;
    trashButton = nil;

    progressContainer = nil;
    importButton = nil;
 
}

-(void)reloadCollection {
    assetLibraryGroupList = [[AssetManager manager] groups];
    videoList = [[AssetManager manager] videoList];
   
    if (collectionViewPack) {
        [selectedEntries removeAllObjects];
        lastTapRow = -1;
        [collectionViewPack reloadData];
        [self updateToolbar];
    }
}

-(void)updateAssetManagerAndReload {
    [[AssetManager manager] update];
    [self performSelector:@selector(waitOnLibraryForAssetLibrary) withObject:nil afterDelay:0.55];
}

-(void)popAndShowPhotoLibrary:(NSNotification *)n {
    [self.navigationController popToViewController:self animated:NO];
    self.navigationController.toolbarHidden = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanup" object:nil];
    PhotoLibraryViewController *vc = [[PhotoLibraryViewController alloc] initWithNibName:@"PhotoLibraryViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:NO];
}

-(void)popAndShowAudioLibrary:(NSNotification *)n {
    [self.navigationController popToViewController:self animated:NO];
    self.navigationController.toolbarHidden = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanup" object:nil];
    AudioLibraryViewController *vc = [[AudioLibraryViewController alloc] initWithNibName:@"AudioLibraryViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:NO];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[MovieManager manager] closePlayer];
    }
}

-(void)returnedFromSuspend:(NSNotification *)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            collectionViewPack.alpha = 0.02f;
        });
        [NSThread sleepForTimeInterval:2.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateAssetManagerAndReload];
        });
    });
}

-(void)updateUploadedURLAndDict:(NSNotification *)n {
    NSArray *a = (NSArray *)n.object;
    
    if (a) {
        urlForUploadedMovie = [a objectAtIndex:0];
        dictForUploadedMovie = [a objectAtIndex:1];
    } else {
        urlForUploadedMovie = nil;
        dictForUploadedMovie = nil;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:2.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self checkforUploadedMovie]; //also shows ad if appropriate instead
            });
        });
    }
}

- (void)viewDidLoad
{
    self.automaticallyAdjustsScrollViewInsets = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAddressNotification:) name:@"locationFound" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popAndShowPhotoLibrary:) name:@"popAndShowPhotoLibrary" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popAndShowAudioLibrary:) name:@"popAndShowAudioLibrary" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnedFromSuspend:) name:@"returnedFromSuspend" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUploadedURLAndDict:) name:@"updateUploadedURLAndDict" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLibraryCloseButtonForOrientation:) name:@"updateLibraryCloseButtonForOrientation" object:nil];
    
    selectedEntries = [[NSMutableArray alloc] initWithCapacity:5];
    
    BOOL isiPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    [collectionViewPack registerNib:[UINib nibWithNibName: isiPad ? @"CollectionViewItemiPad" : @"CollectionViewItem" bundle:nil] forCellWithReuseIdentifier:kCellReuseIdentifier];
    collectionViewPack.backgroundColor = [UIColor blackColor];
    
    [collectionViewPack registerNib:[UINib nibWithNibName:@"GridCollectionHeaderViewItem" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
         [flowLayout setItemSize:CGSizeMake(160, 160)];
    } else {
         [flowLayout setItemSize:CGSizeMake(100, 100)];
    }
    
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [collectionViewPack setCollectionViewLayout:flowLayout];
    [collectionViewPack setAllowsSelection:YES];
    
    lastTapRow = -1;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishShowing:) name:@"finishPlaying" object:nil];
    
    collectionViewPack.allowsMultipleSelection = YES;
   
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelpButton:)];
    

    
    progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0,0,140,30)];
    progressContainer.backgroundColor = [UIColor clearColor];
    
  
    
    self.navigationItem.title = @"Library";

    
    UISegmentedControl *seg =[[UISegmentedControl alloc] initWithItems:@[ @"Video" , @"Pictures", @"Audio"] ];
    [seg addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventValueChanged];
    seg.selectedSegmentIndex = 0;
    self.navigationItem.titleView = seg;
    
    
}
-(void)waitOnLibraryForAssetLibrary {
    if ([[AssetManager manager] isReady]) {
        collectionViewPack.delegate=self;
        lastTapRow = -1;
        [selectedEntries removeAllObjects];
        [self reloadCollection];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        if ( (![[SettingsTool settings] clipStorageLibrary]) && (![[SettingsTool settings] clipMoveImmediately]) && (!firstMove)) {
            firstMove = YES;
            [self performSelector:@selector(autoMoveClipsToPhotoAlbum) withObject:nil afterDelay:0.25];
        }
        collectionViewPack.alpha = 1.0f;
    } else {
        [self performSelector:@selector(waitOnLibraryForAssetLibrary) withObject:nil afterDelay:0.25];
    }
}

-(void)waitOnLibraryForPhotoLibrary:(UISegmentedControl *)seg {
    if ([[PhotoManager manager] isReady]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [self showPhotoLibrary:seg];
    } else {
        [self performSelector:@selector(waitOnLibraryForPhotoLibrary:) withObject:seg afterDelay:0.25];
    }
}

-(void)showPhotoLibrary:(UISegmentedControl *)seg {
    self.navigationController.toolbarHidden = NO;
    PhotoLibraryViewController *vc = [[PhotoLibraryViewController alloc] initWithNibName:@"PhotoLibraryViewController" bundle:nil];
    NSMutableArray *vcList = [self.navigationController.viewControllers mutableCopy];
    [vcList removeLastObject];
    [vcList addObject:vc];
    [self.navigationController setViewControllers:[vcList copy] animated:NO];
    [seg setSelectedSegmentIndex:0];

}

-(void)changeMode:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl *)sender;
   
    pictureMode = (seg.selectedSegmentIndex == 1);
   
    if (seg.selectedSegmentIndex == 0) {
       
    } else if (seg.selectedSegmentIndex == 1) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [[PhotoManager manager] update];
        [self performSelector:@selector(waitOnLibraryForPhotoLibrary:) withObject:seg afterDelay:0.25];
    } else if (seg.selectedSegmentIndex == 2) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [[AudioBrowser manager] update];
        [self performSelector:@selector(waitOnLibraryForAudioBrowser:) withObject:seg afterDelay:0.25];
    }
}

-(void)waitOnLibraryForAudioBrowser:(UISegmentedControl *)seg {
    if ([[AudioBrowser manager] isReady]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [self showAudioBrowser:seg];
    } else {
        [self performSelector:@selector(waitOnLibraryForAudioBrowser:) withObject:seg afterDelay:0.25];
    }
}

-(void)showAudioBrowser:(UISegmentedControl *)seg {
    self.navigationController.toolbarHidden = NO;
    AudioLibraryViewController *vc = [[AudioLibraryViewController alloc] initWithNibName:@"AudioLibraryViewController" bundle:nil];
    NSMutableArray *vcList = [self.navigationController.viewControllers mutableCopy];
    [vcList removeLastObject];
    [vcList addObject:vc];
    [self.navigationController setViewControllers:[vcList copy] animated:NO];
    [seg setSelectedSegmentIndex:0];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    
}

-(void)userTappedHelpButton:(id)sender {
      
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
   
        //  [collectionViewPack removeFromSuperview];
 
}

-(void)checkforUploadedMovie {
    if (urlForUploadedMovie) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:1.5f];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                LinkShareViewController *vc = [[LinkShareViewController alloc] initWithNibName:@"LinkShareViewController" bundle:nil];
                vc.url = urlForUploadedMovie;
                vc.dict = dictForUploadedMovie;
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                
                [self.navigationController presentViewController:nav animated:YES completion:nil];
                
                urlForUploadedMovie = nil;
                dictForUploadedMovie = nil;
            });
        });
    } else {
       [self performSelector:@selector(checkAd) withObject:Nil afterDelay:1.0f];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateAssetManagerAndReload];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanup" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanupPhotoLibraryViewController" object:nil];
    
    [self checkforUploadedMovie];
}

-(void)checkAd {
    if ([[SettingsTool settings] hasDoneSomethingAdWorthy]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showAdOnController" object:self];
    }
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
   
    [[SyncManager manager] progressContainer].frame = CGRectMake(0,2,140,30);
    
    [progressContainer addSubview:[[SyncManager manager] progressContainer]];
    
    [self updateToolbar];
    
   
    UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.titleView;
    [seg setEnabled:([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) forSegmentAtIndex:1];
    
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = YES;
    
    self.navigationController.toolbarHidden = YES;
    collectionViewPack.alpha = 0.02f;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numFound = 0;
    
    if (![[AssetManager manager] isReady]) {
        return 0;
    }
    
    if (section == 0) {
        if (videoList) {
            numFound = [videoList count];
        }
    } else if (section <= [assetLibraryGroupList count]) {
        numFound = [[AssetManager manager] groupEntryCount:section];
    }
    
    return numFound;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1 + [assetLibraryGroupList count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {

    CGSize s = CGSizeMake(self.view.frame.size.width,20);
   
    return s;
}

-(NSArray *)metadataForItemWithName:(NSString *)fname {
    NSString *path = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:fname];
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:url options:asset_options];

    return [self metadataForAsset:asset];
}

-(NSArray *)metadataForAsset:(AVAsset *)asset {

    NSString *c = @"";
    NSString *l = @"";
    
    NSInteger duration = asset.duration.value / asset.duration.timescale;
    
    NSInteger hours = duration / (60 * 60);
    
    NSInteger remain = duration - (hours * 60 * 60);
    
    NSInteger minutes = remain / 60;
    
    NSInteger seconds = remain - (minutes * 60);
    
    NSString *d = @"";
    
    if (hours == 1) {
        d = @"1 hour";
    } else if (hours > 1) {
        d = [NSString stringWithFormat:@"%ld hours", (long)hours];
    }
    
    if ( (minutes > 0) && ([d length] >0)) {
        d = [d stringByAppendingString:@", "];
    }
    
    BOOL addSpace = NO;
    
    if (minutes == 1) {
        addSpace = YES;
        d = [d stringByAppendingString:@"1 minute"];
    } else if (minutes > 1) {
        addSpace = YES;
        d = [NSString stringWithFormat:@"%@%ld minutes", d, (long)minutes];
    }
    
    if (addSpace) {
        d = [d stringByAppendingString:@", "];
    }
    
    if (seconds == 1) {
        d = [d stringByAppendingString:@"1 second"];
    } else if (seconds > 1) {
        d = [NSString stringWithFormat:@"%@%ld seconds", d, (long)seconds];
    }
    
    for (NSString *format in [asset availableMetadataFormats]) {
            for (AVMutableMetadataItem *item in [asset metadataForFormat:format]) {
                if ([item.commonKey isEqualToString:@"creationDate"]) {
                    c = (NSString *) item.value;
                } else if ([item.commonKey isEqualToString:@"location"]) {
                    l = (NSString *) item.value;
                }
        }
    }
    
    if ([c length]>0) {
        c =  [[LocationHandler tool] timeAgoFromDateStr:c];
    }

    return @[ c, l, d ];
}

-(void)updateAddressNotification:(NSNotification *)n {
    NSArray *notifyArray = (NSArray *)n.object;
    
    UICollectionViewCell *cell = [notifyArray objectAtIndex:0];
    NSArray *metadata  = [notifyArray objectAtIndex:1];
    NSString *address = [notifyArray objectAtIndex:2];
    
    if ([metadata count] == 3) {
        NSString *timeStr =[metadata objectAtIndex:0];
        NSString *durationStr = [metadata objectAtIndex:2];
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        NSString *newLabelText = [NSString stringWithFormat:@"%@\n%@\n%@", timeStr ? timeStr : @"", address ? address : @"", durationStr ? durationStr : @""];
        titleLabel.text = newLabelText;
        [titleLabel setNeedsDisplay];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
   
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    if (indexPath.section == 0) {
        if ([videoList count] <1) {
             titleLabel.text = @"App Library (empty)";
        } else {
             titleLabel.text = @"App Library";
        }
        if (![progressContainer.superview isEqual:cell]) {
            progressContainer.frame = CGRectMake(cell.bounds.size.width - (progressContainer.bounds.size.width + 10), 0, progressContainer.bounds.size.width, progressContainer.bounds.size.height);
            [cell addSubview:progressContainer];
        }
    } else {
        titleLabel.text = [assetLibraryGroupList objectAtIndex:indexPath.section -1];
    }
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:101];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    NSArray *metadata = nil;
    
    BOOL badClip = NO;
    
    BOOL playable = NO;
    
    AVAsset *avAsset = nil;
    UIImage *thumbnail = nil;
    
    if (indexPath.section > 0) {
        ALAsset *alasset = [[AssetManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
        
        if (!alasset) {
            titleLabel.text = @"bad clip";
            badClip = YES;
        } else {
            ALAssetRepresentation *representation = [alasset defaultRepresentation];
            NSURL *url = [representation url];
            
            NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            avAsset = [[AVURLAsset alloc] initWithURL:url options:asset_options];
            metadata = [self metadataForAsset:avAsset];
            thumbnail = [UIImage imageWithCGImage:[alasset aspectRatioThumbnail] scale:1.0 orientation:UIImageOrientationUp];
        }
    } else {
        NSString *fPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[videoList objectAtIndex:indexPath.row] objectAtIndex:0]];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:fPath];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        avAsset = [AVURLAsset URLAssetWithURL:url options:asset_options];
        metadata = [self metadataForAsset:avAsset];
    }
    
    if ([avAsset isPlayable]) {
        playable = YES;
    }
    
    if ((!badClip) && [metadata count] == 3) {
        NSString *location = [metadata objectAtIndex:1];
        NSString *timeStr =[metadata objectAtIndex:0];
        NSString *durationStr = [metadata objectAtIndex:2];
        
        NSString *titleStr =[NSString stringWithFormat:@"%@\n%@\n%@", timeStr, location, durationStr];
        titleLabel.text = titleStr;
        
        [[LocationHandler tool] reverseGeocodeAddressWithNotification:location notification:@[ cell, metadata]];
    } else {
        NSLog(@"metadata problem: %@", metadata);
        titleLabel.text = @"bad metadata";
        badClip = YES;
    }
    
    if (!badClip) {
        if (indexPath.section == 0) {
            NSString *clipFname = [[videoList objectAtIndex:indexPath.row] objectAtIndex:0];
            
            [cell setSelected:([selectedEntries indexOfObject:indexPath] != NSNotFound)];
            
            NSString *thumbStr = [[clipFname stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
            
            NSString *thumbPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:thumbStr];
            
            thumbnail = [UIImage imageWithContentsOfFile:thumbPath];
            if (!thumbnail)  {
                [[UtilityBag bag] makeThumbnail:clipFname];
                thumbnail = [UIImage imageWithContentsOfFile:thumbPath];
            }
        } 
        
        imageView.image = thumbnail;
      
        if (![[SettingsTool settings] isOldDevice]) {
            imageView.layer.shadowColor = [UIColor blackColor].CGColor;
            [imageView.layer setShadowOpacity:0.8];
            [imageView.layer setShadowRadius:1.0];
            [imageView.layer setShadowOffset:CGSizeMake(1.0, 1.0)];
        }
        
        UIImageView *bgImage = [[UIImageView alloc] initWithImage:nil];
        bgImage.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#a57342" withAlpha:1.0];
        cell.selectedBackgroundView = bgImage;
    }
    
    if (badClip) {
        cell.backgroundColor = [UIColor redColor];
    } else if (!playable) {
        cell.backgroundColor = [UIColor yellowColor];
        titleLabel.text = @"Not Playable";
    } else {
        cell.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#e5b382" withAlpha:1.0];
    }
    
    if (![[SettingsTool settings] isOldDevice]) {
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:cell.bounds];
        cell.layer.masksToBounds = NO;
        cell.layer.shadowColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
        cell.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
        cell.layer.shadowOpacity = 0.3f;
        cell.layer.shadowRadius = 2.0f;
        cell.layer.shadowPath = shadowPath.CGPath;
    }
    
    
    return cell;
}

#pragma mark - delegate methods

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    lastTapRow = -1;
    
    if ([selectedEntries indexOfObject:indexPath] != NSNotFound) {
        [selectedEntries removeObject:indexPath];
    }
    
    [self updateToolbar];
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger curRow = indexPath.row;
    
    lastTapRow = curRow;
    
    if ([selectedEntries indexOfObject:indexPath] == NSNotFound) {
        [selectedEntries addObject:indexPath];
    }
    [self updateToolbar];
    
    if ((1 == 2) && (indexPath.section == 0)) {
        NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[videoList objectAtIndex:indexPath.row] objectAtIndex:0]]];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVAsset *asset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
        NSString *meta = @"clip meta";
        for (NSString *format in [asset availableMetadataFormats]) {
            for (AVMutableMetadataItem *item in [asset metadataForFormat:format]) {
                meta = [meta stringByAppendingFormat:@"%@\n", item];
            }
        }
        NSLog(@"%@", meta);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)userTappedClose:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [self performSelector:@selector(dealloc2) withObject:nil afterDelay:0.4];
}

- (IBAction)userTappedImport:(id)sender {
    deleteMode = NO;
}

-(void)autoMoveClipsToPhotoAlbum {
    deleteMode = NO;
    NSMutableArray *assetList = [[NSMutableArray alloc] initWithCapacity:3];
    
    BOOL foundAtLeastOneAppLibraryClip = NO;
    
    for (NSArray *a in videoList) {
        NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[a objectAtIndex:0]]];
        [assetList addObject:assetURL];
        foundAtLeastOneAppLibraryClip  = YES;
    }
    
    if (!foundAtLeastOneAppLibraryClip) {
        return;
    }
    
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        return;
    }


    NSArray *activities = @[  [[PhotoAlbumActivity alloc] init] ];
    
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:[assetList copy] applicationActivities:activities];
    [vc.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.navigationBar setTranslucent:NO];
    [vc.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.toolbar    setTranslucent:NO];
    
    vc.excludedActivityTypes = @[
                                 UIActivityTypeAssignToContact,
                                 UIActivityTypeCopyToPasteboard,
                                 UIActivityTypePostToTwitter,
                                 UIActivityTypePostToWeibo,
                                 UIActivityTypePrint,
                                 UIActivityTypeSaveToCameraRoll,
                                 UIActivityTypePostToFacebook,
                                 UIActivityTypePostToVimeo,
                                 UIActivityTypeMail,
                                 UIActivityTypeMessage
                                 ];
    
    vc.completionHandler = ^(NSString *activityType, BOOL completed) {
        NSLog(@"activity %@ completed:%d", activityType, completed);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [selectedEntries removeAllObjects];
            [self performSelector:@selector(updateAssetManagerAndReload) withObject:nil afterDelay:0.05];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"resetAfterActivityDialog" object:nil];
        }

    };
    
    [self presentViewController:vc animated:YES completion:^{
      
    }];
    
}

-(void)userTappedInfoButton:(id)sender {
    UIButton *b = (UIButton *)sender;
    if (b.tag == 1) {
        
        while ([detailView.subviews count] >0) {
            [[detailView.subviews firstObject] removeFromSuperview];
        }
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,75, 400, 50)];
        l.textAlignment = NSTextAlignmentCenter;
        l.text = @"Copying";
        l.textColor = [UIColor whiteColor];
        [detailView addSubview:l];

        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.frame = CGRectMake(175, 12.5, 50,50);
        [detailView addSubview:activityView];
        [activityView startAnimating];
        
        UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progress.frame = CGRectMake(0,150,400,4);
        progress.progressTintColor = [UIColor blueColor];
        progress.tag = 10;
        progress.progress = 0.0f;
        [detailView addSubview:progress];
    
        [[UtilityBag bag] makeCopyOfAsset:detailAsset withDelegate:self];
        return;
    }
    
    [self closeActionDetailView];
}

-(void)closeActionDetailView {
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [animator removeAllBehaviors];
    [animator addBehavior:gravity];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            animator = nil;
            [detailView removeFromSuperview];
            detailView = nil;
        });
    });
}

-(void)assetCopyProgress:(CGFloat )p {
    UIProgressView *progress = (UIProgressView *)[detailView viewWithTag:10];
    progress.progress = p;
}

-(void)assetCopyDidCompleteWithError:(BOOL)hadError andMessage:(NSString *)message {
    if (hadError) {
        while ([detailView.subviews count] >0) {
            [[detailView.subviews firstObject] removeFromSuperview];
        }
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,75, 400, 50)];
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor whiteColor];
        l.numberOfLines = 0;
        l.lineBreakMode = NSLineBreakByWordWrapping;
        l.text = message;
        [detailView addSubview:l];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:5.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self closeActionDetailView];
            });
        });
    } else {
        [self updateAssetManagerAndReload];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            while (![[AssetManager manager] isReady]) {
                [NSThread sleepForTimeInterval:1.0f];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
                [collectionViewPack scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
                selectedEntries = [@[ ip ] mutableCopy];
                [collectionViewPack selectItemAtIndexPath:ip animated:YES scrollPosition:UICollectionViewScrollPositionTop];
                [self closeActionDetailView];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [NSThread sleepForTimeInterval:1.0f];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self userTappedAction:nil];
                    });
                });
            });
        });
    }
}


- (IBAction)userTappedAction:(id)sender {
    if ([selectedEntries count]<1) {
        return;
    }
    
    deleteMode = NO;

    NSMutableArray *assetList = [[NSMutableArray alloc] initWithCapacity:3];
    
    BOOL foundAtLeastOneAppLibraryClip = NO;
    BOOL foundAtLeastOneAssetClip = NO;
    
    ALAssetRepresentation *firstRep = nil;
    
    for (NSIndexPath *indexPath in selectedEntries) {
        if (indexPath.section == 0) {
             NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[videoList objectAtIndex:indexPath.row] objectAtIndex:0]]];
            [assetList addObject:assetURL];
            foundAtLeastOneAppLibraryClip  = YES;
        } else {
            ALAsset *alasset = [[AssetManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
            ALAssetRepresentation *representation = [alasset defaultRepresentation];
            NSURL *url = [representation url];
           [assetList addObject:url];
            foundAtLeastOneAssetClip = YES;
            if (!firstRep) {
                firstRep = representation;
            }
        }
    }
    
    NSArray *activities = @[  ];
    
    if ( (foundAtLeastOneAppLibraryClip) && ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) ) {
        activities = [activities arrayByAddingObject:[[PhotoAlbumActivity alloc] init] ];
    }
    
    if (foundAtLeastOneAssetClip) {
        activities = [activities arrayByAddingObject:[[AppLibraryActivity alloc] init] ];
    }

    if ([selectedEntries count] == 1) {
        NSIndexPath *ip = [selectedEntries objectAtIndex:0];
        if (ip.section == 0) {
            activities  = [activities arrayByAddingObjectsFromArray: @[
                                                           [[YoutubeActivity alloc] init],
                                                           [[DailyMotionActivity alloc] init],
                                                           [[GSDropboxActivity alloc] init],
                                                           [[S3UploaderActivity alloc] init],
                                                           [[AzureActivity alloc] init]//,[[RESTActivity alloc] init]
                                                          ] ];
        } else {
            if (detailView) {
                animator = nil;
                [detailView removeFromSuperview];
                detailView = nil;
            }
            
            animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
            detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200,-200,400,200)];
            [self.view addSubview:detailView];
            
            detailView.backgroundColor = [UIColor blackColor];
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,400,150)];
            l.backgroundColor = [UIColor lightGrayColor];
            l.textColor = [UIColor whiteColor];
            l.textAlignment = NSTextAlignmentCenter;
            l.lineBreakMode = NSLineBreakByWordWrapping;
            l.numberOfLines = 0;
            l.text = @"Uploads to Facebook, Vimeo, Youtube, Daily Motion, Dropbox, REST, S3 or Azure are handled from within the App Library.\n\nCopy this clip to the App Library?";
            l.tag = 1;
            [detailView addSubview:l];
            
            UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
            UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView ] ];
            CGFloat y = self.view.frame.size.height - 50;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                y = (self.view.frame.size.height / 2.0f) - 100;
            }
            [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
            [animator addBehavior:collision];
            [animator addBehavior:gravity];
            
            UIButton *accept = [[UIButton alloc] initWithFrame:CGRectMake(0, 150, 200, 44)];
            [accept setTitle:@"Copy" forState:UIControlStateNormal];
            [accept addTarget:self action:@selector(userTappedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
            accept.tag = 1;
            [detailView addSubview:accept];
            
            UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake(200, 150, 200, 44)];
            
            [close setTitle:@"Cancel" forState:UIControlStateNormal];
            [close addTarget:self action:@selector(userTappedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
            close.tag = 0;
            [detailView addSubview:close];
            detailAsset = firstRep;
            return;
        }
    }
    
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:[assetList copy] applicationActivities:activities];
    [vc.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.navigationBar setTranslucent:NO];
    [vc.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.toolbar    setTranslucent:NO];
    
    vc.excludedActivityTypes = @[
                                 UIActivityTypeAssignToContact,
                                 UIActivityTypeCopyToPasteboard,
                                 UIActivityTypePostToTwitter,
                                 UIActivityTypePostToWeibo,
                                 UIActivityTypePrint,
                                 UIActivityTypeSaveToCameraRoll,
                                 ];
    
    vc.completionHandler = ^(NSString *activityType, BOOL completed) {
        NSLog(@"activity %@ completed:%d", activityType, completed);
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [selectedEntries removeAllObjects];
                [self performSelector:@selector(updateAssetManagerAndReload) withObject:nil afterDelay:0.55];
            } else {
               [[NSNotificationCenter defaultCenter] postNotificationName:@"resetAfterActivityDialog" object:nil];
            }
    };
    
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   [[appD.navController.viewControllers lastObject] presentViewController:vc animated:YES completion:^{
    }];
}

-(void)setAlreadyPromptedForClipMove {
    firstMove = YES;
}


- (IBAction)userTappedPlay:(id)sender {
    if ([selectedEntries count] < 1) {
        return;
    }
    
    deleteMode = NO;
    
 
    NSIndexPath *indexPath = [selectedEntries objectAtIndex:0];
    
    NSURL *assetURL = nil;
    
    if (indexPath.section == 0) {
        NSString *clipPath = [[videoList objectAtIndex:indexPath.row] objectAtIndex:0];
        assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:clipPath]];
    } else {
        ALAsset *alasset = [[AssetManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
            //NSLog(@"alasset:%@:ip:%@", alasset, indexPath);
        ALAssetRepresentation *representation = [alasset defaultRepresentation];
        assetURL = [representation url];
    }
  
    if (!assetURL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clip" message:@"Unable to work with this clip." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    } else {
        [[MovieManager manager] playClipWithURL:assetURL];
        [selectedEntries removeAllObjects];
        lastTapRow = -1;
        [self reloadCollection];
        [self updateToolbar];
    }
}

- (IBAction)userTappedTrim:(id)sender {
    if ([selectedEntries count]<1) {
        return;
    }
    
    deleteMode = NO;

    CutClipViewController *cutVC = [[CutClipViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName: @"CutClipViewController"] bundle:nil];

    NSIndexPath *indexPath = [selectedEntries objectAtIndex:0];
    
    AVURLAsset *asset = nil;
    NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    if (indexPath.section == 0) {
        NSString *clipPath = [[videoList objectAtIndex:indexPath.row] objectAtIndex:0];
        NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:clipPath]];
        asset = [[AVURLAsset alloc] initWithURL:assetURL options:asset_options];
    } else {
        ALAsset *alasset = [[AssetManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
        ALAssetRepresentation *representation = [alasset defaultRepresentation];
        NSURL *assetURL = [representation url];
        asset = [[AVURLAsset alloc] initWithURL:assetURL options:asset_options];
    }
    
    if ( (!asset) || (![asset isComposable]) ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clip" message:@"Unable to work with this clip." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    } else {
        cutVC.clip = asset;
        [self.navigationController pushViewController:cutVC animated:YES];
        
        [selectedEntries removeAllObjects];
        lastTapRow = -1;
    }
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)userTappedTrash:(id)sender {
    if ([selectedEntries count]<1) {
        return;
    }
    deleteMode = YES;
    
    NSInteger deleteCount = [selectedEntries count];
  
    if (deleteCount <1) {
        return;
    }
    
    NSString *desc = [NSString stringWithFormat:@"Permanently delete %ld clip%@?", (long)deleteCount, deleteCount > 1 ? @"s" : @""];
    
    UIActionSheet *deleteSheet = [[UIActionSheet alloc] initWithTitle:desc delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
    [deleteSheet setCancelButtonIndex:1];
    [deleteSheet setDestructiveButtonIndex:0];
    [deleteSheet showFromToolbar:toolBar];
}

- (IBAction)userTappedAdd:(id)sender {
    AddVideoViewController *vc = [[AddVideoViewController alloc] initWithNibName:@"AddVideoViewController" bundle:nil];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!deleteMode) {
        return;
    }
    
    if (buttonIndex == 1) {
        return;
    }
    
   
    while ([selectedEntries count] >0)   {
        NSIndexPath *indexPath = [selectedEntries objectAtIndex:0];
        [selectedEntries removeObjectAtIndex:0];
      
        NSURL *assetURL = nil;
        
        if (indexPath.section == 0) {
            NSString *clipPath = [[videoList objectAtIndex:indexPath.row] objectAtIndex:0];
            assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:clipPath]];
        } else {
            ALAsset *alasset = [[AssetManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
            ALAssetRepresentation *representation = [alasset defaultRepresentation];
            assetURL = [representation url];
        }
        
        if (assetURL) {
            if (indexPath.section == 0) {
                [[UtilityBag bag] removeClip:[[videoList objectAtIndex:indexPath.row] objectAtIndex:0]];
            }
        }
    }
    
    [selectedEntries removeAllObjects];
    lastTapRow = -1;
    [self reloadCollection];
    [self updateToolbar];
   
}

-(void)updateToolbar {
    BOOL singleSelected = [selectedEntries count] == 1;
    
    BOOL multiSelected = [selectedEntries count] > 1;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    if (singleSelected) {
        actionButton.enabled = YES;
        playButton.enabled = YES;
        trimButton.enabled = YES;
        trashButton.enabled = YES;
    } else if (multiSelected) {
        actionButton.enabled = YES;
        playButton.enabled = NO;
        trimButton.enabled = NO;
        trashButton.enabled = YES;
    } else {
        actionButton.enabled = NO;
        playButton.enabled = NO;
        trimButton.enabled = NO;
        trashButton.enabled = NO;
    }


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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
}

-(void)updateLibraryCloseButtonForOrientation:(NSNotification *)n {
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {

        self.view.frame = CGRectMake(0,0,768,1024);
    } else {

        self.view.frame = CGRectMake(0,0,1024,768);
    }

}







@end