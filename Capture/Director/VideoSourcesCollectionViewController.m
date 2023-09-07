//
//  GridCollectionViewController.m
//  iArchiver
//
//  Created by Gary Barnett on 5/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "VideoSourcesCollectionViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CameraViewController.h"
#import "RemoteCamera.h"
#import "HelpViewController.h"
#import "RemoteLibraryViewController.h"

@interface VideoSourcesCollectionViewController () {
    NSArray *sourcesList;
    
    NSInteger lastTapRow;
    
    NSDateFormatter *dateFormatter;
    
    BOOL waitingForConnection;
    NSString *connectingToID;
    BOOL firstStartupComplete;
    BOOL showingFirstStartup;
    UIDynamicAnimator *animator;
    UIView *detailView;
    BOOL returningFromPreviousConnection;
    BOOL pausePreviewUpdate;
    NSInteger waitingOnPreviewResponse;
    NSTimer *previewUpdateTimer;
    NSMutableArray *previewUpdateList;
    NSIndexPath *currentEditIndexPath;
    NSDictionary *lastPeerList;
    NSMutableArray *selectedItemList;
}

@end

@implementation VideoSourcesCollectionViewController

@synthesize collectionViewPack;

static NSString * const kCellReuseIdentifier = @"videoSourcesCollectionViewCell";

-(void)startAnimatorForDetailView {
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView ] ];
    CGFloat y = self.view.frame.size.height - 50;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = self.view.frame.size.height - 300;
    }
    
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, y) toPoint:CGPointMake(self.view.frame.size.width, y)];
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
}

-(void)closeDetailView {
    if (animator && detailView) {
        [animator removeAllBehaviors];
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
        [animator addBehavior:gravity];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:1.5];
            dispatch_async(dispatch_get_main_queue(), ^{
                [animator removeAllBehaviors];
                animator = nil;
                [detailView removeFromSuperview];
                detailView = nil;
                showingFirstStartup = NO;
            });
        });

    }
}


-(void)showNoCamerasFoundAtStartupView {
    if (animator) {
        [self closeDetailView];
        return;
    }
    
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200, -200, 400, 200)];
    detailView.backgroundColor = [UIColor whiteColor];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:detailView.bounds];
    detailView.layer.shadowColor = [UIColor blackColor].CGColor;
    [detailView.layer setShadowOpacity:0.8];
    [detailView.layer setShadowRadius:2.0];
    [detailView.layer setShadowOffset:CGSizeMake(4.0, 4.0)];
    detailView.layer.masksToBounds = NO;
    detailView.layer.shadowPath = shadowPath.CGPath;

    
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,50,400,100)];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor blackColor];
    l.numberOfLines = 0;
    l.textAlignment = NSTextAlignmentCenter;
    l.lineBreakMode = NSLineBreakByWordWrapping;
    l.text = @"Waiting for a device running Cloud Capture to appear.";
    [detailView addSubview:l];
    
    [self.view addSubview:detailView];
    
    [self startAnimatorForDetailView];
}


-(void)userDidTapHelpButton {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)closeAbout:(UIGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self closeDetailView];
    }
}


-(void)showFullscreenCameraViewForID:(NSNotification *)n {
    NSString *ID = (NSString *)n.object;
    CameraViewController *vc = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
    vc.cameraID = ID;
    collectionViewPack.alpha = 0.0f;
    returningFromPreviousConnection = YES;
    pausePreviewUpdate = YES;
    [self.navigationController pushViewController:vc animated:YES];
}



-(void)shutdown:(NSNotification *)n {
    /*
    BOOL hasConnections = NO;
    NSArray *list = [[RemoteBrowserManager manager] connectedCameraList];
    for (RemoteCamera *camera in list) {
        if (camera.connected) {
            hasConnections = YES;
            break;
        }
    }
    */
    [[RemoteBrowserManager manager] endSession];
}

