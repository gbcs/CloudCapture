//
//  RemoteLibraryViewController.m
//  Capture
//
//  Created by Gary  Barnett on 3/12/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "RemoteLibraryViewController.h"

@interface RemoteLibraryViewController ()

@end

@implementation RemoteLibraryViewController {
    NSDictionary *currentList;
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
    
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[[NSString stringWithFormat:@"%@", [[UIDevice currentDevice] name]], [[VideoSourceManager manager] nameForSource:self.remoteID]]];
    [segment addTarget:self action:@selector(deviceSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    segment.selectedSegmentIndex = 1;
   
    UISegmentedControl *segment2 = [[UISegmentedControl alloc] initWithItems:@[ @"Video", @"Pictures", @"Audio" ]];
    [segment2 addTarget:self action:@selector(typeSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    segment2.selectedSegmentIndex = 0;
    
    self.toolbarItems = @[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc] initWithCustomView:segment],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
                           ];
    self.navigationItem.titleView = segment2;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryUpdate:) name:@"libraryUpdate" object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self requestUpdate];
}

-(void)requestUpdate {
    NSString *whichType = @"libraryVideo";
    if ([self typeSegment].selectedSegmentIndex == 1) {
        whichType = @"libraryPhoto";
    } else if ([self typeSegment].selectedSegmentIndex == 2) {
        whichType = @"libraryAudio";
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"cmd" : whichType } options:NSJSONWritingPrettyPrinted error:nil];
    [[RemoteBrowserManager manager] sendMessage:data toID:self.remoteID];
}

-(void)deviceSegmentChanged:(id)sender {
    
}

-(void)typeSegmentChanged:(id)sender {
    [self requestUpdate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UISegmentedControl *)typeSegment {
    return (UISegmentedControl *)self.navigationItem.titleView;
}

-(void)libraryUpdate:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSDictionary *list = [args objectAtIndex:1];
    NSInteger index = [[args objectAtIndex:0] integerValue];
    switch (index) {
        case 0: //video
            currentList = list;
            [self typeSegment].selectedSegmentIndex = 0;
            break;
        case 1: //Photo
            currentList = list;
            [self typeSegment].selectedSegmentIndex = 1;
            break;
        case 2: //Audio
            currentList = list;
            [self typeSegment].selectedSegmentIndex = 2;
            break;
    }
    
    //reload collectionview
    NSLog(@"libraryUpdate:%@:%@", @(index), list);
    
    
}

@end
