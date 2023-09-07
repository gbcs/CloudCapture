//
//  PhotoLibraryViewController.m
//  Capture
//
//  Created by Gary Barnett on 10/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "PhotoLibraryViewController.h"
#import "HelpViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"
#import "GSDropboxActivity.h"
#import "AddPhotoListViewController.h"
#import "PhotoEditView.h"
#import "PhotoEditViewController.h"
#import "GridCollectionViewController.h"
#import "AudioLibraryViewController.h"
#import "StillReviewViewController.h"

static NSString * const kCellReuseIdentifier = @"photoLibraryCollectionViewCell";

@interface PhotoLibraryViewController () {
    UIBarButtonItem *actionButton;

    
    UIBarButtonItem *helpButton;
    UIView *progressContainer;
    UIBarButtonItem *editButton;


    NSArray *assetLibraryGroupList;
    
    NSMutableArray *selectedEntries;
    
    NSIndexPath *lastTapRow;
    IBOutlet UICollectionView *collectionViewPack;
    
    UIView *picViewerView;
    
    NSArray *listForDeletion;
}

@end

@implementation PhotoLibraryViewController

-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
    NSLog(@"%@:%s", [self class], __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    actionButton = nil;
    helpButton = nil;
    progressContainer = nil;
    editButton = nil;
    assetLibraryGroupList = nil;
    selectedEntries = nil;
    lastTapRow = nil;
    collectionViewPack = nil;
    picViewerView = nil;
    listForDeletion = nil;
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)userTappedAction {
    if ([selectedEntries count]<1) {
        return;
    }
    
   
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:1];
    
    for (NSIndexPath *p in selectedEntries) {
        ALAsset *asset = [[PhotoManager manager] entryForGroupAtIndex:p.section-1 atEntryIndex:p.row];
        
        if (asset) {
            NSURL *url = [[asset defaultRepresentation] url];
            if (url) {
                [list addObject:url];
                    //NSLog(@"Adding asset:%@", url);
            }
          
        }
    }

    if ([list count]<1) {
        return;
    }
    
    NSArray *activities = @[ [[GSDropboxActivity alloc] init]];
    
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:[list copy] applicationActivities:activities];
    [vc.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.navigationBar setTranslucent:NO];
    [vc.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.toolbar    setTranslucent:NO];
    
    vc.excludedActivityTypes = @[
                                
                               
                           
                                 ];
    
    vc.completionHandler = ^(NSString *activityType, BOOL completed) {
        NSLog(@"activity %@ completed:%d", activityType, completed);
    };
    
    [self presentViewController:vc animated:YES completion:^{
        [selectedEntries removeAllObjects];
        [self reloadCollection];
        [self updateToolbar];
    }];
    
    
    
}

-(void)userTappedEdit {
    if (lastTapRow) {
        ALAsset *alasset = [[PhotoManager manager] entryForGroupAtIndex:lastTapRow.section-1 atEntryIndex:lastTapRow.row];
        if (alasset) {
            PhotoEditViewController *vc = [[PhotoEditViewController alloc] initWithNibName:@"PhotoEditViewController" bundle:nil];
            vc.asset = alasset;
            [self.navigationController pushViewController:vc animated:YES];
            //[self viewAsset:alasset];
        }
    }
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    selectedEntries = [@[ ] mutableCopy];
    [collectionViewPack registerNib:[UINib nibWithNibName:@"PhotoLibraryCollectionViewItem" bundle:nil] forCellWithReuseIdentifier:kCellReuseIdentifier];
    [collectionViewPack registerNib:[UINib nibWithNibName:@"GridCollectionHeaderViewItem" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    
    [collectionViewPack setAllowsSelection:YES];
    [collectionViewPack setAllowsMultipleSelection:YES];
   
    helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelpButton)];
    
    self.navigationItem.leftBarButtonItem = nil;
    
    progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0,0,140,30)];
    progressContainer.backgroundColor = [UIColor clearColor];
    
    self.navigationItem.rightBarButtonItems = @[ helpButton];
   
    self.navigationItem.title = @"Pictures";
    
    UISegmentedControl *seg =[[UISegmentedControl alloc] initWithItems:@[ @"Video" , @"Pictures", @"Audio"] ];
    [seg addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventValueChanged];
    seg.selectedSegmentIndex = 1;
    self.navigationItem.titleView = seg;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    
    editButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(userTappedEdit)];
    actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(userTappedAction)];
   
    self.toolbarItems = @[
                           editButton,
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           actionButton,
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(userTappedAdd)]
                            ];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePhotoLibrary:) name:@"updatePhotoLibrary" object:nil];
    self.navigationController.toolbarHidden = NO;
}