- (void)viewDidLoad
{
    selectedItemList = [@[ ] mutableCopy];
    self.navigationController.toolbarHidden = YES;
    self.navigationItem.title = @"Camera Director";
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
    

    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userDidTapHelpButton)];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shutdown:) name:@"directorShutdown" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerListChanged:) name:@"peerListChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerConnectedWithID:) name:@"peerConnectedWithID" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFullscreenCameraViewForID:) name:@"showFullscreenCameraViewForID" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewDataForID:) name:@"previewDataForID" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusDict:) name:@"statusDict" object:nil];
    
    [self.collectionViewPack registerNib:[UINib nibWithNibName:@"VideoSourcesCollectionViewItem" bundle:nil] forCellWithReuseIdentifier:kCellReuseIdentifier];
    
    [self.collectionViewPack registerNib:[UINib nibWithNibName:@"VideoSourcesCollectionHeaderViewItem" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    
    [super viewDidLoad];

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    [flowLayout setItemSize:CGSizeMake(230, 215)];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    } else {
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    }
    
    [self.collectionViewPack setCollectionViewLayout:flowLayout];
    [self.collectionViewPack setAllowsSelection:YES];
    self.collectionViewPack.delegate=self;
    
    self.collectionViewPack.allowsMultipleSelection = YES;
}

-(void)previewDataForID:(NSNotification *)n {
    waitingOnPreviewResponse = NO;
}

-(void)statusDict:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSString *ID = [[args objectAtIndex:0] copy];
    NSDictionary *status = [[args objectAtIndex:1] copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL recording = [[status objectForKey:@"r"] boolValue];
        NSIndexPath *ip = [NSIndexPath indexPathForItem:[[VideoSourceManager manager] indexOfSourceWithID:ID] inSection:0];
        UICollectionViewCell *cell = [self.collectionViewPack cellForItemAtIndexPath:ip];
        cell.backgroundColor = recording ? [UIColor redColor] : [UIColor colorWithWhite:0.8 alpha:1.0];
    });
}


