//
//  RESTActivityViewController.m
//  Capture
//
//  Created by Gary Barnett on 1/20/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "RESTActivityViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface RESTActivityViewController ()

@end

@implementation RESTActivityViewController {
    
    __weak IBOutlet UITableView *tv;
    
    UIDynamicAnimator *detailAnimator;
    UIView *detailView;
    
    BOOL uploading;
    
    UIProgressView *uploadProgress;
    UILabel *uploadProgressLabel;
    
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *uploadButton;
    UIBarButtonItem *logoutButton;
    
    NSURLSessionUploadTask *task;
    NSURLSession *session;
    NSOperationQueue *queue;
    
}

- (void)dealloc
{//NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    uploadButton = nil;
    cancelButton  = nil;
    logoutButton = nil;
    
    tv = nil;
    
    detailAnimator = nil;
    detailView = nil;
    
    
    uploadButton = nil;
    
    uploadProgress = nil;
    uploadProgressLabel = nil;
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(RESTUploadProgress:) name:@"RESTUploadProgress" object:nil];
    self.navigationItem.title = @"REST Uploader";
    
}


-(void)RESTUploadProgress:(NSNotification *)n {
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
  
    uploading = YES;
    [tv reloadData];
    
    [self uploadVideoFile];
}

- (IBAction)userTappedCancel:(id)sender {
   
    
    self.activityItems = nil;
    [self.delegate RESTDidFinish:YES];
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
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
            {
                l.text = @"Upload URL";
                UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,50,440,44)];
                textField.backgroundColor = [UIColor whiteColor];
                textField.delegate = self;
                textField.keyboardType = UIKeyboardTypeURL;
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.tag = 127;
                textField.text = [[SettingsTool settings] restUploadURL];
                [detailView addSubview:textField];
                [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0];
                
                UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,94,440,30)];
                infoLabel.backgroundColor = [UIColor clearColor];
                infoLabel.numberOfLines = 0;
                infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
                infoLabel.text = @"Use $1 for the filename, $2 to generate a new GUID.mov";
                infoLabel.textAlignment = NSTextAlignmentCenter;
                [detailView addSubview:infoLabel];
                
            }
                break;
            case 1:
            {
                l.text = @"Upload URL Request Type";
                
                
                
                GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(152 - 50 , 100, 100, 50)];
                GradientAttributedButton *button2 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(303 - 50, 100, 100, 50)];
                
                NSShadow *shadow = [[NSShadow alloc] init];
                shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
                shadow.shadowOffset = CGSizeMake(0,-1.0f);
             
            
                
                NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                [style setAlignment:NSTextAlignmentCenter];
                
                NSInteger rType = [[SettingsTool settings] restRequestType];
                
                NSString *bColor = @"#444444";
                NSString *eColor = @"#111111";
                
                NSString *bColorSel = @"#009900";
                NSString *eColorSel = @"#006600";
                
                
                [button setTitle:[[NSAttributedString alloc] initWithString:@"POST" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSParagraphStyleAttributeName : style,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }] disabledTitle:nil beginGradientColorString:(rType == 0) ? bColorSel : bColor endGradientColor:(rType == 0) ? eColorSel : eColor];
              
                
                [button2 setTitle:[[NSAttributedString alloc] initWithString:@"PUT" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSParagraphStyleAttributeName : style,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }] disabledTitle:nil beginGradientColorString:(rType == 1) ? bColorSel : bColor endGradientColor:(rType == 1) ? bColorSel : bColor];
                button.delegate = self;
                button2.delegate = self;
                button.enabled = YES;
                [button update];
                
                button2.enabled = YES;
                [button2 update];

                button.tag = 110;
                button2.tag = 111;
                
                [detailView addSubview:button];
                [detailView addSubview:button2];
                
                UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,170,440,30)];
                infoLabel.backgroundColor = [UIColor clearColor];
                infoLabel.numberOfLines = 0;
                infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
                infoLabel.text = @"Select the method to be used in uploading to the server.";
                infoLabel.textAlignment = NSTextAlignmentCenter;
                [detailView addSubview:infoLabel];

            }
                break;
            case 2:
            {
                l.text = @"Upload URL Custom Header";
                UITextView *textV = [[UITextView alloc] initWithFrame:CGRectMake(10,50,440,120)];
                textV.backgroundColor = [UIColor whiteColor];
                textV.keyboardType = UIKeyboardTypeASCIICapable;
                textV.delegate = self;
                textV.tag = 126;
                textV.text = [[SettingsTool settings] restHeaders];
                textV.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textV.autocorrectionType = UITextAutocorrectionTypeNo;
                [detailView addSubview:textV];
                [textV performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
                
                UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,170,440,30)];
                infoLabel.backgroundColor = [UIColor clearColor];
                infoLabel.numberOfLines = 0;
                infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
                infoLabel.text = @"Use $1 for the filename, $2 to generate a new GUID.mov";
                infoLabel.textAlignment = NSTextAlignmentCenter;
                [detailView addSubview:infoLabel];

            }
                break;
        }
    } else {
        switch (indexPath.row) {
            case 0:
            {
                l.text = @"Response Type";
                
                GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(152 - 50 , 100, 100, 50)];
                GradientAttributedButton *button2 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(303 - 50, 100, 100, 50)];
                
                NSShadow *shadow = [[NSShadow alloc] init];
                shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
                shadow.shadowOffset = CGSizeMake(0,-1.0f);
               
                
                NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                [style setAlignment:NSTextAlignmentCenter];
                
                NSInteger rType = [[SettingsTool settings] restResponseType];
                
                NSString *bColor = @"#444444";
                NSString *eColor = @"#111111";
                
                NSString *bColorSel = @"#009900";
                NSString *eColorSel = @"#006600";
                
                
                [button setTitle:[[NSAttributedString alloc] initWithString:@"Ignore" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSParagraphStyleAttributeName : style,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }] disabledTitle:nil beginGradientColorString:(rType == 0) ? bColorSel : bColor endGradientColor:(rType == 0) ? eColorSel : eColor];
                
                
                [button2 setTitle:[[NSAttributedString alloc] initWithString:@"JSON" attributes:@{    NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSParagraphStyleAttributeName : style,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }] disabledTitle:nil beginGradientColorString:(rType == 1) ? bColorSel : bColor endGradientColor:(rType == 1) ? bColorSel : bColor];
                
                button.delegate = self;
                button2.delegate = self;
                
                button.enabled = YES;
                [button update];
                
                button2.enabled = YES;
                [button2 update];
                
                button.tag = 120;
                button2.tag = 121;
                
                [detailView addSubview:button];
                [detailView addSubview:button2];
                
                UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,170,440,60)];
                infoLabel.backgroundColor = [UIColor clearColor];
                infoLabel.numberOfLines = 0;
                infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
                infoLabel.text = @"Select the method to be used for reading the server's response.";
                infoLabel.textAlignment = NSTextAlignmentCenter;
                [detailView addSubview:infoLabel];

            }
                break;
            case 1:
            {
                l.text = @"Response URL Parameter";
                UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10,50,440,44)];
                textField.backgroundColor = [UIColor whiteColor];
                textField.keyboardType = UIKeyboardTypeASCIICapable;
                textField.delegate = self;
                textField.tag = 125;
                textField.text = [[SettingsTool settings] restResponseParameter];
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                [detailView addSubview:textField];
                [textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
                
                UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,94,440,30)];
                infoLabel.backgroundColor = [UIColor clearColor];
                infoLabel.numberOfLines = 0;
                infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
                infoLabel.text = @"Enter a parameter to be used as a shareable URL.";
                infoLabel.textAlignment = NSTextAlignmentCenter;
                [detailView addSubview:infoLabel];

            }
                break;
        }
    }
    
    [self.view addSubview:detailView];
    [detailAnimator addBehavior:collision];
    [detailAnimator addBehavior:gravity];
}