-(void)waitOnLibraryForPhotoLibrary:(UISegmentedControl *)seg {
    if ([[PhotoManager manager] isReady]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [self reloadCollection];
    } else {
        [self performSelector:@selector(waitOnLibraryForPhotoLibrary:) withObject:seg afterDelay:0.25];
    }
}


-(void)updatePhotoLibrary:(NSNotification *)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PhotoManager manager] update];
            [self performSelector:@selector(waitOnLibraryForPhotoLibrary:) withObject:nil afterDelay:0.25];
        });
    });
}

-(void)userTappedAdd {
    AddPhotoListViewController *vc = [[AddPhotoListViewController alloc] initWithNibName:@"AddPhotoListViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)userTappedHelpButton {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)changeMode:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    if (seg.selectedSegmentIndex == 0) {
        [seg setSelectedSegmentIndex:1];
        [[PhotoManager manager] cleanup];
        [[UtilityBag bag] logEvent:@"library" withParameters:nil];
        GridCollectionViewController *vc = [[GridCollectionViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"GridCollectionViewController"] bundle:nil];
        NSMutableArray *vcList = [self.navigationController.viewControllers mutableCopy];
        [vcList removeLastObject];
        [vcList addObject:vc];
        [self.navigationController setViewControllers:[vcList copy] animated:NO];
    } else if (seg.selectedSegmentIndex == 2) {
        [[AudioBrowser manager] update];
        [self performSelector:@selector(waitOnLibraryForAudioBrowser:) withObject:seg afterDelay:0.25];
    }
}

