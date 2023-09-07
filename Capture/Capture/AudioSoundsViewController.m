//
//  AudioSoundsViewController.m
//  Capture
//
//  Created by Gary Barnett on 1/22/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AudioSoundsViewController.h"
#import "FreeSFXViewController.h"
#import "FreeSoundViewController.h"
#import "SoundBibleViewController.h"
#import "GenerateSilentTrackViewController.h"

@interface AudioSoundsViewController ()

@end

@implementation AudioSoundsViewController {
    __weak IBOutlet UITableView *tv;
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
    
    self.navigationItem.title = @"Add Sounds";
    self.navigationController.toolbarHidden = YES;
    self.toolbarItems = @[ ];

}

-(void)userTappedSave {
    UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-3];
    [self.navigationController popToViewController:vc animated:YES];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        GenerateSilentTrackViewController *vc = [[GenerateSilentTrackViewController alloc] initWithNibName:@"GenerateSilentTrackViewController" bundle:nil];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        switch (indexPath.row) {
            case 0:
            {
                FreeSFXViewController *vc = [[FreeSFXViewController alloc] initWithNibName:@"FreeSFXViewController" bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 1:
            {
                FreeSoundViewController *vc = [[FreeSoundViewController alloc] initWithNibName:@"FreeSoundViewController" bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 2:
            {
                SoundBibleViewController *vc = [[SoundBibleViewController alloc] initWithNibName:@"SoundBibleViewController" bundle:nil];
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
        l.text = @"Generate Sounds";
    } else if (section == 1) {
       l.text = @"Download Sounds";
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
        return 1;
    }
    
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
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Make Silent Sound Track";
    } else if (indexPath.section == 1) {
        switch ( indexPath.row) {
            case 0:
                cell.textLabel.text = @"freeSFX.co.uk (free account required)";
                break;
            case 1:
                cell.textLabel.text = @"freesound.org (free account required)";
                break;
            case 2:
                cell.textLabel.text = @"SoundBible.com";
                break;
        }
    } else {
        
    }
    
    return cell;
}



@end
