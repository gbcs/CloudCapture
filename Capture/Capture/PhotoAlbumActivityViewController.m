//
//  PhotoAlbumActivityViewController.m
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "PhotoAlbumActivityViewController.h"

@interface PhotoAlbumActivityViewController () {
    
    __weak IBOutlet UILabel *progressLabel;
    __weak IBOutlet UIButton *cancelButton;
    NSInteger originalCount;
    NSMutableArray *tmpList;
}

@end

@implementation PhotoAlbumActivityViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //NSLog(@"%s", __func__);
    progressLabel = nil;
    cancelButton = nil;
    
    tmpList = nil;
    
}

-(void)userDidTapCancelButton:(id)sender {
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipMoveReport:) name:@"clipMoveReport" object:nil];
    
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidUnload];
    
}

-(void)updateLabel {
    progressLabel.text = [NSString stringWithFormat:@"Moving clip #%ld of %ld", (long)(originalCount + 1) - [tmpList count], (long) originalCount];
}

-(void)clipMoveReport:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    [tmpList removeObjectAtIndex:0];
    
    if ([tmpList count]<1) {
        [self.delegate photoAlbumDidFinish:YES];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[args objectAtIndex:1] boolValue] == YES) {
          
        } else {
            
        }
        [self updateLabel];
    });
    
    [self moveClip];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    originalCount = [self.activityItems count];
    tmpList = [self.activityItems mutableCopy];
    [self updateLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSelectorInBackground:@selector(moveClip) withObject:nil];
}

-(void)moveClip {
    NSURL *filePath = [tmpList objectAtIndex:0];
    [[AssetManager manager] moveClipToAlbum:[filePath path]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

- (void)handleApplicationBecameActive:(NSNotification *)notification
{
         
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation  {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end
