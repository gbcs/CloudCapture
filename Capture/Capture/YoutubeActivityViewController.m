//
//  YoutubeActivityViewController.m
//  Capture
//
//  Created by Gary Barnett on 11/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "YoutubeActivityViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "GTMHTTPUploadFetcher.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface YoutubeActivityViewController ()

@end

@implementation YoutubeActivityViewController {
    
    __weak IBOutlet UITableView *tv;
    
    NSString *title;
    NSString *description;
    NSString *tags;
    NSInteger privacy;
    NSString *category;
    NSString *categoryStr;
    NSArray *categoryList;
    
    UIDynamicAnimator *detailAnimator;
    UIView *detailView;
    
    NSString *keychainName;
    GTMOAuth2Authentication *authToken;
    BOOL uploading;
    UIProgressView *uploadProgress;
    UILabel *uploadProgressLabel;
    GTLServiceTicket *_uploadFileTicket;
    NSURL *_uploadLocationURL;
    NSString *tmpFilePath;
    ALAssetsLibrary *assetLibrary;
    
    
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *uploadButton;
    UIBarButtonItem *logoutButton;
    
}

- (void)dealloc
{//NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    uploadButton = nil;
    cancelButton  = nil;
    logoutButton = nil;
    
    tv = nil;
    
    title = nil;
    description = nil;
    tags = nil;
    
    category = nil;
    categoryStr = nil;
    categoryList = nil;
    
    detailAnimator = nil;
    detailView = nil;
    
    keychainName = nil;
    uploadButton = nil;
    authToken = nil;
    
    uploadProgress = nil;
    uploadProgressLabel = nil;
    _uploadFileTicket = nil;
    _uploadLocationURL = nil;
    tmpFilePath = nil;
    assetLibrary = nil;
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
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(youtubeUploadProgress:) name:@"youtubeUploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(youtubeUploadStatusUpdate:) name:@"youtubeUploadStatusUpdate" object:nil];
    
    assetLibrary = [[ALAssetsLibrary alloc] init];
    
    tags = [[SettingsTool settings] youtubeTags];
    category = [[SettingsTool settings] youtubeCategory];
    keychainName = @"youtubeLogin";
}

-(void)youtubeUploadProgress:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSNumber *progress = [args objectAtIndex:0];
     NSString *msg = [args objectAtIndex:1];
    uploadProgress.progress = [progress floatValue];
    uploadProgressLabel.text = msg;
    uploadProgressLabel.textColor = [UIColor whiteColor];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidUnload];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUploadButtonStatus];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self youtubeSignIn];
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
    [[SettingsTool settings] setYoutubeTags:tags];
    [[SettingsTool settings] setYoutubeCategory:category];
    
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
    [self.delegate youTubeDidFinish:YES];
}

