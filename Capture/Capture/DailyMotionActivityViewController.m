//
//  DailyMotionActivityViewController.m
//  Capture
//
//  Created by Gary Barnett on 1/14/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "DailyMotionActivityViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface DailyMotionActivityViewController ()
@end

@implementation DailyMotionActivityViewController {
    __strong UIViewController *loginController;
    
    __weak IBOutlet UITableView *tv;
    
    NSString *title;
    NSString *description;
    NSString *tags;
    NSString *channel;
    NSArray *channelList;
    
    UIDynamicAnimator *detailAnimator;
    UIView *detailView;


    BOOL uploading;
    UIProgressView *uploadProgress;
    UILabel *uploadProgressLabel;
   
    NSURL *_uploadLocationURL;
    NSString *tmpFilePath;
    ALAssetsLibrary *assetLibrary;
    
    __strong id me;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *uploadButton;
    UIBarButtonItem *logoutButton;
    DMAPITransfer *transfer;
    BOOL presenting;
    BOOL private;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
   
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    uploadButton = nil;
    cancelButton  = nil;
    logoutButton = nil;
    tv = nil;
    title = nil;
    description = nil;
    tags = nil;
    channel = nil;
    channelList = nil;
    detailAnimator = nil;
    detailView = nil;
    me = nil;
    uploadButton = nil;
    uploadProgress = nil;
    uploadProgressLabel = nil;
    _uploadLocationURL = nil;
    tmpFilePath = nil;
    assetLibrary = nil;
    loginController = nil;
    me = nil;
    transfer = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
            // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setToolbarHidden:YES];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel:)];
    
    logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedLogout:)];
    logoutButton.enabled = NO;
    
    uploadButton = [[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedUpload:)];
    uploadButton.enabled = NO;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.leftBarButtonItems =  @[ cancelButton, logoutButton ];
    
    self.navigationItem.rightBarButtonItem = uploadButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(handleApplicationBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(youtubeUploadProgress:) name:@"dailyMotionUploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(youtubeUploadStatusUpdate:) name:@"dailyMotionUploadStatusUpdate" object:nil];
    
    assetLibrary = [[ALAssetsLibrary alloc] init];
    
    tags = [[SettingsTool settings] dailyMotionTags];
    
    DMAPI *api = [DMAPI sharedAPI];

    [api.oauth setGrantType:DailymotionGrantTypeAuthorization withAPIKey:@"dfb7a8b3ef22cb2c038e" secret:@"30b660ef86adc0c04b46d3bb9a6bcf808a012f29" scope:@"manage_videos read"];
    api.oauth.delegate = self;
    api.oauth.autoSaveSession = YES;
    [api.oauth readSession];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURL *url = [NSURL URLWithString:@"https://api.dailymotion.com/channels"];
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        if ( (!error) && data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (dict) {
                NSDictionary *list = [dict objectForKey:@"list"];
                NSMutableArray *cList = [[NSMutableArray alloc] initWithCapacity:[list count]];
                for (NSDictionary *cDict in list) {
                    [cList addObject:@[ [cDict objectForKey:@"id"], [cDict objectForKey:@"name"] ] ];
                }
                channelList = [cList copy];
                channel = [[SettingsTool settings] dailyMotionChannel];
                NSLog(@"channelList contains %lu items", (unsigned long)[channelList count]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [tv reloadData];
                });
            }
        }
    });
}

-(void)userTappedLogout:(id)sender {
    if (loginController) {
        [loginController.view removeFromSuperview];
        loginController.view = nil;
        loginController = nil;
    }
    me = nil;
    DMAPI *api = [DMAPI sharedAPI];
    [api logout];
    
    [self performSelector:@selector(finishNotUploaded) withObject:nil afterDelay:2.0f];
   
}