-(void)peerConnectedWithID:(NSNotification *)n {
    NSString *ID = (NSString *)n.object;
    waitingForConnection = NO;
    NSLog(@"connected to:%@", ID);
    NSIndexPath *ip = [NSIndexPath indexPathForItem:[[VideoSourceManager manager] indexOfSourceWithID:ID] inSection:0];
    [self.collectionViewPack reloadItemsAtIndexPaths:@[ ip ]];
    if ([selectedItemList indexOfObject:ip] == NSNotFound) {
        [selectedItemList addObject:ip];
    }
    [self.collectionViewPack selectItemAtIndexPath:ip animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

-(void)cleanupDetailView {
    [animator removeAllBehaviors];
    animator = nil;
    [detailView removeFromSuperview];
    detailView = nil;
}

-(void)showEditView {
    
}

-(void)peerListChanged:(NSNotification *)n {
    
    
    [self.collectionViewPack reloadData];
    
    for (NSIndexPath *path in selectedItemList) {
        [self.collectionViewPack selectItemAtIndexPath:path animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    
    if (showingFirstStartup) {
        [self closeDetailView];
    } else if (detailView.tag == -100) {
        [self closeDetailView];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[VideoSourceManager manager] sourceCount];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {

    CGSize s = CGSizeZero;
   
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        s = CGSizeMake(self.view.frame.size.width,45);
    }
    
    return s;
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    lastTapRow = -1;
    collectionViewPack.alpha = 0.0f;
    self.navigationController.toolbarHidden = YES;
}

-(void)previewUpdateTimerEvent {
    if (pausePreviewUpdate) {
        return;
    }
    
    if ([self.navigationController.viewControllers lastObject] != self) {
        return;
    }
    
    if (waitingOnPreviewResponse >0) {
        waitingOnPreviewResponse++;
        if (waitingOnPreviewResponse > 50) {
            NSLog(@"Stopped waiting on preview update");
            waitingOnPreviewResponse = 0;
        } else {
            return;
        }
    }
    
    if ([previewUpdateList count] <1) {
        previewUpdateList = [[RemoteBrowserManager manager] connectedCameraList];
    }
    
    if ([previewUpdateList count]>0) {
        waitingOnPreviewResponse = 1;
        RemoteCamera *camera = [previewUpdateList objectAtIndex:0];
        [previewUpdateList removeObjectAtIndex:0];
        NSDictionary *cmdDict = @{ @"cmd" : @"prv" };
        [camera sendMessage:[NSJSONSerialization dataWithJSONObject:cmdDict options:NSJSONWritingPrettyPrinted error:nil]];
    } else {
        waitingOnPreviewResponse = 0;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    previewUpdateTimer = nil;
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    lastTapRow = -1;
    collectionViewPack.alpha = 1.0f;
    
    if ((!firstStartupComplete) && ([[VideoSourceManager manager] sourceCount] < 1) ) {
        showingFirstStartup = YES;
        [self showNoCamerasFoundAtStartupView];
    }
    pausePreviewUpdate = NO;
    firstStartupComplete = YES;
   
    previewUpdateList = [@[ ] mutableCopy];
    previewUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(previewUpdateTimerEvent) userInfo:nil repeats:YES];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *headerView = nil;
   
    
    headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[headerView viewWithTag:100];
    
    titleLabel.textColor = [UIColor blackColor];
    [titleLabel  setTextAlignment:NSTextAlignmentCenter];
    
    titleLabel.layer.cornerRadius = 15.0f;
    titleLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    titleLabel.text = @"Cloud Capture Cameras";
    
    return headerView;
}


- (NSString *)timeAgoFromDateStr:(NSString *)dateStr {
    NSDate *date = [dateFormatter dateFromString:dateStr];
    
    double seconds = [date timeIntervalSince1970];
    
    if (seconds < 30) {
        return @"Just Now";
    }
    
    double difference = [[NSDate date] timeIntervalSince1970] - seconds;
    NSMutableArray *periods = [NSMutableArray arrayWithObjects:@"second", @"minute", @"hour", @"day", @"week", @"month", @"year", @"decade", nil];
    NSArray *lengths = [NSArray arrayWithObjects:@60, @60, @24, @7, @4.35, @12, @10, nil];
    NSInteger j = 0;
    for(j=0; difference >= [[lengths objectAtIndex:j] doubleValue]; j++)
    {
        difference /= [[lengths objectAtIndex:j] doubleValue];
    }
    difference = roundl(difference);
    if(difference != 1)
    {
        [periods insertObject:[[periods objectAtIndex:j] stringByAppendingString:@"s"] atIndex:j];
    }
    return [NSString stringWithFormat:@"%li %@%@", (long)difference, [periods objectAtIndex:j], @" ago"];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
   
    cell.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
    bgImage.backgroundColor = [UIColor colorWithRed:0.0 green:0.3 blue:0.0 alpha:0.7];
    cell.selectedBackgroundView = bgImage;
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    VideoThumbImageView *imageView = (VideoThumbImageView *)[cell viewWithTag:101];
    imageView.backgroundColor = [UIColor whiteColor];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:imageView.bounds];
    imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    [imageView.layer setShadowOpacity:0.8];
    [imageView.layer setShadowRadius:2.0];
    [imageView.layer setShadowOffset:CGSizeMake(3.0, 3.0)];
    imageView.layer.shadowPath = shadowPath.CGPath;
    shadowPath = [UIBezierPath bezierPathWithRect:cell.bounds];
    cell.layer.shadowColor = [UIColor blackColor].CGColor;
    [cell.layer setShadowOpacity:0.8];
    [cell.layer setShadowRadius:2.0];
    [cell.layer setShadowOffset:CGSizeMake(4.0, 4.0)];
    cell.layer.masksToBounds = NO;
    cell.layer.shadowPath = shadowPath.CGPath;
    
    ConnectionButtonWIthID *connectButton = (ConnectionButtonWIthID *)[cell viewWithTag:102];
    
    NSDictionary *sourceInfoDict = [[VideoSourceManager manager] infoDictForSourceAtIndex:indexPath.row];
    
    titleLabel.text = [sourceInfoDict objectForKey:@"name"];
    NSString *ID = [sourceInfoDict objectForKey:@"id"];
    NSDate *lastConnected = [sourceInfoDict objectForKey:@"lastSeen"];
    
    UILabel *connectionLabel = (UILabel *)[cell viewWithTag:105];
   
    imageView.ID = ID;
    [imageView listen];
    
    connectButton.ID = ID;
    [connectButton listen];
    
    NSLog(@"Using %@:%@ for %@", [[RemoteBrowserManager manager] peerForID:ID], ID, indexPath);
    
    imageView.image = nil;
    NSData *imageData = [sourceInfoDict objectForKey:@"thumb"];
    if (imageData) {
        UIImage *thumbImage = [UIImage imageWithData:imageData];
        if (thumbImage) {
            imageView.image = thumbImage;
        }
    }
    
    if ([[RemoteBrowserManager manager] isIDConnected:ID]) {
        connectionLabel.text = @"";
        [connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        connectButton.enabled = YES;
    } else if ([[RemoteBrowserManager manager] peerForID:ID]) {
        connectionLabel.text = @"Online";
        [connectButton setTitle:@"Connect" forState:UIControlStateNormal];
        connectButton.enabled = YES;
    } else if (lastConnected) {
        connectionLabel.text = [NSString stringWithFormat:@"Last seen %@", [self timeAgoFromDateStr:[dateFormatter stringFromDate:lastConnected]]];
        [connectButton setTitle:@"Offline" forState:UIControlStateNormal];
        connectButton.enabled = NO;
    } else {
        connectionLabel.text = @"Never Connected";
        [connectButton setTitle:@"Offline" forState:UIControlStateNormal];
        connectButton.enabled = NO;
    }
    
    ButtonWithSourceID *editButton = (ButtonWithSourceID *)[cell viewWithTag:103];
    [editButton addTarget:self action:@selector(userTappedCellEditButton:) forControlEvents:UIControlEventTouchUpInside];
    editButton.ID = ID;
    
    ButtonWithSourceID *fsButton = (ButtonWithSourceID *)[cell viewWithTag:104];
    [fsButton addTarget:self action:@selector(userTappedCellFullScreenButton:) forControlEvents:UIControlEventTouchUpInside];
    fsButton.ID = ID;
    
    return cell;
}

-(void)userTappedCellEditButton:(id)sender {
    if (detailView) {
        return;
    }
    
    ButtonWithSourceID *button = (ButtonWithSourceID *)sender;
    NSLog(@"EditCellButton:%@", button.ID);
    
    connectingToID = button.ID;
    
    [self promptForCredentials];
    
}

-(void)userTappedCellFullScreenButton:(id)sender {
    ButtonWithSourceID *button = (ButtonWithSourceID *)sender;
    NSLog(@"FSCellButton:%@", button.ID);
    
    connectingToID = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showFullscreenCameraViewForID" object:button.ID userInfo:nil];
    
    
}

#pragma mark - delegate methods


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (indexPath && ([selectedItemList indexOfObject:indexPath] != NSNotFound)) {
        [selectedItemList removeObject:indexPath];
    }
    
    if ([selectedItemList count] >0) {
        NSIndexPath *lastItem = [selectedItemList lastObject];
        lastTapRow = lastItem.item;
    }
}

-(void)promptForCredentials {
    [NSThread sleepForTimeInterval:0.25];
    if (animator) {
        [self closeDetailView];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:2.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self promptForCredentials];
            });
        });
        return;
    }
    
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200, -200, 400, 200)];
    detailView.backgroundColor = [UIColor lightGrayColor];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:detailView.bounds];
    detailView.layer.shadowColor = [UIColor blackColor].CGColor;
    [detailView.layer setShadowOpacity:0.8];
    [detailView.layer setShadowRadius:2.0];
    [detailView.layer setShadowOffset:CGSizeMake(4.0, 4.0)];
    detailView.layer.masksToBounds = NO;
    detailView.layer.shadowPath = shadowPath.CGPath;
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,400,40)];
    l.textAlignment = NSTextAlignmentCenter;
    l.textColor = [UIColor blackColor];
    l.backgroundColor = [UIColor whiteColor];
    
    MCPeerID *peer = [[RemoteBrowserManager manager] peerForID:connectingToID];
    
    l.text = [NSString stringWithFormat:@"Password for %@", peer.displayName];
    [detailView addSubview:l];
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(0,50,400,30)];
    tf.backgroundColor = [UIColor whiteColor];
    tf.secureTextEntry = YES;
    [detailView addSubview:tf];
    
    [self.view addSubview:detailView];
    
    [self startAnimatorForDetailView];

    [tf performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0f];
    tf.delegate = self;
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,60,40)];
    [cancelButton setTintColor:[UIColor blueColor]];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(userTappedCancelCredential) forControlEvents:UIControlEventTouchUpInside];
    [detailView insertSubview:cancelButton aboveSubview:l];
     
    
    UIButton *loginButton = [[UIButton alloc] initWithFrame:CGRectMake(340,0,60,40)];
    [loginButton setTintColor:[UIColor blueColor]];
    [loginButton setTitle:@"Update" forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(userTappedUpdateWithCredential) forControlEvents:UIControlEventTouchUpInside];
    [detailView insertSubview:loginButton aboveSubview:l];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text length] > 0) {
        [[VideoSourceManager manager] updatePassword:[textField.text dataUsingEncoding:NSStringEncodingConversionAllowLossy] forSourceWithID:connectingToID];
        [self userTappedUpdateWithCredential];
    } else {
        [self userTappedCancelCredential];
    }
}