- (IBAction)userTappedLogout:(id)sender {
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:keychainName];
    [self userTappedCancel:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 2) {
        category = [[categoryList objectAtIndex:indexPath.row] objectAtIndex:1];
        categoryStr = [[categoryList objectAtIndex:indexPath.row] objectAtIndex:0];
        [[SettingsTool settings] setYoutubeCategory:category];
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
            l.text = @"Choose Category";
            UITableView *catTV = [[UITableView alloc] initWithFrame:CGRectMake(2,44,456,230 - 46) style:UITableViewStylePlain];
            catTV.delegate = self;
            catTV.dataSource = self;
            catTV.tag = 2;
            [detailView addSubview:catTV];
        }
            break;
        case 4:
            l.text = @"Choose Privacy Mode";
            
            GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake((460 * 0.25) - 40, 80, 80, 44)];
            GradientAttributedButton *button2 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake((460 * 0.50) - 40, 80, 80, 44)];
            GradientAttributedButton *button3 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake((460 * 0.75) - 40, 80, 80, 44)];
            
            
            
            NSShadow *shadow = [[NSShadow alloc] init];
            shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
            shadow.shadowOffset = CGSizeMake(0,-1.0f);
            button.delegate = self;
            button.tag = indexPath.row;
            
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [style setAlignment:NSTextAlignmentCenter];
            
            BOOL b1Selected = [[SettingsTool settings] youtubePrivacy] == 0;
            BOOL b2Selected = [[SettingsTool settings] youtubePrivacy] == 1;
            BOOL b3Selected = [[SettingsTool settings] youtubePrivacy] == 2;
            
            
            [button setTitle:[[NSAttributedString alloc] initWithString:@"Public" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                 NSShadowAttributeName : shadow,
                                                                                                 NSParagraphStyleAttributeName : style,
                                                                                                 NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                   }] disabledTitle:nil beginGradientColorString:b1Selected ? @"#009900" : @"#666666" endGradientColor: b1Selected ? @"#006600" : @"#333333"];
            
            
            [button2 setTitle:[[NSAttributedString alloc] initWithString:@"Unlisted" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                 NSShadowAttributeName : shadow,
                                                                                                 NSParagraphStyleAttributeName : style,
                                                                                                 NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                 }] disabledTitle:nil beginGradientColorString:b2Selected ? @"#009900" : @"#666666" endGradientColor: b2Selected ? @"#006600" : @"#333333"];
            
            [button3 setTitle:[[NSAttributedString alloc] initWithString:@"Private" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                 NSShadowAttributeName : shadow,
                                                                                                 NSParagraphStyleAttributeName : style,
                                                                                                 NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                 }] disabledTitle:nil beginGradientColorString:b3Selected ? @"#009900" : @"#666666" endGradientColor: b3Selected ? @"#006600" : @"#333333"];
            button.enabled = YES;
            button2.enabled = YES;
            button3.enabled = YES;
            
            [button update];
            [button2 update];
            [button3 update];

            button.tag = 100;
            button2.tag = 101;
            button3.tag = 102;
            
            button.delegate = self;
            button2.delegate = self;
            button3.delegate = self;
            
            [detailView addSubview:button];
            [detailView addSubview:button2];
            [detailView addSubview:button3];
       
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

    if (tag == 100) {
        [[SettingsTool settings] setYoutubePrivacy:0];
    } else if (tag == 101) {
        [[SettingsTool settings] setYoutubePrivacy:1];
    } else if (tag == 102) {
        [[SettingsTool settings] setYoutubePrivacy:2];
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
    if (title && ([title length]>0) && category && ([category length] > 0)) {
        uploadButton.enabled = YES;
    } else {
        uploadButton.enabled = NO;
    }
    
    logoutButton.enabled = (authToken != nil);
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
        return [categoryList count];
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
        cell.textLabel.text = [[categoryList objectAtIndex:indexPath.row] objectAtIndex:0];
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
            cell.textLabel.text = @"Category";
            cell.detailTextLabel.text = categoryStr;
            break;
        case 4:
            cell.textLabel.text = @"Privacy";
            switch ([[SettingsTool settings] youtubePrivacy]) {
                case  0:
                    cell.detailTextLabel.text = @"Public";
                    break;
                case  1:
                    cell.detailTextLabel.text = @"Unlisted";
                    break;
                case  2:
                    cell.detailTextLabel.text = @"Private";
                    break;
            }
            break;

    }
    
   
    return cell;
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


- (void)youtubeSignIn {
    NSString *clientID = @"239992282780-03v1jhe7ck0sdr8bkft7h1onuu3cmeiq.apps.googleusercontent.com";
    NSString *clientSecret = @"x_gpg3vKExQKvP0-j-P2sIOG";
 
    
    if (!self.youTubeService) {
        _youTubeService = [[GTLServiceYouTube alloc] init];
        _youTubeService.shouldFetchNextPages = YES;
        _youTubeService.retryEnabled = YES;
    }
   
   authToken = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychainName
                                                                 clientID:clientID
                                                             clientSecret:clientSecret];

    if ((!authToken) || (![authToken canAuthorize])) {
        GTMOAuth2ViewControllerTouch *viewController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeYouTube
                                                                                                  clientID:clientID
                                                                                              clientSecret:clientSecret
                                                                                          keychainItemName:keychainName
                                                                                                  delegate:self
                                                                                          finishedSelector:@selector(viewController:finishedWithAuth:error:)];
        [self presentViewController:viewController animated:YES completion:^{
            
        }];
    } else {
        [self updateUploadButtonStatus];
        [_youTubeService setAuthorizer:authToken];
        [self fetchVideoCategories];
        [tv reloadData];
    }
    
}


- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth  error:(NSError *)error {
    authToken = nil;
    if (error != nil) {
       
    } else {
        authToken = auth;
        [_youTubeService setAuthorizer:authToken];
        [self fetchVideoCategories];
    }

    if (authToken) {
        logoutButton.enabled = YES;
    } else {
        logoutButton.enabled = NO;
    }

    [viewController dismissViewControllerAnimated:YES completion:^{
        [tv reloadData];
    }];
}

