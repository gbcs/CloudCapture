//
//  AddPhotoListViewController.m
//  Capture
//
//  Created by Gary  Barnett on 2/24/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AddPhotoListViewController.h"
#import "AddPhotoFreePixelsViewController.h"
#import "AddPhotoMorgueFileViewController.h"
#import "AddPhotoPublicDomainPhotosViewController.h"

@interface AddPhotoListViewController ()

@end

@implementation AddPhotoListViewController {

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
    
    self.navigationItem.title = @"Add Photos";
    self.navigationController.toolbarHidden = NO;
    self.toolbarItems = @[ ];
    
   
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
    
    //  [self updateUploadButtonStatus];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        {
            AddPhotoFreePixelsViewController *vc = [[AddPhotoFreePixelsViewController alloc] initWithNibName:@"AddPhotoFreePixelsViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1:
        {
            AddPhotoMorgueFileViewController *vc = [[AddPhotoMorgueFileViewController alloc] initWithNibName:@"AddPhotoMorgueFileViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
            AddPhotoPublicDomainPhotosViewController *vc = [[AddPhotoPublicDomainPhotosViewController alloc] initWithNibName:@"AddPhotoPublicDomainPhotosViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
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

    l.text = @"Free Stock Photo Sites";

    l.font = [UIFont boldSystemFontOfSize:20];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    
    return l;
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
		
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor blackColor];
    cell.textLabel.textColor = [UIColor whiteColor];

    switch ( indexPath.row) {
        case 0:
            cell.textLabel.text = @"freepixels.com";
            break;
        case 1:
            cell.textLabel.text = @"morguefile.com";
            break;
        case 2:
            cell.textLabel.text = @"commons.wikimedia.org";
            break;
    }

    return cell;
}



@end