-(void)updateUploadButtonStatus {
    if (1 == 1)  {
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
        
        
        return 44;
    }
    
    return 60.0f;
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    
    if (!detailView) {
        return;
    }
    UITextField *t = nil;
    UITextView *tview = nil;
    
    for (UIView *d in detailView.subviews) {
        if ([[UITextField class] isEqual:[d class]]) {
            t = (UITextField *)d;
            [t resignFirstResponder];
            break;
        } else if ([[UITextView class] isEqual:[d class]]) {
            tview = (UITextView *)d;
            [tview resignFirstResponder];
            break;
        }
    }

    switch (tag) {
        case 110:
        {
            [[SettingsTool settings] setRestRequestType:0];
        }
            break;
        case 111:
        {
            [[SettingsTool settings] setRestRequestType:1];
        }
            break;
        case 120:
        {
            [[SettingsTool settings] setRestResponseType:0];
        }
            break;
        case 121:
        {
            [[SettingsTool settings] setRestResponseType:1];

        }
            break;
        default:
        {
            if (t) {
                switch (t.tag) {
                    case 125:
                        [[SettingsTool settings] setRestResponseParameter:t.text];
                        break;
                    case 127:
                        [[SettingsTool settings] setRestUploadURL:t.text];
                        break;
                }
            } else if (tview) {
                switch (tview.tag) {
                    case 126:
                        [[SettingsTool settings] setRestHeaders:tview.text];
                        break;
                }
            }
        }
            break;
    }
    
    
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [detailAnimator removeAllBehaviors];
    [detailAnimator addBehavior:gravity];
    [self performSelector:@selector(finishDetailPage) withObject:nil afterDelay:1.0];
    [self updateUploadButtonStatus];
    
    [tv reloadData];
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat width = self.view.frame.size.height;
   
    if ( (!uploading) || (section != 0) ) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,width,60)];
        l.backgroundColor = [UIColor blackColor];
        l.textColor = [UIColor whiteColor];
        l.textAlignment = NSTextAlignmentCenter;
        l.text = (section == 0) ? @"Upload Location - Request" : @"Results - Server Response";
        return l;
    }
    
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
    }
	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (indexPath.section == 0) {
        switch ( indexPath.row) {
            case 0:
                cell.textLabel.text = @"URL";
                cell.detailTextLabel.text = [[SettingsTool settings] restUploadURL];
                break;
            case 1:
                cell.textLabel.text = @"Request Type";
                switch ([[SettingsTool settings] restRequestType]) {
                    case 0:
                        cell.detailTextLabel.text = @"POST";
                        break;
                    case 1:
                        cell.detailTextLabel.text = @"PUT";
                        break;
                }
                break;
            case 2:
                cell.textLabel.text = @"Custom Headers";
                cell.detailTextLabel.text = [[SettingsTool settings] restHeaders];
                break;
        }
    } else {
        switch ( indexPath.row) {
            case 0:
                cell.textLabel.text = @"Response Type";
                switch ([[SettingsTool settings] restResponseType]) {
                    case 0:
                        cell.detailTextLabel.text = @"Ignore";
                        break;
                    case 1:
                        cell.detailTextLabel.text = @"JSON";
                        break;
                }
                break;
            case 1:
                cell.textLabel.text = @"Parameter for shareable URL";
                cell.detailTextLabel.text = [[SettingsTool settings] restResponseParameter];
                break;
        }
    }

    return cell;
}


