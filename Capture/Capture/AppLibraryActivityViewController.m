//
//  AppLibraryActivityViewController.m
//  Capture
//
//  Created by Gary Barnett on 11/27/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AppLibraryActivityViewController.h"

@interface AppLibraryActivityViewController ()

@end

@implementation AppLibraryActivityViewController {
    __weak IBOutlet UILabel *progressLabel;
    __weak IBOutlet UIButton *cancelButton;
    NSInteger originalCount;
    NSMutableArray *tmpList;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //NSLog(@"%s", __func__);
    progressLabel = nil;
    cancelButton = nil;
    tmpList = nil;
}


-(IBAction)userDidTapCancelButton:(id)sender {
    tmpList = [[NSArray array] mutableCopy];
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
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(handleApplicationBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipCopyReport:) name:@"clipCopyReport" object:nil];
    
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidUnload];
    
}

-(void)updateLabel {
    progressLabel.text = [NSString stringWithFormat:@"Copying clip #%ld of %ld", (long)(originalCount + 1 - [tmpList count]), (long)originalCount];
}

-(void)clipCopyReport:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    [tmpList removeObjectAtIndex:0];
    
    if ([tmpList count]<1) {
        [self.delegate appLibraryDidFinish:YES];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[args objectAtIndex:1] boolValue] == YES) {
            
        } else {
            
        }
        [self updateLabel];
    });
    
    [self copyClip];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    originalCount = [self.activityItems count];
    tmpList = [self.activityItems mutableCopy];
    [self updateLabel];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self performSelectorInBackground:@selector(copyClip) withObject:nil];
}



-(void)copyClip {
    NSURL *filePath = [tmpList objectAtIndex:0];
    [[AssetManager manager] copyClipToAppLibrary:filePath];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}




- (void)handleApplicationBecameActive:(NSNotification *)notification
{
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end