-(void)cleanup {
    loginController = nil;
    tv = nil;
    title = nil;
    description = nil;
    tags = nil;
    channel = nil;
    channelList = nil;
    detailAnimator = nil;
    detailView = nil;
    uploadProgress = nil;
    uploadProgressLabel = nil;
    _uploadLocationURL = nil;
    tmpFilePath = nil;
    assetLibrary = nil;
    me = nil;
    cancelButton = nil;
    uploadButton = nil;
    logoutButton = nil;
    transfer = nil;
}

-(void)finishNotUploaded {
    [self.delegate dailyMotionDidFinish:NO];
    [self cleanup];
}

-(void)finishUploaded {
    [self.delegate dailyMotionDidFinish:YES];
    [self cleanup];
}


-(void)dailyMotionUploadProgress:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSNumber *progress = [args objectAtIndex:0];
    NSString *msg = [args objectAtIndex:1];
    uploadProgress.progress = [progress floatValue];
    uploadProgressLabel.text = msg;
    uploadProgressLabel.textColor = [UIColor whiteColor];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUploadButtonStatus];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}



- (void)handleApplicationBecameActive:(NSNotification *)notification
{
    
}

- (IBAction)userTappedUpload:(id)sender {
    [[SettingsTool settings] setDailyMotionTags:tags];
    [[SettingsTool settings] setDailyMotionChannel:channel];
    
    uploading = YES;
    [tv reloadData];
    
    [self uploadVideoFile];
}

- (IBAction)userTappedCancel:(id)sender {
    if (tmpFilePath) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:&error];
        tmpFilePath = nil;
    }
    
    self.activityItems = nil;
    [self finishNotUploaded];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 2) {
        NSArray *selectecChannel = [channelList  objectAtIndex:indexPath.row];
        [[SettingsTool settings] setDailyMotionChannel:[selectecChannel objectAtIndex:0]];
        channel = [selectecChannel objectAtIndex:0];
        [self userPressedGradientAttributedButtonWithTag:0];
        return;
    }
    
    if (detailView) {
        [self finishDetailPage];
    }
    
    CGFloat width = self.view.frame.size.height;
    CGFloat height = self.view.frame.size.width;
    
    if (width < height) {
        CGFloat t = width;
        width = height;
        height = t;
    }
    
    if (height > 320) {
        if (width < height) {
            height = self.view.frame.size.width - 300;
        } else {
            height = self.view.frame.size.height - 300;
        }
    } else {
        height -= 50;
    }
    
    
    
    detailView = [[UIView alloc] initWithFrame:CGRectMake((width / 2.0f) - 230, -240,460,230)];
    detailView.backgroundColor = [UIColor lightGrayColor];
    detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView ] ];
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,height) toPoint:CGPointMake(width,height)];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,460,44)];
    l.backgroundColor = [UIColor darkGrayColor];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    [detailView addSubview:l];
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(460 - 80, 0, 80, 44)];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    button.delegate = self;
    button.tag = indexPath.row;
    
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment:NSTextAlignmentCenter];
	
    
    [button setTitle:[[NSAttributedString alloc] initWithString:@"Done" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                         NSShadowAttributeName : shadow,
                                                                                         NSParagraphStyleAttributeName : style,
                                                                                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                         }] disabledTitle:nil beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    button.enabled = YES;
    [button update];
    [detailView addSubview:button];
    
    switch (indexPath.row) {
        case 0:
        {
            l.text = @"Enter Title";
            
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,60,440,44)];
            textField.backgroundColor = [UIColor whiteColor];
            textField.delegate = self;
            textField.tag = indexPath.row;
            textField.text = title;
            [detailView addSubview:textField];
            [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];
        }
            break;
        case 1:
        {
            l.text = @"Enter Description";
            UITextView *textField = [[UITextView alloc] initWithFrame:CGRectMake(10,44,440,88)];
            textField.backgroundColor = [UIColor whiteColor];
            textField.delegate = self;
            textField.tag = indexPath.row;
            textField.text = description;
            [detailView addSubview:textField];
            [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];
        }
            break;
        case 2:
        {
            
            l.text = @"Enter Tags";
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,60,440,44)];
            textField.backgroundColor = [UIColor whiteColor];
            textField.delegate = self;
            textField.tag = indexPath.row;
            textField.text = tags;
            [detailView addSubview:textField];
            [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];
        }
            break;
        case 3:
        {
            l.text = @"Choose Channel";
            UITableView *catTV = [[UITableView alloc] initWithFrame:CGRectMake(2,44,456,230 - 46) style:UITableViewStylePlain];
            catTV.delegate = self;
            catTV.dataSource = self;
            catTV.tag = 2;
            [detailView addSubview:catTV];
        }
            break;
    }
    
    [self.view addSubview:detailView];
    [detailAnimator addBehavior:collision];
    [detailAnimator addBehavior:gravity];
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    
    if (!detailView) {
        return;
    }
    
    for (UIView *d in detailView.subviews) {
        if ([[UITextField class] isEqual:[d class]]) {
            UITextField *t = (UITextField *)d;
            [t resignFirstResponder];
            break;
        } else if ([[UITextView class] isEqual:[d class]]) {
            UITextView *t = (UITextView *)d;
            [t resignFirstResponder];
            break;
        }
    }
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [detailAnimator removeAllBehaviors];
    [detailAnimator addBehavior:gravity];
    [self performSelector:@selector(finishDetailPage) withObject:nil afterDelay:1.0];
    [self updateUploadButtonStatus];
    
    [tv reloadData];
}

