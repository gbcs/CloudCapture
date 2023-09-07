//
//  AudioLibraryViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/10/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioLibraryViewController.h"
#import "AppDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "PhotoLibraryViewController.h"
#import "HelpViewController.h"
#import "AudioLevelView.h"
#import "AudioSoundsViewController.h"
#import "AudioEditorViewController.h"
#import "GSDropboxActivity.h"
#import "GridCollectionViewController.h"
#import "PhotoLibraryViewController.h"

@interface AudioLibraryViewController () {
    
    NSMutableArray *selectedEntries;
    
    __weak IBOutlet UIToolbar *toolBar;
    
    NSInteger lastTapRow;
    IBOutlet UICollectionView *collectionViewPack;
    
    UIBarButtonItem *addButton;
    UIBarButtonItem *playButton;
    UIBarButtonItem *editButton;
    UIBarButtonItem *trashButton;
    UIBarButtonItem *combineButton;
    UIBarButtonItem *actionButton;
    
    BOOL deleteMode;
    
    UIBarButtonItem *closeButton;
    
    BOOL isPlaying;
    
    UIDynamicAnimator *animator;
    UIView *audioPlayerView;
    UISlider *audioPlayerSlider;
    UILabel *audioPosLabel;
    
    UIView *combineView;
    
    AVAudioPlayer *audioPlayer;
    
    AudioLevelView *levelR;
    AudioLevelView *levelL;
    
    NSTimer *audioPlayTimer;
    float updatedPosition;
    BOOL processing;
    
    AVComposition *composition;
    AVAssetExportSession *exporter;
    NSMutableArray *deletionList;
}

@end

@implementation AudioLibraryViewController

static NSString * const kCellReuseIdentifier = @"audioLibraryCollectionViewCell";

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
    NSLog(@"%@:%s", [self class], __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    selectedEntries = nil;
    toolBar = nil;
    collectionViewPack = nil;
    addButton = nil;
    playButton = nil;
    actionButton = nil;
    editButton = nil;
    trashButton = nil;
     closeButton = nil;
    animator = nil;
    audioPlayerView = nil;
    audioPlayerSlider = nil;
    audioPosLabel = nil;
    audioPlayer = nil;
    levelR = nil;
    levelL = nil;
    audioPlayTimer = nil;
    combineButton = nil;
    
    [[AudioBrowser manager] cleanup];

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAssetManagerAndReload) name:@"updateAudioLibraryAndReload" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanupPhotoLibraryViewController" object:nil];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishShowing:) name:@"finishPlaying" object:nil];
    
    collectionViewPack.allowsMultipleSelection = NO;
    
    self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelpButton:)];
   
    closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose:)];
    
    self.navigationItem.title = @"Library";
    
    UISegmentedControl *seg =[[UISegmentedControl alloc] initWithItems:@[ @"Video" , @"Pictures", @"Audio"] ];
    [seg addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventValueChanged];
    seg.selectedSegmentIndex = 2;
    self.navigationItem.titleView = seg;
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

-(void)waitOnLibraryForPhotoLibrary:(UISegmentedControl *)seg {
    if ([[PhotoManager manager] isReady]) {
        [seg setSelectedSegmentIndex:1];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        PhotoLibraryViewController *vc = [[PhotoLibraryViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"PhotoLibraryViewController"] bundle:nil];
        NSMutableArray *vcList = [self.navigationController.viewControllers mutableCopy];
        [vcList removeLastObject];
        [vcList addObject:vc];
        [self.navigationController setViewControllers:[vcList copy] animated:NO];
    } else {
        [self performSelector:@selector(waitOnLibraryForPhotoLibrary:) withObject:seg afterDelay:0.25];
    }
}

-(void)changeMode:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    if (seg.selectedSegmentIndex == 0) {
        [[UtilityBag bag] logEvent:@"library" withParameters:nil];
        GridCollectionViewController *vc = [[GridCollectionViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"GridCollectionViewController"] bundle:nil];
        NSMutableArray *vcList = [self.navigationController.viewControllers mutableCopy];
        [vcList removeLastObject];
        [vcList addObject:vc];
        [self.navigationController setViewControllers:[vcList copy] animated:NO];
    } else if (seg.selectedSegmentIndex == 1) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [[PhotoManager manager] update];
        [self performSelector:@selector(waitOnLibraryForPhotoLibrary:) withObject:seg afterDelay:0.25];
    }
}

