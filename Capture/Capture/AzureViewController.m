//
//  AzureViewController.m
//  Capture
//
//  Created by Gary Barnett on 1/29/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AzureViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface AzureViewController ()

@end

@implementation AzureViewController {
    __weak IBOutlet UITableView *tv;
   
    NSString *uploadContainerName;
    NSString *account;
    NSString *secret;
    
    UIDynamicAnimator *detailAnimator;
    UIView *detailView;
    
    BOOL uploading;
    
    UIProgressView *uploadProgress;
    UILabel *uploadProgressLabel;
    
    NSURL *_uploadLocationURL;
    NSString *tmpFilePath;
    ALAssetsLibrary *assetLibrary;
    
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *uploadButton;
    UIBarButtonItem *logoutButton;
    
    NSArray *regionList;
    BOOL secretUpdated;
  
    
    NSString *guid;
   
    
}

- (void)dealloc
{//NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    uploadButton = nil;
    cancelButton  = nil;
    logoutButton = nil;
    
    tv = nil;
    
    uploadContainerName = nil;
   
    account = nil;
    secret = nil;
    
    detailAnimator = nil;
    detailView = nil;
    
    
    uploadButton = nil;
    
    uploadProgress = nil;
    uploadProgressLabel = nil;
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(azureUploadProgress:) name:@"azureUploadStatus" object:nil];
    [self.navigationController setToolbarHidden:YES];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel:)];
    
    uploadButton = [[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedUpload:)];
    uploadButton.enabled = NO;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.leftBarButtonItems =  @[ cancelButton ];
    
    self.navigationItem.rightBarButtonItem = uploadButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(handleApplicationBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    assetLibrary = [[ALAssetsLibrary alloc] init];
    
    account = [[SettingsTool settings] azureAccount];
    uploadContainerName = [[SettingsTool settings] azureContainer];
    
    if (account && uploadContainerName && ([account length] >0) && ([uploadContainerName length] > 0) ) {
        [self readSecret];
    }
    
    
}

-(void)readSecret {
    NSString *s  = [[UtilityBag bag] passwordFromKeychainForServer:[NSString stringWithFormat:@"%@-%@", account, uploadContainerName] andUsername:account];
    if (s) {
        secret = s;
    } else {
        secret = @"";
    }
}

-(void)azureUploadProgress:(NSNotification *)n {
    NSNumber *progress = (NSNumber *)n.object;

    uploadProgress.progress = [progress floatValue];
    uploadProgressLabel.text = @"";
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
    [[SettingsTool settings] setAzureAccount:account];
    [[SettingsTool settings] setAzureContainer:uploadContainerName];

    if (secretUpdated) {
        secretUpdated = NO;
        [[UtilityBag bag] saveInKeychainForServer:[NSString stringWithFormat:@"%@-%@", account, uploadContainerName] withUsername:account andPassword:secret];
    }
    
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
    [self.delegate AzureDidFinish:YES];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
       
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
            l.text = @"Account";
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,60,440,44)];
            textField.backgroundColor = [UIColor whiteColor];
            textField.delegate = self;
            textField.tag = indexPath.row;
            textField.text = @"";
            [detailView addSubview:textField];
            [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];

        }
            break;
        case 1:
        {
            l.text = @"Container";
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,60,440,44)];
            textField.backgroundColor = [UIColor whiteColor];
            textField.delegate = self;
            textField.tag = indexPath.row;
            textField.text = @"";
            [detailView addSubview:textField];
            [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];
        }
            break;
        case 2:
        {
            l.text = @"Enter Access Key";
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,60,440,44)];
            textField.backgroundColor = [UIColor whiteColor];
            textField.delegate = self;
            textField.tag = indexPath.row;
            textField.text = @"";
            [detailView addSubview:textField];
            [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];
        }
            break;
        case 3:
        {
            
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,width,50)];
            l.textColor = [UIColor whiteColor];
            l.textAlignment = NSTextAlignmentCenter;
            l.text = @"Post-Upload Action";
            [detailView addSubview:l];
            
            GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(230 - 100, 70, 200, 44)];
            
            NSShadow *shadow = [[NSShadow alloc] init];
            shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
            shadow.shadowOffset = CGSizeMake(0,-1.0f);
            button.delegate = self;
            button.tag = indexPath.row;
            
            NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [style setAlignment:NSTextAlignmentCenter];
            
            NSString *c1 = @"#444444";
            NSString *c1e = @"333333";
            
            NSString *c2 = @"#009900";
            NSString *c2e =@"#006600";
            
            NSInteger action = [[[SettingsTool settings] S3PostUploadAction] integerValue];
            
            [button setTitle:[[NSAttributedString alloc] initWithString:@"Show" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                 NSShadowAttributeName : shadow,
                                                                                                 NSParagraphStyleAttributeName : style,
                                                                                                 NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                 }] disabledTitle:nil beginGradientColorString:(action != 0) ? c1 : c2 endGradientColor:(action != 0) ? c1e : c2e];
            button.enabled = YES;
            button.tag = 500;
            button.delegate = self;
            [button update];
            [detailView addSubview:button];
            
            button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(230 - 100, 125, 200, 44)];
            [button setTitle:[[NSAttributedString alloc] initWithString:@"Email" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                  NSShadowAttributeName : shadow,
                                                                                                  NSParagraphStyleAttributeName : style,
                                                                                                  NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                  }] disabledTitle:nil beginGradientColorString:(action != 1) ? c1 : c2 endGradientColor:(action != 1) ? c1e : c2e];
            button.enabled = YES;
            button.tag = 501;
            button.delegate = self;
            [button update];
            [detailView addSubview:button];
            
            button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(230 - 100, 180, 200, 44)];
            [button setTitle:[[NSAttributedString alloc] initWithString:@"URL" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                NSShadowAttributeName : shadow,
                                                                                                NSParagraphStyleAttributeName : style,
                                                                                                NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                }] disabledTitle:nil beginGradientColorString:(action != 2) ? c1 : c2 endGradientColor:(action != 2) ? c1e : c2e];
            button.enabled = YES;
            button.tag = 502;
            button.delegate = self;
            [button update];
            [detailView addSubview:button];
            
            
        }
            break;
    }
    
    
    [self.view addSubview:detailView];
    [detailAnimator addBehavior:collision];
    [detailAnimator addBehavior:gravity];
}