-(void)userTappedCancelCredential {
    
    for (NSObject *v in detailView.subviews) {
        if ([v isKindOfClass:[UITextField class]]) {
            UITextField *f = (UITextField *)v;
            [f resignFirstResponder];
            break;
        }
    }
    
    connectingToID = NO;
    waitingForConnection = NO;
    lastTapRow = -1;
    [self closeDetailView];
}

-(void)userTappedUpdateWithCredential {
    for (NSObject *v in detailView.subviews) {
        if ([v isKindOfClass:[UITextField class]]) {
            UITextField *f = (UITextField *)v;
            if ([f.text length] > 0) {
                [[VideoSourceManager manager] updatePassword:[f.text dataUsingEncoding:NSStringEncodingConversionAllowLossy] forSourceWithID:connectingToID];
                [f resignFirstResponder];
            }
            break;
        }
    }
    
    [self closeDetailView];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger curRow = indexPath.row;
    
    if (indexPath && ([selectedItemList indexOfObject:indexPath] == NSNotFound)) {
        [selectedItemList addObject:indexPath];
    }
    
    lastTapRow = curRow;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)userTappedTrash:(id)sender {
    if (lastTapRow < 0) {
        return;
    }
    
    [[VideoSourceManager manager] removeSourceAtIndex:lastTapRow];
    lastTapRow = -1;
    [self.collectionViewPack deleteItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:lastTapRow inSection:0]]];
}