-(void)userTappedHelpButton:(id)sender {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    collectionViewPack.allowsMultipleSelection = YES;
    
    
    UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.titleView;
    [seg setEnabled:([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) forSegmentAtIndex:1];
    
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = YES;
    
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbarHidden = NO;
    
    
    trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(userTappedTrash:)];
    editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedEdit:)];
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(userTappedAdd:)];
    combineButton = [[UIBarButtonItem alloc] initWithTitle:@"Combine" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCombine:)];
    actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(userTappedAction:)];
    
    [selectedEntries removeAllObjects];
     
    [self updateToolbar];
    
}

-(void)userTappedCombine:(id)sender {
    if (combineView) {
        return;
    }
    
    combineView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 230, -230, 460, 230)];
    [self.view addSubview:combineView];
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ combineView ] ];
    CGFloat yPos = self.view.frame.size.height - 50;
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, yPos) toPoint:CGPointMake(self.view.frame.size.width, yPos)];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ combineView ] ];
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    
    combineView.backgroundColor = [UIColor whiteColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,460, 50)];
    l.backgroundColor = [UIColor darkGrayColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.textColor = [UIColor whiteColor];
    l.text = @"Combine Audio Clips";
    [combineView addSubview:l];
    
    UILabel *l2 = [[UILabel alloc] initWithFrame:CGRectMake(20,60,420, 70)];
    l2.backgroundColor = [UIColor darkGrayColor];
    l2.textColor = [UIColor whiteColor];
    l2.textAlignment = NSTextAlignmentCenter;
    [combineView addSubview:l2];

    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedCombineView:)];
    [combineView addGestureRecognizer:tapG];
    
    
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(180, 170, 100, 50)];
    button.enabled = YES;
    button.delegate = self;
    button.tag = 200;
    NSAttributedString *eActive = [[NSAttributedString alloc] initWithString:@"Start" attributes:@{
                                                                                                     NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1],
                                                                                                  
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }];
    
    [button setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    [button update];
    [combineView addSubview:button];
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    CMTime duration = kCMTimeZero;
    
    NSError *editError;
    CMTime begin = CMTimeMake(0,duration.timescale);
    BOOL failed = NO;
    AVURLAsset *firstAsset = nil;
    
    AVMutableCompositionTrack *audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    for (NSIndexPath *ip in selectedEntries) {
        AVURLAsset *songAsset = nil;
        if (ip.section == 0) {
            NSString *filename = [[AudioBrowser manager] entryforAppLibraryAtIndex:ip.item];
            
            NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:filename]];
            NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
        } else {
            MPMediaItem *item = [[AudioBrowser manager] entryForArtistAtIndex:ip.section atEntryIndex:ip.item];
            NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
            NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
        }
        
        if (songAsset && [songAsset isComposable]) {
            if (!firstAsset) {
                firstAsset = songAsset;
            }
            AVAssetTrack *clipAudioTrack = [[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, songAsset.duration) ofTrack:clipAudioTrack atTime:begin error:&editError];
            begin = CMTimeAdd(begin, songAsset.duration);
            if (editError) {
                NSLog(@"combine_error:%@", [editError localizedDescription]);
                failed = YES;
                break;
            }
        } else {
            NSLog(@"combine_error:no asset for %@", ip);
            failed = YES;
            break;
        }
    }
    
    if(failed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Combine Error" message:@"Unable to complete the operation." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        [self closeCombineView];
    }
    composition  = [mutableComposition copy];
    NSString *audioFName = [[UtilityBag bag] pathForNewResourceWithExtension:@"m4a"];
    NSString *audioFPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:audioFName];
    NSURL *audioURL = [NSURL fileURLWithPath:audioFPath];
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    exporter.outputFileType=AVFileTypeAppleM4A;
    exporter.outputURL=audioURL;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *originalTimeStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *originalLoc = @"";
    NSString *originalTitle = @"";
    
    NSArray *originalMetadata = [firstAsset metadataForFormat:@"com.apple.quicktime.mdta"];
    for (AVMutableMetadataItem *a in originalMetadata) {
        if ([a.commonKey isEqualToString:@"creationDate"]) {
            originalTimeStr = (NSString *)a.value;
        } else if ([a.commonKey isEqualToString:@"location"]) {
            originalLoc = (NSString *)a.value;
        } else if ([a.commonKey isEqualToString:@"title"]) {
            originalTitle = (NSString *)a.value;
        }
    }
    
    NSMutableArray *metadata = [[NSMutableArray alloc] initWithCapacity:3];
    
    AVMutableMetadataItem *item = nil;
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.key = AVMetadataCommonKeyCreationDate;
    item.value = originalTimeStr;
    [metadata addObject:item];
    
    if ([[SettingsTool settings] useGPS]) {
        item = [[AVMutableMetadataItem alloc] init];
        item.keySpace = AVMetadataKeySpaceCommon;
        item.key = AVMetadataCommonKeyLocation;
        item.value = originalLoc;
        [metadata addObject:item];
    }
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceQuickTimeUserData;
    item.key = AVMetadataQuickTimeUserDataKeyTrack;
    item.value = [NSNumber numberWithInt:1];
    [metadata addObject:item];
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.locale = [NSLocale currentLocale];
    item.key = AVMetadataCommonKeyTitle;
    item.value = [NSString stringWithFormat:@"%@[combine]", originalTitle];
    [metadata addObject:item];
    
    
    AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
    [metadata addObject:descUID];
    
    exporter.metadata = [metadata copy];
    
    exporter.timeRange=CMTimeRangeFromTimeToTime(CMTimeMake(1,composition.duration.timescale), composition.duration);
    
    l2.numberOfLines = 3;
    
    NSInteger hours = CMTimeGetSeconds(composition.duration) / (60 * 60);
    
    NSInteger remain = CMTimeGetSeconds(composition.duration) - (hours * 60 * 60);
    
    NSInteger minutes = remain / 60;
    
    NSInteger seconds = remain - (minutes * 60);
   
    l2.text = [NSString stringWithFormat:@"Combine %ld audio clips\n\nDuration: %02ld:%02ld:%02ld", (long)[selectedEntries count], (long)hours, (long)minutes, (long)seconds];

}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    GradientAttributedButton *button = (GradientAttributedButton *)[combineView viewWithTag:200];
    if (!button) {
        return;
    }
    
    if (!processing) {
        processing = YES;
        NSAttributedString *eActive = [[NSAttributedString alloc] initWithString:@"Stop" attributes:@{
                                                                                                       NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1],
                                                                                        
                                                                                                       NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                       }];
        
        [button setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
        UIActivityIndicatorView *i = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [i setColor:[UIColor blackColor]];
        i.center = CGPointMake(230,152);
        [combineView addSubview:i];
        [i startAnimating];
        [self startProcessing];
    } else {
        [self cancelProcessing];
        [self closeCombineView];
    }
}
            

