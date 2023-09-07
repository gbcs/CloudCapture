//
//  PublishVIdeoViewController.m
//  Capture
//
//  Created by Gary  Barnett on 3/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "PublishVIdeoViewController.h"

@interface PublishVIdeoViewController ()

@end

@implementation PublishVIdeoViewController {
    __weak IBOutlet UITableView *tv;
    
    UIDynamicAnimator *detailAnimator;
    UIView *detailView;

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

    detailAnimator = nil;
    detailView = nil;
    
    
    uploadButton = nil;
    
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

- (IBAction)userTappedCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 2) {
        [tv reloadData];
        
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
    if (tableView.tag == 2) {
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    /*
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
    */
    return cell;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    /*
    NSString *textStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    switch (textField.tag) {
        case 1:
            
            break;
        case 2:
           
            break;
        case 3:
           
            break;
    }
     */
    return YES;
}



@end