- (void)fetchVideoCategories {
    GTLServiceYouTube *service = self.youTubeService;
    
    GTLQueryYouTube *query = [GTLQueryYouTube queryForVideoCategoriesListWithPart:@"snippet,id"];
    query.regionCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    [service executeQuery:query
        completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeVideoCategoryListResponse *categoryList2, NSError *error) {
            if (error) {
                NSLog(@"Could not fetch video category list: %@", error);
            } else {
                NSMutableArray *list  =[[NSMutableArray alloc] initWithCapacity:50];
                for (GTLYouTubeVideoCategory *c in categoryList2) {
                    NSString *t = c.snippet.title;
                    NSString *categoryID = c.identifier;
                    [list addObject:@[ t, categoryID]];
                    if ([category isEqualToString:categoryID]) {
                        categoryStr = t;
                    }
                }
                categoryList = [list copy];
                [tv reloadData];
                if ((!detailView) && ((!title) || ([title length] < 1))) {
                    [self tableView:tv didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                }
            }
        }];
}


#pragma mark - Upload

- (void)uploadVideoFile {
    GTLYouTubeVideoStatus *status = [GTLYouTubeVideoStatus object];
    
    switch (privacy) {
        case 0:
            status.privacyStatus = @"public";
            break;
        case 1:
            status.privacyStatus = @"unlisted";
            break;
        case 2:
            status.privacyStatus = @"private";
            break;
    }
    
    GTLYouTubeVideoSnippet *snippet = [GTLYouTubeVideoSnippet object];
    snippet.title = title;
    
    if ([description length] > 0) {
        snippet.descriptionProperty = description;
    }
    
    if ([tags length] > 0) {
        snippet.tags = [tags componentsSeparatedByString:@","];
    }
    
    snippet.categoryId = category;
    
    
    GTLYouTubeVideo *video = [GTLYouTubeVideo object];
    video.status = status;
    video.snippet = snippet;
    
    NSURL *o = [self.activityItems objectAtIndex:0];
    
    [self uploadVideoWithVideoObject:video resumeUploadLocationURL:nil url:o];
}

- (void)uploadVideoWithVideoObject:(GTLYouTubeVideo *)video resumeUploadLocationURL:(NSURL *)locationURL url:(NSURL *)o {
    NSFileHandle *fileHandle = nil;
    NSString *filename = nil;

    GTLUploadParameters *uploadParameters = nil;
 
    if ([o isFileURL]) {
        NSString *path  = [o path];
        NSString *mimeType = [self MIMETypeForFilename:filename defaultMIMEType:@"video/mp4"];
        filename = [path lastPathComponent];
        fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
        if (fileHandle) {
            uploadParameters = [GTLUploadParameters uploadParametersWithFileHandle:fileHandle MIMEType:mimeType];
            uploadParameters.uploadLocationURL = locationURL;
            [self uploadVideoWithParamaters:uploadParameters andVideo:video];
        } else {
            uploadProgressLabel.text = [NSString stringWithFormat:@"Unable to read %@", filename];
            uploadProgressLabel.textColor = [UIColor redColor];
            return;
        }
    } else {
        [assetLibrary assetForURL:o resultBlock:^(ALAsset *asset) {
            uploadProgressLabel.text = @"Copying clip to app library";
            uploadProgressLabel.textColor =[UIColor whiteColor];
            [self performSelectorInBackground:@selector(makeLocalCopyOf:) withObject:@[asset,video]];
        } failureBlock:^(NSError *error) {
            uploadProgressLabel.textColor = [UIColor redColor];
                uploadProgressLabel.text = [NSString stringWithFormat:@"Unable to acquire the asset from the library"];
        }];
        
        return;
    }
}

-(void)uploadComplete:(NSURL *)url {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUploadedURLAndDict" object:@[
                                                                                                    url,
                                                                                                    @{@"title" : title, @"description" : description }
                                                                                                    ] ];
    [self.delegate youTubeDidFinish:YES];
}