-(void)cancelProcessing {
    [exporter cancelExport];
}

-(void)startProcessing {
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        [self performSelectorOnMainThread:@selector(closeCombineView) withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(updateAssetManagerAndReload) withObject:nil waitUntilDone:NO];
        
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed:{
                NSLog(@"Export failed: %@ %@", [[exporter error] localizedDescription],[[exporter error]debugDescription]);
                break;
            }
            case AVAssetExportSessionStatusCancelled:{
                NSLog(@"Export canceled");
                break;
            }
            case AVAssetExportSessionStatusCompleted:
            {
                break;
            }
        }
        composition = nil;
        exporter = nil;
        processing = NO;
    }];

}


-(void)userTappedCombineView:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self closeCombineView];
    }
}

-(void)finishClosingCombineView {
    [animator removeAllBehaviors];
    animator = nil;
    [combineView removeFromSuperview];
    combineView = nil;
}

-(void)closeCombineView {
    if (combineView) {
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ combineView ] ];
        [animator removeAllBehaviors];
        [animator addBehavior:gravity];
        [self performSelector:@selector(finishClosingCombineView) withObject:nil afterDelay:1.5f];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [selectedEntries removeAllObjects];
    [self reloadCollection];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanupAudioRecorder" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanupAudioEditor" object:nil];
    [self performSelector:@selector(checkAd) withObject:Nil afterDelay:1.0f];
}

