//
//  LaunchPadViewController.m
//  Capture
//
//  Created by Gary  Barnett on 3/26/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "LaunchPadViewController.h"
#import "VideoCameraViewController.h"
#import "AppDelegate.h"
#import "HelpViewController.h"
#import "ConfigureViewController.h"
#import "GridCollectionViewController.h"
#import "VideoSourcesCollectionViewController.h"
#import "AudioCaptureViewController.h"
#import "StillCameraViewController.h"
#import "PhotoLibraryViewController.h"
#import "AudioLibraryViewController.h"

@interface LaunchPadViewController ()

@end

@implementation LaunchPadViewController

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
    // Do any additional setup after loading the view from its nib.
    UILabel *titleLabel =[[UILabel alloc] initWithFrame:CGRectMake(0,0,200,44)];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = @"CloudCapt Camera and Edit Studio 1.2";
    self.navigationItem.titleView = titleLabel;
    
    self.navigationItem.title = @"Home";
    
    GradientAttributedButton *videoCameraButton = (GradientAttributedButton *)[self.view viewWithTag:1];
    GradientAttributedButton *stillCameraButton = (GradientAttributedButton *)[self.view viewWithTag:2];
    GradientAttributedButton *audioRecorder = (GradientAttributedButton *)[self.view viewWithTag:3];
    GradientAttributedButton *directorButton = (GradientAttributedButton *)[self.view viewWithTag:4];
   
    GradientAttributedButton *libraryButton = (GradientAttributedButton *)[self.view viewWithTag:5];
    GradientAttributedButton *scriptButton = (GradientAttributedButton *)[self.view viewWithTag:6];
    GradientAttributedButton *configButton = (GradientAttributedButton *)[self.view viewWithTag:7];
    GradientAttributedButton *helpButton = (GradientAttributedButton *)[self.view viewWithTag:8];
   
    videoCameraButton.enabled = YES;
    stillCameraButton.enabled = YES;
    directorButton.enabled = YES;
    libraryButton.enabled = YES;
    configButton.enabled = YES;
    helpButton.enabled = YES;
    audioRecorder.enabled = YES;
    scriptButton.enabled = YES;

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[[UtilityBag bag] standardFontBold] fontWithSize:15], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSString *bgColor = @"#666666";
    NSString *endColor = @"#333333";
    
    
    [videoCameraButton setTitle:[[NSAttributedString alloc] initWithString:@"Video Camera" attributes:strAttr]
             disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
  beginGradientColorString:bgColor
          endGradientColor:endColor];
    
    [stillCameraButton setTitle:[[NSAttributedString alloc] initWithString:@"Still Camera" attributes:strAttr]
             disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
  beginGradientColorString:bgColor
          endGradientColor:endColor];

    [audioRecorder setTitle:[[NSAttributedString alloc] initWithString:@"Audio Recorder" attributes:strAttr]
                  disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
       beginGradientColorString:bgColor
               endGradientColor:endColor];

    
    [directorButton setTitle:[[NSAttributedString alloc] initWithString:@"Camera Director" attributes:strAttr]
             disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
  beginGradientColorString:bgColor
          endGradientColor:endColor];
    
    [libraryButton setTitle:[[NSAttributedString alloc] initWithString:@"Video Library" attributes:strAttr]
             disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
  beginGradientColorString:bgColor
          endGradientColor:endColor];
    
    
    [scriptButton setTitle:[[NSAttributedString alloc] initWithString:@"Photo Library" attributes:strAttr]
             disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
  beginGradientColorString:bgColor
          endGradientColor:endColor];

    
    
    [configButton setTitle:[[NSAttributedString alloc] initWithString:@"Audio Library" attributes:strAttr]
              disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
   beginGradientColorString:bgColor
           endGradientColor:endColor];

    
    [helpButton setTitle:[[NSAttributedString alloc] initWithString:@"Story Editor" attributes:strAttr]
             disabledTitle:[[NSAttributedString alloc] initWithString:@"" attributes:strAttr]
  beginGradientColorString:bgColor
          endGradientColor:endColor];
   
    videoCameraButton.delegate = self;
    stillCameraButton.delegate = self;
    directorButton.delegate = self;
    configButton.delegate = self;
    libraryButton.delegate = self;
    helpButton.delegate = self;
    audioRecorder.delegate = self;
    scriptButton.delegate = self;
   
    [videoCameraButton update];
    [stillCameraButton update];
    [directorButton update];
    [configButton update];
    [libraryButton update];
    [helpButton update];
    [audioRecorder update];
    [scriptButton update];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popAndLoadPhotoLibrary:) name:@"popAndLoadPhotoLibrary" object:nil];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbarHidden = NO;
    self.toolbarItems = @[ [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedAbout)],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc] initWithTitle:@"Setup" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedSetup)],
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelp)],
                          ];
    
    
}

