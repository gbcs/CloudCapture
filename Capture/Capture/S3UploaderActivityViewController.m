//
//  S3UploaderActivityViewController.m
//  Capture
//
//  Created by Gary Barnett on 1/17/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "S3UploaderActivityViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>


@interface S3UploaderActivityViewController ()

@end

@implementation S3UploaderActivityViewController {
    
    __weak IBOutlet UITableView *tv;
    
    NSString *region;
    NSString *bucket;
    NSString *key;
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
    
    AmazonS3Client *S3Client;
    
    NSString *guid;
    S3PutObjectResponse *putObjectResponse;
    S3PutObjectRequest *por;

}

- (void)dealloc
{//NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    uploadButton = nil;
    cancelButton  = nil;
    logoutButton = nil;
    
    tv = nil;
    
    region = nil;
    bucket = nil;
    key = nil;
    secret = nil;
    
    detailAnimator = nil;
    detailView = nil;
    
  
    uploadButton = nil;

    uploadProgress = nil;
    uploadProgressLabel = nil;

    _uploadLocationURL = nil;
    tmpFilePath = nil;
    assetLibrary = nil;
    S3Client = nil;
    putObjectResponse = nil;
    por = nil;
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
    
    uploadButton = [[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedUpload:)];
    uploadButton.enabled = NO;
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.leftBarButtonItems =  @[ cancelButton ];
    
    self.navigationItem.rightBarButtonItem = uploadButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(handleApplicationBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(youtubeUploadProgress:) name:@"youtubeUploadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(youtubeUploadStatusUpdate:) name:@"youtubeUploadStatusUpdate" object:nil];
    
    assetLibrary = [[ALAssetsLibrary alloc] init];

    region = [[SettingsTool settings] S3Region];
    bucket = [[SettingsTool settings] S3Bucket];
    key = [[SettingsTool settings] S3Key];
    
    if (bucket && key && ([bucket length] >0) && ([key length] > 0) ) {
        [self readSecret];
    }
    
    regionList = @[
                   @"US_EAST_1",
                   @"US_WEST_1",
                   @"EU_WEST_1",
                   @"AP_SOUTHEAST_1",
                   @"AP_NORTHEAST_1",
                   @"US_WEST_2",
                   @"SA_EAST_1",
                   @"AP_SOUTHEAST_2"

                   ];
    

}

-(void)readSecret {
    NSString *a  = [[UtilityBag bag] passwordFromKeychainForServer:key andUsername:key];
    if (a) {
        secret = a;
    } else {
        secret = @"";
    }
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
    [[SettingsTool settings] setS3Region:region];
    [[SettingsTool settings] setS3Bucket:bucket];
    [[SettingsTool settings] setS3Key:key];
   
    if (secretUpdated) {
        secretUpdated = NO;
        [[UtilityBag bag] saveInKeychainForServer:key withUsername:key andPassword:secret];
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
    [self.delegate S3DidFinish:YES];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 2) {
        region = [regionList objectAtIndex:indexPath.row];
        [tv reloadData];
        [self updateUploadButtonStatus];
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
        [detailAnimator removeAllBehaviors];
        [detailAnimator addBehavior:gravity];
        [self performSelector:@selector(finishDetailPage) withObject:nil afterDelay:1.0];

        return;
    }
    
    if (detailView) {
        [self finishDetailPage];
        return;
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
            l.text = @"Select Region";
            UITableView *catTV = [[UITableView alloc] initWithFrame:CGRectMake(2,44,456,230 - 46) style:UITableViewStylePlain];
            catTV.delegate = self;
            catTV.dataSource = self;
            catTV.tag = 2;
            [detailView addSubview:catTV];
        }
            break;
        case 1:
        {
            l.text = @"Enter Bucket";
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
            l.text = @"Enter Access Secret";
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,60,440,44)];
            textField.backgroundColor = [UIColor whiteColor];
            textField.delegate = self;
            textField.tag = indexPath.row;
            textField.text = @"";
            [detailView addSubview:textField];
            [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];
        }
            break;
        case 5:
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
    if (region && bucket && key && secret)  {
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
    if (tableView.tag == 2) {
        return 0;
    }
    
    if (!uploading) {
        return 0;
    }
    
    return 60.0f;
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
    
    [tv performSelector:@selector(reloadData) withObject:nil afterDelay:1.0f];
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
        return [regionList count];
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
        cell.textLabel.text = [regionList objectAtIndex:indexPath.row];
        return cell;
    }
    
    
    switch ( indexPath.row) {
        case 0:
            cell.textLabel.text = @"Region";
            cell.detailTextLabel.text = region;
            break;
        case 1:
            cell.textLabel.text = @"Bucket";
            cell.detailTextLabel.text = bucket;
            break;
        case 2:
            cell.textLabel.text = @"Access Key";
            if (key && ([key length] >5)) {
                cell.detailTextLabel.text = [[key substringToIndex:5] stringByAppendingString:@"..."];
            } else {
                cell.detailTextLabel.text = @"<no key>";
            }
            break;
        case 3:
            cell.textLabel.text = @"Access Secret";
            if (secret && ([secret length] >5)) {
                cell.detailTextLabel.text = [[secret substringToIndex:5] stringByAppendingString:@"..."];
            } else {
                cell.detailTextLabel.text = @"<no secret>";
            }
            break;
        case 4:
        {
            cell.textLabel.text = @"Get Pre-Signed URL";
            UISwitch *sw1 = [[UISwitch alloc] init];
            sw1.tag = 4;
            [sw1 setOn:[[[SettingsTool settings] S3GetURL] integerValue]];
            [sw1 addTarget:self action:@selector(getUrlSwitch:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw1;
        }
            break;
    }
    
    return cell;
}

-(void)getUrlSwitch:(id)sender {
    UISwitch *sw1 = (UISwitch *)sender;
    
    [[SettingsTool settings] setS3GetURL:@(sw1.isOn)];
    [tv reloadData];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *textStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    switch (textField.tag) {
        case 1:
            bucket = textStr;
            break;
        case 2:
            key = textStr;
            break;
        case 3:
            secret = textStr;
            secretUpdated = YES;
            break;
    }
    return YES;
}

-(void)uploadComplete {
    [self.delegate S3DidFinish:YES];
}

-(void)uploadFailed {
    [self.delegate S3DidFinish:NO];
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite {
    
    uploadProgress.progress = ((float)totalBytesWritten) / (float)totalBytesExpectedToWrite;
 
}

-(void)uploadVideoFile {
    
    S3Client = [[AmazonS3Client alloc] initWithAccessKey:key withSecretKey:secret];
    S3Client.endpoint = [AmazonEndpoints s3Endpoint:(int)[regionList indexOfObject:region]];
    
       guid = [[UtilityBag bag] generateGUID];
        
        por = [[S3PutObjectRequest alloc] initWithKey:guid inBucket:bucket];
        por.contentType = @"video/mp4";
        NSURL *url = [self.activityItems objectAtIndex:0];
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:&error];
        por.data        = data;
        por.delegate = self;
        
        putObjectResponse = [S3Client putObject:por];
    
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    if ([[[SettingsTool settings] S3GetURL] boolValue] == YES) {
        [self getURLForUpload];
    } else {
        [self uploadComplete];
    }
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error);
    [self uploadFailed];
}

-(void)getURLForUpload {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
    
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = @"video/mp4";
    
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        gpsur.key                     = guid;
        gpsur.bucket                  = bucket;
        gpsur.expires                 = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.
        gpsur.responseHeaderOverrides = override;
        
        NSError *error = nil;
        NSURL *url = [S3Client getPreSignedURL:gpsur error:&error];
        
        if(url == nil)
        {
            if(error != nil)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self uploadFailed];
                });
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUploadedURLAndDict" object:@[
                                                                                                                url,
                                                                                                                @{@"title" : @"", @"description" : @"" }
                                                                                                                ] ];
                 [self uploadComplete];
            });
        }
        
    });
}



@end