-(void)checkAd {
    if ([[SettingsTool settings] hasDoneSomethingAdWorthy]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:0.75f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"showAdOnController" object:self];
            });
        });
    }
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

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (audioPlayer) {
        [audioPlayer stop];
        [audioPlayTimer invalidate];
        audioPlayTimer = nil;
        animator = nil;
        [audioPlayerView removeFromSuperview];
        audioPlayerView = nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    lastTapRow = -1;
    
    if ([selectedEntries indexOfObject:indexPath] != NSNotFound) {
        [selectedEntries removeObject:indexPath];
    }
    
    if (isPlaying) {
        if (audioPlayerView) {
            [self closeAudioPlayer];
        }
        isPlaying = NO;
    }
    
    [self updateToolbar];
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger curRow = indexPath.row;
    
    if ([selectedEntries indexOfObject:indexPath] == NSNotFound) {
        [selectedEntries addObject:indexPath];
    } else if (lastTapRow == curRow) {
        [self startPlaying:YES];
    }
        
    lastTapRow = curRow;
        
    [self updateToolbar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}


- (IBAction)userTappedClose:(id)sender {
     if (audioPlayer.playing) {
        [audioPlayer stop];
    }

    deleteMode = NO;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)userTappedImport:(id)sender {
    deleteMode = NO;
}



- (IBAction)userTappedAction:(id)sender {
    NSIndexPath *indexPath = [selectedEntries objectAtIndex:0];
    if ((!indexPath) || (indexPath.section !=0) ) {
        actionButton.enabled = NO;
        return;
    }
    
    NSString *filepath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[AudioBrowser manager] entryforAppLibraryAtIndex:indexPath.row]];
    NSURL *url = [NSURL fileURLWithPath:filepath];
    
    NSArray *activities = @[ [[GSDropboxActivity alloc] init]];
    
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[ url ] applicationActivities:activities];
    [vc.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.navigationBar setTranslucent:NO];
    [vc.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.toolbar    setTranslucent:NO];
    
    vc.excludedActivityTypes = @[
                                 UIActivityTypeAssignToContact,
                                 UIActivityTypeCopyToPasteboard,
                                 UIActivityTypePostToTwitter,
                                 UIActivityTypePostToWeibo,
                                 UIActivityTypePrint
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

- (IBAction)userTappedPlay:(id)sender {
    [self startPlaying:NO];
}

-(void)startPlaying:(BOOL)paused {
    if (isPlaying) {
        isPlaying = NO;
        if (audioPlayerView) {
            if (audioPlayer.playing) {
                [audioPlayer stop];
            }

            [self closeAudioPlayer];
        }
        
        [self updateToolbar];
        return;
    }
    
    deleteMode = NO;
    
    if ([selectedEntries count] < 1) {
        return;
    }
    
    NSIndexPath *ip = [selectedEntries objectAtIndex:0];
    
    isPlaying = YES;
    
    if (ip.section == 0) {
        NSString *filename = [[AudioBrowser manager] entryforAppLibraryAtIndex:ip.item];
        
        NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:filename]];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];

        [self showAudioPlayerAtIndex:songAsset atIndexPath:ip startPaused:paused];
    } else {
        MPMediaItem *item = [[AudioBrowser manager] entryForArtistAtIndex:ip.section atEntryIndex:ip.item];
        NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
        [self showAudioPlayerAtIndex:songAsset atIndexPath:ip startPaused:paused];
    }
    
    [self updateToolbar];
  
    audioPlayTimer  = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateTimerEvent) userInfo:nil repeats:YES];
    
}


                            