-(void)uploadComplete {
    [self.delegate RESTDidFinish:YES];
}

-(void)uploadFailed {
    [self.delegate RESTDidFinish:NO];
}


-(void)uploadVideoFile {
   
        // guid = ;
    
        //por.contentType = @"video/mp4";
    NSURL *url = [self.activityItems objectAtIndex:0];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:&error];
  
    NSString *urlStr = [[SettingsTool settings] restUploadURL];
    urlStr = [urlStr stringByReplacingOccurrencesOfString:@"$1" withString:[[url path] lastPathComponent]];
    urlStr = [urlStr stringByReplacingOccurrencesOfString:@"$2" withString:[[[UtilityBag bag] generateGUID] stringByAppendingPathExtension:@"mov"]];
   
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [request setHTTPMethod:[[SettingsTool settings] restRequestType] == 0 ? @"POST" : @"PUT"];
    
    NSString *headers = [[SettingsTool settings] restHeaders];
    if (headers && ([headers length] > 3)) {
        //[request setAllHTTPHeaderFields:]
    }
    
    
    NSURLRequest *r = [request copy];
    
    queue = [NSOperationQueue mainQueue];
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:queue];
    
    task = [session uploadTaskWithRequest:r fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
    }];
    
    
    [task resume];

    
    NSLog(@"upURL:%@ ",urlStr);
    
}



@end