-(void)updateUploadButtonStatus {
    if (title && ([title length]>0) && channel && ([channel length] > 0)) {
        uploadButton.enabled = YES;
    } else {
        uploadButton.enabled = NO;
    }
    
    logoutButton.enabled = (me != nil);
}

-(void)finishDetailPage {
    [detailAnimator removeAllBehaviors];
    detailAnimator = nil;
    [detailView removeFromSuperview];
    detailView = nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 2) {
        return 0;
    }
    
    if (!uploading) {
        return 0;
    }
    
    return 60.0f;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 2) {
        return nil;
    }
    
    if (!uploading) {
        return nil;
    }
    
    CGFloat width = self.view.frame.size.height;
    CGFloat height = self.view.frame.size.width;
    
    if (width < height) {
        width = height;
    }
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,width, 60)];
    v.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#333333"];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,width,30)];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Uploading";
    
    uploadProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    uploadProgress.frame = CGRectMake(0,40,width,4);
    
    uploadProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,45,width,13)];
    uploadProgressLabel.textColor = [UIColor whiteColor];
    uploadProgressLabel.textAlignment = NSTextAlignmentCenter;
    uploadProgressLabel.text = @"";
    
    [v addSubview:l];
    [v addSubview:uploadProgress];
    [v addSubview:uploadProgressLabel];
    
    uploadProgress.progress = 0.01;
    
    return v;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 2) {
        return [channelList count];
    }
	return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (tableView.tag == 2) {
        NSArray *item =[channelList objectAtIndex:indexPath.row];
        cell.textLabel.text = [item objectAtIndex:1];
        return cell;
    }
    
    
    switch ( indexPath.row) {
        case 0:
            cell.textLabel.text = @"Title";
            cell.detailTextLabel.text = title;
            break;
        case 1:
            cell.textLabel.text = @"Description";
            cell.detailTextLabel.text = description;
            break;
        case 2:
            cell.textLabel.text = @"Tags";
            cell.detailTextLabel.text = tags;
            break;
        case 3:
            cell.textLabel.text = @"Channel";
            for (NSArray *a in channelList) {
                if ([[a objectAtIndex:0] isEqualToString:channel]) {
                    cell.detailTextLabel.text = [a objectAtIndex:1];
                }
            }
            break;
        case 4:
        {
            cell.textLabel.text = @"Public";
            UISwitch *sw1 = [[UISwitch alloc] init];
            [sw1 addTarget:self action:@selector(publicSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            [sw1 setOn:[[SettingsTool settings] dailyMotionPublicSwitch]];
            cell.accessoryView = sw1;
        }
            break;
    }
    
    return cell;
}

-(void)publicSwitchChanged:(id)sender {
    UISwitch *sw1 = (UISwitch *)sender;
    
    [[SettingsTool settings] setDailyMotionPublicSwitch:@(sw1.isOn)];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *textStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    switch (textField.tag) {
        case 0:
            title = textStr;
            break;
        case 2:
            tags = textStr;
            break;
    }
    return YES;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    description = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return YES;
}


#pragma mark - Upload




-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
 
    DMAPI *api = [DMAPI sharedAPI];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [api get:@"/me" callback:^(id result, DMAPICacheInfo *cacheInfo, NSError *error)
                 {
                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                         [NSThread sleepForTimeInterval:1.0];
                         dispatch_async(dispatch_get_main_queue(), ^{
                             me = result;
                             [self updateUploadButtonStatus];
                             [tv reloadData];
                             
                         });
                     });
                 }];
        });
    });
}