- (IBAction)userTappedEdit:(id)sender {
    deleteMode = NO;
    if ([selectedEntries count] != 1) {
        return;
    }
    NSString *nibName = @"AudioEditorViewController";
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        nibName = [nibName stringByAppendingString:@"iPad"];
    }

    AudioEditorViewController *vc = [[AudioEditorViewController alloc] initWithNibName:nibName bundle:nil];
    
    NSIndexPath *ip = [selectedEntries objectAtIndex:0];
    AVURLAsset *songAsset = nil;
    if (ip.section == 0) {
        NSString *filename = [[AudioBrowser manager] entryforAppLibraryAtIndex:ip.item];
        NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:filename]];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
    } else {
        MPMediaItem *item = [[AudioBrowser manager] entryForArtistAtIndex:ip.section atEntryIndex:ip.item];
        NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
    }
    
    vc.asset = songAsset;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)userTappedAdd:(id)sender {
    AudioSoundsViewController *vc = [[AudioSoundsViewController alloc] initWithNibName:@"AudioSoundsViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)userTappedTrash:(id)sender {
    deleteMode = YES;
    
    NSInteger deleteCount = [selectedEntries count];
    
    if (deleteCount < 1) {
        return;
    }
    
    NSMutableArray *list = [@[ ] mutableCopy];
    
    for (NSIndexPath *ip in selectedEntries) {
        if (ip.section > 0) {
            continue;
        }
        
        [list addObject:ip];
    }
    
    if ([list count]<1) {
        return;
    }
    
    deletionList = list;
    
    NSString *txt = [NSString stringWithFormat:@"Permanently delete %lu item%@?", (unsigned long)[list count], [list count] > 1 ? @"s" : @""];
        
    UIActionSheet *deleteSheet = [[UIActionSheet alloc] initWithTitle:txt delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
    [deleteSheet setCancelButtonIndex:1];
    [deleteSheet setDestructiveButtonIndex:0];
    [deleteSheet showFromToolbar:self.navigationController.toolbar];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!deleteMode) {
        deletionList = nil;
        return;
    }
    
    if (buttonIndex == 1) {
        deletionList = nil;
        return;
    }
    
    [deletionList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSIndexPath *ip1 = (NSIndexPath *)obj1;
        NSIndexPath *ip2 = (NSIndexPath *)obj2;
        return [ip1 compare:ip2];
    }];
    
    NSInteger numDeleted = 0;
    for (NSIndexPath *ip  in deletionList) {
        [[AudioBrowser manager] removeAppLibraryAudioItemAtIndex:ip.item - numDeleted];
        numDeleted++;
    }
    
    [selectedEntries removeAllObjects];
    [self updateToolbar];
    
    [self updateAssetManagerAndReload];
}

-(void)updateToolbar {
    BOOL singleSelected = [selectedEntries count] == 1;
    BOOL multipleSelected = [selectedEntries count] > 1;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    if (isPlaying) {
        playButton =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(userTappedPlay:)];
    } else {
        playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(userTappedPlay:)];
    }
    
    self.toolbarItems =  @[ trashButton,
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            editButton,
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            playButton,
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            combineButton,
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            actionButton,
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            addButton
                            ];

    addButton.enabled = NO;
    playButton.enabled = NO;
    editButton.enabled = NO;
    trashButton.enabled = NO;
    combineButton.enabled = NO;
    actionButton.enabled = NO;

    if (isPlaying) {
        playButton.enabled = YES;
    } else if (multipleSelected) {
        addButton.enabled = YES;
        combineButton.enabled = YES;
        BOOL hasAppLibraryFile = NO;
        for (NSIndexPath *ip in selectedEntries) {
            if (ip.section == 0) {
                hasAppLibraryFile = YES;
                break;
            }
        }
        trashButton.enabled = hasAppLibraryFile;
    } else if (singleSelected) {
        NSIndexPath *ip = [selectedEntries objectAtIndex:0];
        if (ip.section == 0) {
            playButton.enabled = YES;
            editButton.enabled = YES;
            trashButton.enabled = YES;
            actionButton.enabled = YES;
        } else {
            playButton.enabled = YES;
            editButton.enabled = YES;
        }
        addButton.enabled = YES;
    } else {
        addButton.enabled = YES;
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



- (BOOL)prefersStatusBarHidden {
    return YES;
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

-(void)closeAudioPlayer {
    
    [audioPlayTimer invalidate];
    audioPlayTimer = nil;
    
    [animator removeAllBehaviors];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ audioPlayerView] ];
    [animator addBehavior:gravity];
    [self performSelector:@selector(removeAudioPlayer) withObject:nil afterDelay:2.0];
    
}