-(void)uploadVideoWithParamaters:(GTLUploadParameters *)uploadParameters andVideo:(GTLYouTubeVideo *)video {
    
    GTLQueryYouTube *query = [GTLQueryYouTube queryForVideosInsertWithObject:video  part:@"snippet,status" uploadParameters:uploadParameters];
    
    GTLServiceYouTube *service = self.youTubeService;
    _uploadFileTicket = [service executeQuery:query  completionHandler:^(GTLServiceTicket *ticket,  GTLYouTubeVideo *uploadedVideo, NSError *error) {
        
        if (error == nil) {
            uploadProgress.progress = 0.0f;
            uploadProgressLabel.text = @"Upload Complete";
            uploadButton.enabled = NO;
            NSLog(@"uploadedVideo:%@ ticket:%@", uploadedVideo, ticket);
            NSString *urlStr = [NSString stringWithFormat:@"http://youtu.be/%@", uploadedVideo.identifier];
            
            [self performSelector:@selector(uploadComplete:) withObject:[NSURL URLWithString:urlStr] afterDelay:1.0f];
        } else {
            if (![uploadProgressLabel.textColor isEqual:[UIColor redColor]]) {
                uploadProgressLabel.text = [error localizedDescription];
            }
            
        }
        _uploadFileTicket = nil;
        if (tmpFilePath) {
            [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:&error];
            tmpFilePath = nil;
        }
    }];
    
    _uploadFileTicket.uploadProgressBlock = ^(GTLServiceTicket *ticket,  unsigned long long numberOfBytesRead,  unsigned long long dataLength) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"youtubeUploadProgress" object:@[ [NSNumber numberWithFloat:(float)numberOfBytesRead / (float)dataLength ], @"Upload in progress."]];
    };
    
    GTMHTTPUploadFetcher *uploadFetcher = (GTMHTTPUploadFetcher *)[_uploadFileTicket objectFetcher];
    uploadFetcher.locationChangeBlock = ^(NSURL *url) {
        _uploadLocationURL = url;
    };
}


- (NSString *)MIMETypeForFilename:(NSString *)filename defaultMIMEType:(NSString *)defaultType {
    NSString *result = defaultType;
    NSString *extension = [filename pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    if (uti) {
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }
        CFRelease(uti);
    }
    return result;
}

-(void)youtubeUploadStatusUpdate:(NSNotification *)n {
    NSData *data = (NSData *)n.object;
    NSError *error = nil;
    NSDictionary *statusDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (!error) {
        if ([statusDict objectForKey:@"error"]) {
            NSDictionary *errDict = [statusDict objectForKey:@"error"];
            NSArray *msgResp = [errDict objectForKey:@"data"];
            uploadProgressLabel.textColor = [UIColor redColor];
            if (!error) {
                NSDictionary *errInfo = [msgResp objectAtIndex:0];
               uploadProgressLabel.text = [NSString stringWithFormat:@"%@:%@", [errInfo objectForKey:@"message"], [errInfo objectForKey:@"reason"]];
            }
        }
    }
}
         

-(void)makeLocalCopyOf:(NSArray *)args
{
    tmpFilePath = nil;
    ALAsset *asset = [args objectAtIndex:0];
    GTLYouTubeVideo *video = [args objectAtIndex:1];
    
    NSString *filePath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[UtilityBag bag] pathForNewResourceWithExtension:@"mov"]];
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!handle) {
        dispatch_async(dispatch_get_main_queue(), ^{
            uploadProgressLabel.text = @"Unable to create a local file for the copy.";
            uploadProgressLabel.textColor =[UIColor redColor];
        });
        return;
    }
    
    ALAssetRepresentation *rep = [asset defaultRepresentation];
  
    NSNumber *fileSpace = [NSNumber numberWithLongLong:[rep size]];
    NSNumber *freeSpace = [[UtilityBag bag] getfreeDiskSpaceInBytes];
        
    if ([freeSpace compare:fileSpace] == NSOrderedAscending) {
        uploadProgressLabel.text = @"Not enough free space to store the required temporary copy.";
        uploadProgressLabel.textColor = [UIColor redColor];
        return;
    }

    static const NSUInteger BufferSize = 1024*1024;
    
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    NSUInteger totalRead = 0;
    do {
        @try {
            bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:nil];
            [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
            offset += bytesRead;
        } @catch (NSException *exception) {
            free(buffer);
            dispatch_async(dispatch_get_main_queue(), ^{
                uploadProgressLabel.text = @"Unable to complete the copy.";
                uploadProgressLabel.textColor = [UIColor redColor];
            });
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            return ;
        }
        totalRead += bytesRead;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"youtubeUploadProgress" object:@[[NSNumber numberWithFloat:(float)[rep size] / (float)totalRead], @"Copy in progress"]];
        });
    } while (bytesRead > 0);
    
    free(buffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"youtubeUploadProgress" object:@[[NSNumber numberWithFloat:(float)[rep size] / (float)totalRead], @"Copy complete; starting upload"]];
    });
    tmpFilePath = filePath;
    [NSThread sleepForTimeInterval:1.0f];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self uploadVideoWithVideoObject:video resumeUploadLocationURL:_uploadLocationURL url:[NSURL fileURLWithPath:filePath] ];
    });
    
}

@end