-(void)updateUploadButtonStatus {
    if (account && uploadContainerName && secret)  {
        uploadButton.enabled = YES;
    } else {
        uploadButton.enabled = NO;
    }
    
}

-(void)finishDetailPage {
    [detailAnimator removeAllBehaviors];
    detailAnimator = nil;
    [detailView removeFromSuperview];
    detailView = nil;
    [tv reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (!uploading) {
        return 0;
    }
    
    return 60.0f;
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    
    if ( (tag >= 500) && (tag <= 502) ) {
        [[SettingsTool settings] setS3PostUploadAction:@(tag - 500)];
    }
    
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


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

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
	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }

    
    
    switch ( indexPath.row) {
        case 0:
            cell.textLabel.text = @"Account";
            cell.detailTextLabel.text = account;
            break;
        case 1:
            cell.textLabel.text = @"Container";
            cell.detailTextLabel.text = uploadContainerName;
            break;
        case 2:
            cell.textLabel.text = @"Access Key";
            if (secret && ([secret length] >5)) {
                cell.detailTextLabel.text = [[secret substringToIndex:5] stringByAppendingString:@"..."];
            } else {
                cell.detailTextLabel.text = @"<no key>";
            }
            break;
        case 3:
        {
            cell.textLabel.text = @"Post-Upload Action";
            NSInteger action = [[[SettingsTool settings] azurePostUploadAction] integerValue];
            switch (action) {
                case 0:
                    cell.detailTextLabel.text = @"Text";
                    break;
                case 1:
                    cell.detailTextLabel.text = @"Email";
                    break;
                case 2:
                    cell.detailTextLabel.text = @"URL";
                    break;
            }
        }
            break;
    }
    
    return cell;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *textStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    switch (textField.tag) {
        case 0:
            account = textStr;
            break;
        case 1:
            uploadContainerName = textStr;
            break;
        case 2:
            secret = textStr;
            secretUpdated = YES;
            break;
    }
    return YES;
}

-(void)uploadComplete {
    [self.delegate AzureDidFinish:YES];
}

-(void)uploadFailed {
    [self.delegate AzureDidFinish:NO];
}

-(void)uploadVideoFile {
    credential = [AuthenticationCredential credentialWithAzureServiceAccount:account accessKey:secret];
    client = [CloudStorageClient storageClientWithCredential:credential];
    client.delegate=self;


    [client getBlobContainersWithBlock:^(NSArray *containers, NSError *error)
     {
         if (error)  {
             NSLog(@"%@",[error localizedDescription]);
         }  else  {
             if([containers count]!=0)
             {
                 container=[[NSArray alloc]initWithArray:containers];
                 
                 BlobContainer *useContainer = nil;
                 
                 for (BlobContainer *c in container) {
                     if ([c.name isEqualToString:uploadContainerName]) {
                         useContainer = c;
                         break;
                     }
                 }
                 
                 if (!useContainer) {
                     uploadProgressLabel.text = @"Selected container not found";
                     return;
                 }
            
                 NSURL *url = [self.activityItems objectAtIndex:0];
                 NSError *error = nil;
                 NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:&error];
                 NSString *fname = [[url absoluteString] lastPathComponent];
                 [client addBlobToContainer:useContainer blobName:fname contentData:data contentType:@"video/mp4"];
             } else {
                uploadProgressLabel.text = @"Create container in Azure Mgr";
             
             }
         }
         
     }];

    
}

- (void)storageClient:(CloudStorageClient *)client didAddBlobToContainer:(BlobContainer *)c blobName:(NSString *)blobName;
{
    NSString *containerStr = c.URL.absoluteString;
    
    
    NSString *imageStr=[NSString stringWithFormat:@"%@/%@", containerStr, blobName];
    NSLog(@"blob %@",imageStr);
    uploadProgressLabel.text = @"Complete";
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUploadedURLAndDict" object:@[
                                                                                                    [NSURL URLWithString:imageStr],
                                                                                                    @{@"title" : @"", @"description" : @"" }
                                                                                                    ] ];
    [_delegate AzureDidFinish:YES];
    
}

- (void)storageClient:(CloudStorageClient *)client didFailRequest:(NSURLRequest*)request withError:(NSError *)error {
    uploadProgressLabel.text = @"Failed";
    [_delegate AzureDidFinish:NO];
}





@end