-(void)waitOnLibraryForAudioBrowser:(UISegmentedControl *)seg {
    if ([[AudioBrowser manager] isReady]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        AudioLibraryViewController *vc = [[AudioLibraryViewController alloc] initWithNibName:@"AudioLibraryViewController" bundle:nil];
        NSMutableArray *vcList = [self.navigationController.viewControllers mutableCopy];
        [vcList removeLastObject];
        [vcList addObject:vc];
        [self.navigationController setViewControllers:[vcList copy] animated:NO];
    } else {
        [self performSelector:@selector(waitOnLibraryForAudioBrowser:) withObject:seg afterDelay:0.25];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)userTappedClose {
    self.navigationController.toolbarHidden = YES;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadCollection {
    assetLibraryGroupList = [[PhotoManager manager] groups];
    
    if (collectionViewPack) {
        [collectionViewPack reloadData];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [self waitOnLibraryForPhotoLibrary:nil];
    [super viewWillAppear:animated];
    [[SyncManager manager] progressContainer].frame = CGRectMake(0,2,140,30);
    
    [progressContainer addSubview:[[SyncManager manager] progressContainer]];
    
    [self updateToolbar];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numFound = 0;
    
    if (section == 0) {
        numFound =[[[PhotoManager manager] unreviewedStillGroups] count];
    } else {
       numFound = [[PhotoManager manager] groupEntryCount:section-1];
    }
    
    return numFound;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [assetLibraryGroupList count] +1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize s = CGSizeMake(self.view.frame.size.width,20);

    if (section == 0) {
        if ([[PhotoManager manager] unreviewedStillGroupEntryCount:0] < 1) {
            s = CGSizeZero;
        }
    }
    
    return s;
}

-(NSArray *)metadataForItemWithName:(NSString *)fname {
    NSString *path = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:fname];
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
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


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    
    if (indexPath.section == 0) {
        titleLabel.text = @"Unreviewed Stills";
    } else {
        titleLabel.text = [assetLibraryGroupList objectAtIndex:indexPath.section-1];
    }
    
    if (![progressContainer.superview isEqual:cell]) {
        progressContainer.frame = CGRectMake(cell.bounds.size.width - (progressContainer.bounds.size.width + 10), 0, progressContainer.bounds.size.width, progressContainer.bounds.size.height);
        [cell addSubview:progressContainer];
    }
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:101];
    UILabel *infoLabel = (UILabel *)[cell viewWithTag:88];
    
    UIImage *thumbnail = nil;
    
    ALAsset *alasset = nil;
    
    if (indexPath.section == 0) {
        imageView.image = nil;
        imageView.hidden = YES;
        infoLabel.hidden = NO;
        NSInteger count = [[PhotoManager manager] unreviewedStillGroupEntryCount:indexPath.row];
        infoLabel.text = [NSString stringWithFormat:@"%@ photos, %@", @(count), [[[PhotoManager manager] unreviewedStillGroups] objectAtIndex:indexPath.row]];
    } else {
        infoLabel.hidden = YES;
        imageView.hidden = NO;
        alasset = [[PhotoManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
        if (alasset) {
            thumbnail = [UIImage imageWithCGImage:[alasset aspectRatioThumbnail] scale:1.0 orientation:UIImageOrientationUp];
        }
    }

    if (thumbnail) {
        imageView.image = thumbnail;
        
        imageView.layer.shadowColor = [UIColor blackColor].CGColor;
        [imageView.layer setShadowOpacity:0.8];
        [imageView.layer setShadowRadius:1.0];
        [imageView.layer setShadowOffset:CGSizeMake(1.0, 1.0)];
        
        UIImageView *bgImage = [[UIImageView alloc] initWithImage:nil];
        bgImage.backgroundColor = [UIColor blackColor];
        cell.selectedBackgroundView = bgImage;
    }
    
    cell.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#111111" withAlpha:1.0];
    
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:nil];
    bgImage.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#AAAAAA" withAlpha:1.0];
    cell.selectedBackgroundView = bgImage;

    return cell;
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (tag == 1) {
        if (picViewerView) {
            [picViewerView removeFromSuperview];
            picViewerView = nil;
        }
    }
}

-(void)viewAsset:(ALAsset *)asset {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   
    UIImage *thumbnail = nil;
    
    picViewerView = [[UIView alloc] initWithFrame:appD.navController.view.bounds];
    picViewerView.backgroundColor = [UIColor blackColor];
    UIImageView *picImageView = [[UIImageView alloc] initWithFrame:appD.navController.view.bounds];
    [appD.navController.view addSubview:picViewerView];
    [picViewerView addSubview:picImageView];
    picImageView.contentMode = UIViewContentModeScaleAspectFit;
    picImageView.userInteractionEnabled = YES;
    
    if (asset) {
        ALAssetRepresentation *r = [asset defaultRepresentation];
        
        NSInteger orientation = UIImageOrientationUp;
        if (r.dimensions.width < r.dimensions.height) {
            orientation = UIImageOrientationLeft;
        }

        thumbnail = [UIImage imageWithCGImage:[r fullScreenImage] scale:1.0 orientation:orientation];
        picImageView.image = thumbnail;
    }
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(0,0,50,44)];
    
    NSString *bColor = @"#006600";
    NSString *eColor = @"#003300";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[[UtilityBag bag] standardFont] fontWithSize:10], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Close" attributes:strAttr];
    [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = YES;
    button.delegate = self;
    [button update];
    button.tag = 1;
    
    [picImageView addSubview:button];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
  
    [self performSelector:@selector(checkAd) withObject:Nil afterDelay:1.0f];
}

-(void)checkAd {
    if ([[SettingsTool settings] hasDoneSomethingAdWorthy]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:1.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"showAdOnController" object:self];
            });
        });
    }
}
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [picViewerView removeFromSuperview];
    picViewerView = nil;
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ( ([lastTapRow isEqual:indexPath]) && ([selectedEntries indexOfObject:indexPath] != NSNotFound) && ([selectedEntries count] == 1)) {
        if (picViewerView) {
            [picViewerView removeFromSuperview];
            picViewerView = nil;
        }
    }
    
    if ([selectedEntries indexOfObject:indexPath] != NSNotFound) {
        [selectedEntries removeObject:indexPath];
    }

    lastTapRow = indexPath;
    
    [self updateToolbar];
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    lastTapRow = indexPath;
    
    if ([selectedEntries indexOfObject:indexPath] == NSNotFound) {
        [selectedEntries addObject:indexPath];
    }
    
    [self updateToolbar];
    
    if (indexPath.section == 0) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        StillReviewViewController *vc = [[StillReviewViewController alloc] initWithNibName:@"StillReviewViewController" bundle:nil];
        vc.reviewGroupIndex = indexPath.row;
        [self.navigationController pushViewController:vc animated:YES];
    }
}



- (IBAction)userTappedAction:(id)sender {
      
    NSMutableArray *assetList = [[NSMutableArray alloc] initWithCapacity:3];
    
    for (NSIndexPath *indexPath in selectedEntries) {
       
            ALAsset *alasset = [[PhotoManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
            ALAssetRepresentation *representation = [alasset defaultRepresentation];
            NSURL *url = [representation url];
            [assetList addObject:url];
        
    }
    
    NSArray *activities = @[ [[GSDropboxActivity alloc] init]];
    
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
    };
    
    [self presentViewController:vc animated:YES completion:^{
        [selectedEntries removeAllObjects];
        [self reloadCollection];
        [self updateToolbar];
    }];
    
    [self updateToolbar];
    
}



-(void)updateToolbar {
    BOOL singleSelected = [selectedEntries count] == 1;
    BOOL multiSelected = [selectedEntries count] > 1;
    
    if (singleSelected) {
        actionButton.enabled = YES;
        editButton.enabled = YES;
    } else if (multiSelected) {
        actionButton.enabled = YES;
        editButton.enabled = NO;
    } else {
        actionButton.enabled = NO;
        editButton.enabled = NO;
    }
}







@end
