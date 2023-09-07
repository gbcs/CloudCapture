//
//  AudioMergeSelectViewController.m
//  Capture
//
//  Created by Gary Barnett on 2/2/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AudioMergeSelectViewController.h"

#import "AudioLibraryViewController.h"
#import "AppDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "PhotoLibraryViewController.h"
#import "HelpViewController.h"
#import "AudioCaptureViewController.h"
#import "AudioEditorViewController.h"

@interface AudioMergeSelectViewController ()

@end

@implementation AudioMergeSelectViewController {
    
    NSMutableArray *selectedEntries;
    NSIndexPath *lastIP;
    IBOutlet UICollectionView *collectionViewPack;
    
    UIBarButtonItem *playButton;
    
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *closeButton;
    
    BOOL isPlaying;
    
    UIDynamicAnimator *animator;
    UIView *audioPlayerView;
    UISlider *audioPlayerSlider;
    UILabel *audioPosLabel;

    AVAudioPlayer *audioPlayer;

    
    NSTimer *audioPlayTimer;
    float updatedPosition;
    BOOL processing;
    
    AVComposition *composition;
    AVAssetExportSession *exporter;
}

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

    collectionViewPack = nil;

    playButton = nil;
    cancelButton = nil;
    closeButton = nil;
    animator = nil;
    audioPlayerView = nil;
    audioPlayerSlider = nil;
    audioPosLabel = nil;
    audioPlayer = nil;
    audioPlayTimer = nil;
    
 
    
}


-(void)reloadCollection {
    if (collectionViewPack) {
        [collectionViewPack reloadData];
    }
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
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [collectionViewPack setCollectionViewLayout:flowLayout];
    [collectionViewPack setAllowsSelection:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishShowing:) name:@"finishPlaying" object:nil];
    
    collectionViewPack.allowsMultipleSelection = NO;
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancelButton:)];
    
    self.navigationItem.leftBarButtonItem = nil;
    
    closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose:)];
    
    self.navigationItem.leftBarButtonItems = @[ cancelButton];
    self.navigationItem.rightBarButtonItems = @[ closeButton];
    self.navigationItem.title = @"Select Audio Clip";

}

-(void)userTappedHelpButton:(id)sender {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)userTappedCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    collectionViewPack.allowsMultipleSelection = YES;

    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = YES;
    self.navigationController.toolbarHidden = YES;
    
    [selectedEntries removeAllObjects];
    

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
    if ([selectedEntries indexOfObject:indexPath] != NSNotFound) {
            if ([lastIP isEqual:indexPath]) {
                [self startPlaying:YES];
                [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            } else {
                [selectedEntries removeObject:indexPath];
            }
    }
}



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([selectedEntries indexOfObject:indexPath] == NSNotFound) {
        [selectedEntries addObject:indexPath];
    }
    
    lastIP = indexPath;
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
    
    if (!lastIP) {
        return;
    }
    
    AVURLAsset *songAsset = nil;
    NSString *title = @"";
    if (lastIP.section == 0) {
        NSString *filename = [[AudioBrowser manager] entryforAppLibraryAtIndex:lastIP.item];
        NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:filename]];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
        title = filename;
    } else {
        MPMediaItem *item = [[AudioBrowser manager] entryForArtistAtIndex:lastIP.section atEntryIndex:lastIP.item];
        NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        songAsset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
        title = [item valueForProperty:MPMediaItemPropertyTitle];
    }
    
    if (!songAsset) {
        return;
    }

    [_delegate userPickedAudioURL:songAsset withTitle:title];
    [self dismissViewControllerAnimated:YES completion:nil];
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
        

        return;
    }
    
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
    

    
    audioPlayTimer  = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateTimerEvent) userInfo:nil repeats:YES];
    
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
        self.navigationItem.rightBarButtonItems = nil;
        self.view.frame = CGRectMake(0,0,768,1024);
    } else {
        self.navigationItem.rightBarButtonItems = @[ closeButton];
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
    
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAudioPlayer)];
    [audioPlayerView addGestureRecognizer:tapG];
    audioPlayerView.userInteractionEnabled = YES;

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

-(void)updateTimerEvent {
    if (updatedPosition != 0.0f) {
        [audioPlayer setCurrentTime:updatedPosition];
        [audioPlayer play];
        updatedPosition = 0.0f;
    }
    
    [self updateBarPos];
    [self updateBarLabel];

    
    if (audioPlayerView) {
        UIView *v = [audioPlayerView viewWithTag:1337];
        UIButton *b = (UIButton *)v;
        [self updateAudioPlayerPlayButton:b];
    }
}


@end