-(void)userTappedAbout {
    [[UtilityBag bag] logEvent:@"help" withParameters:nil];
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)userTappedSetup {
    [[UtilityBag bag] logEvent:@"setup" withParameters:nil];
    ConfigureViewController *configureVC = [[ConfigureViewController alloc] initWithNibName:@"ConfigureViewController" bundle:nil];
    configureVC.launchForPurchase = NO;
    configureVC.popInsteadOfNotificationForClose = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)userTappedHelp {
    [[UtilityBag bag] logEvent:@"help" withParameters:nil];
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)popAndLoadPhotoLibrary:(NSNotification *)n {
    [[PhotoManager manager] update];
    PhotoLibraryViewController *vc = [[PhotoLibraryViewController alloc] initWithNibName:@"PhotoLibraryViewController" bundle:nil];
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setViewControllers:@[ self, vc] animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.toolbarHidden = NO;
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"directorShutdown" object:nil];
    [super viewDidAppear:animated];
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    switch (tag) {
        case 1:
        {
            [[UtilityBag bag] logEvent:@"videoCamera" withParameters:nil];
            VideoCameraViewController *vc = [[VideoCameraViewController alloc] initWithNibName:@"VideoCameraViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
            [appD allowRotation:YES];
            [[LocationHandler tool] sendMotionUpdates:YES];
            [[UtilityBag bag] logEvent:@"stillCamera" withParameters:nil];
            StillCameraViewController *vc = [[StillCameraViewController alloc] initWithNibName:@"StillCameraViewController" bundle:nil];
            self.navigationController.toolbarHidden = YES;
            self.navigationController.navigationBarHidden = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 3:
        {
            NSString *nibName = @"AudioCaptureViewController";
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                nibName = [nibName stringByAppendingString:@"iPad"];
            }
        
            AudioCaptureViewController *vc = [[AudioCaptureViewController alloc] initWithNibName:nibName bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];

        }
            break;
        case 4:
        {
            [[UtilityBag bag] logEvent:@"director" withParameters:nil];
            self.navigationController.navigationBarHidden = NO;
            [[RemoteAdvertiserManager manager] stopSession];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [NSThread sleepForTimeInterval:0.3];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[RemoteBrowserManager manager] startSession];
                });
            });
            
            VideoSourcesCollectionViewController *vc = [[VideoSourcesCollectionViewController alloc] initWithNibName:@"VideoSourcesCollectionViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 5:
        {
            [[UtilityBag bag] logEvent:@"library" withParameters:nil];
            GridCollectionViewController *libraryVC = [[GridCollectionViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"GridCollectionViewController"] bundle:nil];
            [self.navigationController pushViewController:libraryVC animated:YES];
        }
            break;
        case 6:
        {
            [[UtilityBag bag] logEvent:@"photo" withParameters:nil];
            [[PhotoManager manager] update];
            PhotoLibraryViewController *libraryVC = [[PhotoLibraryViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"PhotoLibraryViewController"] bundle:nil];
            [self.navigationController pushViewController:libraryVC animated:YES];
        }
            break;
        case 7:
        {
            [[UtilityBag bag] logEvent:@"audio" withParameters:nil];
            [[AudioBrowser manager] update];
            AudioLibraryViewController *libraryVC = [[AudioLibraryViewController alloc] initWithNibName:@"AudioLibraryViewController" bundle:nil];
            [self.navigationController pushViewController:libraryVC animated:YES];
        }
            break;
        case 8:
        {
        }
            break;
    }
}

- (BOOL)shouldAutorotate  {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appD.allowRotation;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (NSUInteger)supportedInterfaceOrientations  {
    NSInteger supported = UIInterfaceOrientationMaskAll;
    return supported;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
}

@end
