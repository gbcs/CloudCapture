//
//  NavController.m
//  Capture
//
//  Created by Gary Barnett on 1/5/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "NavController.h"
#import "AppDelegate.h"

@interface NavController ()

@end

@implementation NavController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)shouldAutorotate  {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return appD.allowRotation;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations  {
    NSInteger supported = UIInterfaceOrientationMaskAll;
    return supported;
}

@end