- (IBAction)userTappedLibrary:(id)sender {
    if ([selectedItemList count]<1) {
        return;
    }
    
    NSIndexPath *ip = [selectedItemList lastObject];
    NSDictionary *infoDict = [[VideoSourceManager manager] infoDictForSourceAtIndex:ip.item];
    NSString *sourceID = [infoDict objectForKey:@"id"];
    
    if (!sourceID) {
        return;
    }
    
    RemoteLibraryViewController *vc = [[RemoteLibraryViewController alloc] initWithNibName:@"RemoteLibraryViewController" bundle:nil];
    vc.remoteID = sourceID;
    [self.navigationController pushViewController:vc animated:YES];
}


-(NSArray *)listOfSelectedSourceIDs {
    NSMutableArray *list = [@[ ] mutableCopy];
    for (NSIndexPath *ip in selectedItemList) {
        NSString *cameraID = [[[VideoSourceManager manager] infoDictForSourceAtIndex:ip.item] objectForKey:@"id"];
        if (cameraID) {
            [list addObject:cameraID];
        }
    }
    return [list copy];
}

- (IBAction)userTappedPictureButton:(id)sender {
    NSArray *list = [self listOfSelectedSourceIDs];
    NSData *cmd = [NSJSONSerialization dataWithJSONObject:@{ @"cmd" : @"picture" } options:NSJSONWritingPrettyPrinted error:nil];
    if ([list count]>0) {
        [[RemoteBrowserManager manager] sendMessage:cmd toIDList:list];
    }
}

- (IBAction)userTappedStop:(id)sender {
    NSArray *list = [self listOfSelectedSourceIDs];
    NSData *cmd = [NSJSONSerialization dataWithJSONObject:@{ @"cmd" : @"stop" } options:NSJSONWritingPrettyPrinted error:nil];
    if ([list count]>0) {
        [[RemoteBrowserManager manager] sendMessage:cmd toIDList:list];
    }
}

- (IBAction)userTappedStart:(id)sender {
    NSArray *list = [self listOfSelectedSourceIDs];
    NSData *cmd = [NSJSONSerialization dataWithJSONObject:@{ @"cmd" : @"start" } options:NSJSONWritingPrettyPrinted error:nil];
    if ([list count]>0) {
        [[RemoteBrowserManager manager] sendMessage:cmd toIDList:list];
    }
}


@end