//
//  AddVideoViewController.m
//  Capture
//
//  Created by Gary  Barnett on 2/24/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AddVideoViewController.h"
#import "AddVideoViewFreeAnimalVideoController.h"
#import "AddVideoStockFootageForFreeViewController.h"
#import "AddVideoVidevoViewController.h"
#import "AppDelegate.h"
#import "AddVideoPhotoView.h"
#import "AddVideoArchiveOrgViewController.h"
#import "AddPhotoViewController.h"
#import "CreateMovieViewController.h"

@interface AddVideoViewController ()
@end

@implementation AddVideoViewController {

    NSString *addedPath;
    AddVideoPhotoView *addPhotoView;
}
@synthesize tv;

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
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    self.navigationItem.title = @"Add Video Clips";
    self.toolbarItems = @[ ];
    self.navigationController.toolbarHidden = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addedPhotoForNewClip:) name:@"addedPhotoForNewClip" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addedVideoFromPhoto:) name:@"addedVideoFromPhoto" object:nil];
}

-(void)addedVideoFromPhoto:(NSNotification *)n {
    [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)addedPhotoForNewClip:(NSNotification *)n {
    NSString *fname = (NSString *)n.object;
    addedPath = fname;
}

-(void)userTappedCancel {
    UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-3];
    [self.navigationController popToViewController:vc animated:YES];
}

-(void)userTappedSave {
    UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-3];
    [self.navigationController popToViewController:vc animated:YES];
}

-(void)changeSegment:(id)sender {
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    
    if (segment.selectedSegmentIndex == 0) {
        [self.navigationController popViewControllerAnimated:NO];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidUnload];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
  
}

- (void)viewDidAppear:(BOOL)animated
{
   
    [super viewDidAppear:animated];
   
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];

    if (addedPath) {
        CGFloat midX = self.view.frame.size.width / 2.0f;
        addPhotoView = [[AddVideoPhotoView alloc] initWithFrame:CGRectMake(midX - 240, -270, 480, 270)];
        [self.view addSubview:addPhotoView];
        [addPhotoView startup:addedPath];
        addedPath = nil;
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    addedPath = nil;
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
            {
                CreateMovieViewController *vc = [[CreateMovieViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName: @"CreateMovieViewController"] bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 1:
            {
                AddPhotoViewController *vc = [[AddPhotoViewController alloc] initWithNibName:@"AddPhotoViewController" bundle:nil];
                vc.notifyStr = @"addedPhotoForNewClip";
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
        }
    } else if (indexPath.section == 1) {
    
        switch (indexPath.row) {
                /*
                 case 1:
                 {
                 AddVideoStockFootageForFreeViewController *vc = [[AddVideoStockFootageForFreeViewController alloc] initWithNibName:@"AddVideoStockFootageForFreeViewController" bundle:nil];
                 AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                 appD.allowRotation = NO;
                 [self presentViewController:vc animated:YES completion:nil];
                 }
                 break;
                 case 2:
                 {
                 AddVideoVidevoViewController *vc = [[AddVideoVidevoViewController alloc] initWithNibName:@"AddVideoVidevoViewController" bundle:nil];
                 [self.navigationController pushViewController:vc animated:YES];
                 }
                 break;
                 */
            case 0:
            {
                AddVideoArchiveOrgViewController *vc = [[AddVideoArchiveOrgViewController alloc] initWithNibName:@"AddVideoArchiveOrgViewController" bundle:nil];
                self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 1:
            {
                AddVideoViewFreeAnimalVideoController *vc = [[AddVideoViewFreeAnimalVideoController alloc] initWithNibName:@"AddVideoViewFreeAnimalVideoController" bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, 60)];
   
    if (section == 0) {
          l.text = @"Create";
    } else {
          l.text = @"Download Video";
    }
    
  
    l.font = [UIFont boldSystemFontOfSize:20];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    
    return l;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor blackColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
            {
                cell.textLabel.text = @"Create a movie";
            }
                break;
            case 1:
            {
                cell.textLabel.text = @"Create a video clip from a photo";
            }
                break;
        }
    } else {
        switch ( indexPath.row) {
        /*
            case 1:
                cell.textLabel.text = @"www.stockfootageforfree.com";
                break;
            case 2:
                cell.textLabel.text = @"www.videvo.net";
                break;
        */
            case 0:
                cell.textLabel.text = @"archive.org Moving Image Archive";
                break;
            case 1:
                cell.textLabel.text = @"freeanimalvideo.org";
                break;
        }
    }
   
    return cell;
}



@end