- (void)dailymotionOAuthRequest:(DMOAuthClient *)request createModalDialogWithView:(UIView *)view {
    if(presenting) {
        NSLog(@"present while already presenting");
        return;
    }
    presenting = YES;
    
    if (loginController) {
        [loginController.view removeFromSuperview];
        loginController = nil;
    }
    
    loginController = [[UIViewController alloc] init];
    
    loginController.view = view;
    [self presentViewController:loginController animated:YES completion:^{
        presenting = NO;
    }];
}

- (void)dailymotionOAuthRequestCloseModalDialog:(DMOAuthClient *)request {
    while (presenting) {
        [NSThread sleepForTimeInterval:1.0f];
    }
    
    [loginController dismissViewControllerAnimated:YES completion:^{
        loginController.view = nil;
        loginController = nil;
    }];
}

-(void)uploadVideoFile {
    NSURL *url = [self.activityItems objectAtIndex:0];
    transfer = [[DMAPI sharedAPI] uploadFileURL:url withCompletionHandler:^(id result, NSError *error)
                                        {
                                            [self doneWithResult:result error:error];
                                        }];
    
    __weak DailyMotionActivityViewController* weakSelf = self;
    
   [transfer setProgressHandler:^(NSInteger a, NSInteger b, NSInteger c) {
       [weakSelf updateProgress:(float)((float)b / (float)c)];
   }];
}

-(void)updateProgress:(CGFloat)f {
    uploadProgress.progress = f;
}

- (void)doneWithResult:(NSURL *)url error:(NSError *)error {
    NSLog(@"Done:%@:%@", url, [error localizedDescription]);
    if (!error) {
        uploadProgressLabel.text = @"Posting";
        [self updateProgress:1.0f];
        [self postVideoInfo:url];
    } else {
        [self finishNotUploaded];
    }
}

- (void)postVideoInfo:(NSURL *)url {
    NSDictionary *args = NSMutableDictionary.dictionary;
    [args setValue:title forKey:@"title"];
    [args setValue:description forKey:@"description"];
    [args setValue:channel forKey:@"channel"];
    [args setValue:tags forKey:@"tags"];
    [args setValue:url.absoluteString forKey:@"url"];
    [args setValue:@(YES) forKey:@"published"];
    
    BOOL isPrivate = NO;
    if (![[SettingsTool settings] dailyMotionPublicSwitch]) {
        isPrivate = YES;
    }
    
    [args setValue:@(isPrivate) forKey:@"private"];
    
    [[DMAPI sharedAPI] post:@"/me/videos" args:args callback:^(id result, DMAPICacheInfo *cacheInfo, NSError *error) {
        uploadProgressLabel.text = @"Complete";
        NSLog(@"posted:%@:%@", result, [error localizedDescription]);
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://dai.ly/%@", [result objectForKey:@"id"]]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUploadedURLAndDict" object:@[
                                                                                                        url,
                                                                                                        @{@"title" : title, @"description" : description }
                                                                                                        ] ];

        error ? [self finishNotUploaded] : [self finishUploaded];
    }];
}

@end
