//
//  FirstStartViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/27/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "FirstStartViewController.h"
#import "HelpViewController.h"
#import "AppDelegate.h"

@interface FirstStartViewController () {
    
    __weak IBOutlet UIButton *locButton;
    __weak IBOutlet UIButton *micButton;
    __weak IBOutlet UIButton *photoButton;
    CLLocationManager *locationManager;
}

@end

@implementation FirstStartViewController


-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
    NSLog(@"%@:%s", [self class], __func__);
 
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    locButton = nil;
    micButton = nil;
    photoButton = nil;
    locationManager = nil;
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)updatePhotos {
    [photoButton setTitle:[ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized ? @"Granted" : @"Denied" forState:UIControlStateNormal];
    photoButton.enabled = NO;
}

- (IBAction)userTappedPhotoRequest:(id)sender {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            [self updatePhotos];
        } failureBlock:^(NSError *error) {
            [self updatePhotos];
        }];
    }
}

- (IBAction)userTappedMicRequest:(id)sender {
    AVAudioSession *audioSession = [[AVAudioSession alloc] init];
    NSError *error = nil;
    [audioSession setMode:AVAudioSessionModeVideoRecording error:&error];
    [audioSession requestRecordPermission:^ (BOOL granted){
        dispatch_async(dispatch_get_main_queue(), ^{
            [micButton setTitle:granted ? @"Granted" : @"Denied" forState:UIControlStateNormal];
            micButton.enabled = NO;
        });
    }];
}

- (IBAction)userTappedLocationRequest:(id)sender {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        [locButton setTitle:@"Granted" forState:UIControlStateNormal];
        locButton.enabled = NO;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
       locationManager = [[CLLocationManager alloc] init];
        [locationManager startUpdatingLocation];
    } else {
        [locButton setTitle:@"Denied" forState:UIControlStateNormal];
        locButton.enabled = NO;
    }
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"CloudCapt Camera and Edit Studio";
    self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedDone)];
    self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelp)];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        locButton.enabled = NO;
        [locButton setTitle:@"Granted" forState:UIControlStateNormal];
    } else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) {
        locButton.enabled = NO;
        [locButton setTitle:@"Denied" forState:UIControlStateNormal];
    }
    
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        photoButton.enabled = NO;
        [photoButton setTitle:@"Granted" forState:UIControlStateNormal];
    } else if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusNotDetermined) {
        photoButton.enabled = NO;
        [photoButton setTitle:@"Denied" forState:UIControlStateNormal];
    }
}

-(void)userTappedHelp {
    HelpViewController *vc = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    vc.noCloseButton = YES;
    vc.backOnly = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)userTappedDone {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    if ([[locButton titleForState:UIControlStateNormal] isEqualToString:@"Granted"]) {
        [[SettingsTool settings] setUseGPS:YES];
        [[LocationHandler tool] startup];
    }
    
    if ([[micButton titleForState:UIControlStateNormal] isEqualToString:@"Granted"]) {
        appD.audioRecordingAllowed = YES;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"resumeAfterFirstStart" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