-(void)removeAudioPlayer {
    [animator removeAllBehaviors];
    animator = nil;
    [audioPlayerView removeFromSuperview];
    audioPlayerView = nil;
    
    audioPlayerSlider = nil;
    audioPosLabel = nil;
    
    [self updateToolbar];
}

-(void)showAudioPlayerAtIndex:(AVURLAsset *)asset atIndexPath:(NSIndexPath *)indexPath startPaused:(BOOL)paused {
    
    if (audioPlayerView) {
        return;
    }
    
    NSString *filename = nil;
    
    if (indexPath.section == 0) {
        filename = [[AudioBrowser manager] entryforAppLibraryAtIndex:indexPath.item];
    } else {
        MPMediaItem *item = [[AudioBrowser manager] entryForArtistAtIndex:indexPath.section atEntryIndex:indexPath.item];
        filename = [item valueForProperty:MPMediaItemPropertyTitle];
    }

    isPlaying = YES;
    [self updateToolbar];
    audioPlayerView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200, -270, 400, 220)];
    audioPlayerView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [self.view addSubview:audioPlayerView];
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ audioPlayerView] ];
    
    CGFloat y = self.view.frame.size.height - 50;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = (self.view.frame.size.height / 2.0f) - 110;
    }
    
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ audioPlayerView] ];
    
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    
    
    UILabel *f = [[UILabel alloc] initWithFrame:CGRectMake(0,0,400,70)];
    f.text = filename;
    f.lineBreakMode = NSLineBreakByWordWrapping;
    f.textAlignment = NSTextAlignmentCenter;
    f.textColor = [UIColor whiteColor];
    f.numberOfLines = 0;
    f.tag = 999;
    [audioPlayerView addSubview:f];
    
    if (indexPath.section == 0) {
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedAudioPlayerTitleEdit:)];
        [f addGestureRecognizer:tapG];
        f.userInteractionEnabled = YES;
       
    }
    
    
    audioPosLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,80,400,30)];
    audioPosLabel.text = [self durationStr:CMTimeGetSeconds(asset.duration)];
    audioPosLabel.textColor = [UIColor whiteColor];
    audioPosLabel.textAlignment = NSTextAlignmentCenter;
    [audioPlayerView addSubview:audioPosLabel];
    
    audioPlayerSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,120,400,50)];
    [audioPlayerSlider addTarget:self action:@selector(posSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [audioPlayerView addSubview:audioPlayerSlider];
    
    UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(170,180,60,40)];
    [b setTitle:paused ? @"Play" : @"Pause" forState:UIControlStateNormal];
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    [audioPlayerView addSubview:b];
    [b addTarget:self action:@selector(userTappedAudioPlayerPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    b.tag = 1337;
    
    
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[asset URL] error:&error];
    if (error) {
        NSLog(@"audio file error:%@", [error localizedDescription]);
    }
    audioPlayer.numberOfLoops = 0;
    [audioPlayer setMeteringEnabled:YES];
    
    audioPlayerSlider.maximumValue = audioPlayer.duration;
    if (!paused) {
       [self performSelector:@selector(startPlaying) withObject:nil afterDelay:2.0f];
    }
   
}

-(void)userTappedAudioPlayerTitleEdit:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        g.view.userInteractionEnabled = NO;
        UILabel *titleLabel = (UILabel *)[audioPlayerView viewWithTag:999];
       
        UITextView *titleTextView = [[UITextView alloc] initWithFrame:titleLabel.frame];
        titleTextView.tag = 1000;
        titleTextView.delegate = self;
        titleTextView.font = [UIFont boldSystemFontOfSize:17];
        [audioPlayerView addSubview:titleTextView];
        [titleTextView becomeFirstResponder];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    BOOL renameAccepted = NO;

    UILabel *titleLabel = (UILabel *)[audioPlayerView viewWithTag:999];
    
    if ([textView.text length] > 0) {
        
        NSError *error = nil;
        
        NSString *ext = [titleLabel.text pathExtension];
        
        NSString *fname = [textView.text stringByAppendingPathExtension:ext];
        
        NSString *dp = [[UtilityBag bag] docsPath];
        
        [[NSFileManager defaultManager] moveItemAtPath:[dp stringByAppendingPathComponent:titleLabel.text] toPath:[dp stringByAppendingPathComponent:fname] error:&error];
      
        if (!error) {
           renameAccepted = YES;
        }
    }
    
    
    if (renameAccepted) {
        titleLabel.text = textView.text;
    }
    
    titleLabel.userInteractionEnabled = YES;
    
    [textView removeFromSuperview];
    
    if (renameAccepted) {
        [self performSelector:@selector(updateAssetManagerAndReload) withObject:nil afterDelay:0.25];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else if (![text isEqualToString:@""]) {
        unichar c = [text characterAtIndex:0];
        if (![[NSCharacterSet alphanumericCharacterSet] characterIsMember:c]) {
            return NO;
        }
    }
    
    return YES;
}



-(void)updateAudioPlayerPlayButton:(UIButton *)b {
    if (audioPlayer.playing) {
        [b setTitle:@"Pause" forState:UIControlStateNormal];
    } else {
        [b setTitle:@"Play" forState:UIControlStateNormal];
    }
}

-(void)userTappedAudioPlayerPlayButton:(id)sender {
    UIButton *b = (UIButton *)sender;
   
    if (audioPlayer.playing) {
        [audioPlayer pause];
    } else {
        [audioPlayer play];
    }

    [self performSelector:@selector(updateAudioPlayerPlayButton:) withObject:b afterDelay:0.25f];
}

-(void)startPlaying {
     [audioPlayer play];
}


-(void)updateAudioMeters {
    
    levelR.hidden = (audioPlayer.numberOfChannels == 1);
    
    [audioPlayer updateMeters];
    
    float averagePower1   = [audioPlayer averagePowerForChannel:0];
    float peakPower1      = [audioPlayer peakPowerForChannel:0];
    
    float averagePower2   = [audioPlayer averagePowerForChannel:1];
    float peakPower2      = [audioPlayer peakPowerForChannel:1];
    
    [self performSelectorOnMainThread:@selector(meterLevelsDidUpdate:) withObject:[NSArray arrayWithObjects:
                                                                                   [NSNumber numberWithFloat:averagePower1],
                                                                                   [NSNumber numberWithFloat:peakPower1],
                                                                                   [NSNumber numberWithFloat:averagePower2],
                                                                                   [NSNumber numberWithFloat:peakPower2],
                                                                                   nil] waitUntilDone:NO];
}

- (void)posSliderValueChanged:(id)sender {
    updatedPosition = audioPlayerSlider.value;
}

-(void)updateBarPos {
    audioPlayerSlider.value = audioPlayer.currentTime;
}

-(void)updateBarLabel {
    
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    float hundreths = 0.0;
    
    days = audioPlayer.currentTime / (24 * 60 * 60);
    
    int remain = audioPlayer.currentTime - (days * 24 * 60 * 60);
    
    hours = remain / (60 * 60);
    
    int remain2 = remain - (hours * 60 * 60);
    
    minutes = remain2 / 60;
    
    int remain3 = remain2 - (minutes * 60);
    
    seconds = remain3;
    
    hundreths = audioPlayer.currentTime - (days *24 * 60 * 60) - (hours * 60 * 60) - (minutes * 60) - (seconds) ;
    
    hours = hours + (days * 24);
    
    audioPosLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d.%d", hours, minutes,seconds, (int)(hundreths * 10.0f)];
}


-(void)meterLevelsDidUpdate:(NSArray *)levelInfo {
    float l = [[levelInfo objectAtIndex:0] floatValue];
    float r = [[levelInfo objectAtIndex:2] floatValue];
    
    [levelL updateValue:  pow (10., 0.05 * l) ];
    [levelR updateValue: pow (10., 0.05 * r)  ];
}

-(void)updateTimerEvent {
    if (updatedPosition != 0.0f) {
        [audioPlayer setCurrentTime:updatedPosition];
        [audioPlayer play];
        updatedPosition = 0.0f;
    }
    
    [self updateBarPos];
    [self updateBarLabel];
    [self updateAudioMeters];
    
    if (audioPlayerView) {
        UIView *v = [audioPlayerView viewWithTag:1337];
        UIButton *b = (UIButton *)v;
        [self updateAudioPlayerPlayButton:b];
    }
}


@end