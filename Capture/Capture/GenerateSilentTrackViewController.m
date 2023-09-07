//
//  GenerateSilentTrackViewController.m
//  Capture
//
//  Created by Gary Barnett on 1/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "GenerateSilentTrackViewController.h"

@interface GenerateSilentTrackViewController ()

@end

@implementation GenerateSilentTrackViewController {
    
    __weak IBOutlet UIPickerView *picker;
    __weak IBOutlet UILabel *durationLabel;
    NSInteger duration;
    BOOL processingComplete;
    BOOL processing;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   self.navigationItem.title = @"Generate Silent Audio";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedSave)];
    [picker selectRow:30 inComponent:2 animated:NO];
    duration = 30;
    [self updateDurationLabel];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentAudioFileCreated:) name:@"silentAudioFileCreated" object:nil];
     
}



-(void)userTappedSave {
    picker.hidden = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.view addSubview:indicator];
    indicator.center = self.view.center;
    [indicator startAnimating];
    
    [[UtilityBag bag] logEvent:@"makeSilentTrack" withParameters:nil];
    [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[AudioBrowser manager] generateAudioSampleWithDuration:duration];
    });
}

-(void)silentAudioFileCreated:(NSNotification *)n {
    NSNumber *v = (NSNumber *)n.object;
    if ([v integerValue] > -1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAudioLibraryAndReload" object:nil];
        UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-3];
        [self.navigationController popToViewController:vc animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSInteger count = 60;
    
    switch (component) {
        case 0:
            count = 2;
            break;
    }
    
    return count;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 100;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 40;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%02ld", (long)row];
}

-(void)updateDurationLabel {
    
    NSInteger h = duration / (60*60);
    NSInteger m = (duration - (h *60*60)) / 60;
    NSInteger s = duration - (h*60*60) - (m*60);
    
    durationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)h, (long)m, (long)s];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    duration = ([picker selectedRowInComponent:0] * 60 * 60) + ([picker selectedRowInComponent:1] * 60) + [picker selectedRowInComponent:2];
    [self updateDurationLabel];
}


@end
