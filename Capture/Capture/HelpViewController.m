//
//  HelpViewController.m
//  Capture
//
//  Created by Gary Barnett on 7/18/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController () {
    UIDynamicAnimator *animator;
    UIView *upgradeView;
    UIProgressView *progress;
    NSOperationQueue *queue;
    NSURLSession *session;
    NSInteger updatedHelpVersion;
}

@end

@implementation HelpViewController

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
    self.navigationItem.title = @"Help";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];

}

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
    NSLog(@"%@:%s", [self class], __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    queue = nil;
    session = nil;
    
    animator = nil;
    upgradeView = nil;
    progress = nil;
    
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    _webView.delegate = nil;
    _webView = nil;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
   
    if (!self.backOnly) {
            //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose:)];
    }
    
    if (self.noCloseButton) {
            //  self.navigationItem.rightBarButtonItem = nil;
            // self.navigationItem.leftBarButtonItem = nil;
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"pdf"];
    
    NSInteger curVersion = [[SettingsTool settings] currentHelpVersion];
    if (curVersion > 1) {
        filePath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:@"help.pdf"];
    }
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSString *helpVersionStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://cloudcapt.com/help_version"] encoding:NSStringEncodingConversionAllowLossy error:&error];
        updatedHelpVersion = [helpVersionStr integerValue];
        if (!error) {
            if ([[SettingsTool settings] currentHelpVersion] < updatedHelpVersion) {
                    [NSThread sleepForTimeInterval:2.0f];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        upgradeView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width /2.0f) - 125, -200, 250,250)];
                        upgradeView.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#f5a372" withAlpha:1.0];
                        
                        GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(10, 190, 110, 44)];
                        button.delegate = self;
                        button.tag = 0;
                        
                        GradientAttributedButton *button2 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(250 - 120, 190, 110, 44)];
                        button2.delegate = self;
                        button2.tag = 1;
                        
        
                        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                        paragraphStyle.alignment     = NSTextAlignmentCenter;
                        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
                        
                        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                                  [[[UtilityBag bag] standardFontBold] fontWithSize:15], NSFontAttributeName,
                                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                                  ];
                        
                        NSString *bColor = @"#666666";
                        NSString *eColor = @"#333333";
                        
                        
                        NSAttributedString *buttonTitle =[[NSAttributedString alloc] initWithString:@"Download" attributes:strAttr];
                        [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
                        button.enabled = YES;
                        [button update];
                        
                        NSAttributedString *buttonTitle2 =[[NSAttributedString alloc] initWithString:@"Not Now" attributes:strAttr];
                        [button2 setTitle:buttonTitle2 disabledTitle:buttonTitle2 beginGradientColorString:bColor endGradientColor:eColor];
                        button2.enabled = YES;
                        [button2 update];
                        
                        [upgradeView addSubview:button];
                        [upgradeView addSubview:button2];
                   
                        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,250,50)];
                        label.text = @"Update Available";
                        label.font = [UIFont boldSystemFontOfSize:17];
                        label.textAlignment = NSTextAlignmentCenter;
                        [upgradeView addSubview:label];
                        
                        UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0,70,250,100)];
                        label2.text = @"Updated documentation is available for download";
                        label2.textAlignment = NSTextAlignmentCenter;
                        label2.numberOfLines = 2;
                        [upgradeView addSubview:label2];
                        
                        [self.view addSubview:upgradeView];
                        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
                        
                        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ upgradeView ] ];
                        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ upgradeView ] ];
                        
                        CGFloat bottomY = self.view.frame.size.height - 20;
                        if (bottomY > 568) {
                            bottomY = 450;
                        }
                        
                        [collision addBoundaryWithIdentifier:@"detailView" fromPoint:CGPointMake(0, bottomY) toPoint:CGPointMake(self.view.frame.size.width, bottomY)];
                        
                        [animator addBehavior:gravity];
                        [animator addBehavior:collision];


                    });
            }
        }
        
    });
    

}

-(void)finishAnimation {
    [animator removeAllBehaviors];
    animator = nil;
    [upgradeView removeFromSuperview];
    upgradeView = nil;
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (tag == 0) {
            for (NSObject *o in upgradeView.subviews) {
                if ([o isKindOfClass:[GradientAttributedButton class]]) {
                    GradientAttributedButton *b = (GradientAttributedButton *)o;
                    b.enabled = NO;
                    [b update];
                }
            }
            
            progress = [[UIProgressView alloc] initWithFrame:CGRectMake(5,80,240,5)];
            progress.progressViewStyle = UIProgressViewStyleBar;
            progress.progress = 0.0f;
            [upgradeView addSubview:progress];
            
            NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://cloudcapt.com/Help_1_%ld.pdf", (long)updatedHelpVersion]];
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];
            queue = [[NSOperationQueue alloc] init];
            [queue setMaxConcurrentOperationCount:1];
            [queue setName:@"Help Download Queue"];
            
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
            
            session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
            
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
            [downloadTask resume];
            return;
        } else if (tag == 1) {
            [self closeAnimation];
        }
    });
}

- (void)URLSession:(NSURLSession *)s downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *helpPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:@"help.pdf"];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:helpPath error:&error];
    [[NSFileManager defaultManager] copyItemAtURL:location toURL:[NSURL fileURLWithPath:helpPath] error:&error];
    [NSThread sleepForTimeInterval:3];
    [session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
       dispatch_async(dispatch_get_main_queue(), ^{
           UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Upgrade Problem" message:@"Unable to complete the download of the updated help file." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
           [alert show];
           [self performSelector:@selector(closeAnimation) withObject:nil afterDelay:1.0f];
       });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(closeAnimation) withObject:nil afterDelay:1.0f];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSString *helpPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:@"help.pdf"];
                
                [[SettingsTool settings] setCurrentHelpVersion:updatedHelpVersion];
                [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:helpPath]]];
            }
           
        });
        
    }
}

-(void)closeAnimation {
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ upgradeView] ];
    [animator removeAllBehaviors];
    [animator addBehavior:gravity];
    [self performSelector:@selector(finishAnimation) withObject:nil afterDelay:1.0f];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (totalBytesExpectedToWrite > 0) {
            progress.progress = (float)(totalBytesExpectedToWrite / totalBytesWritten);
        } else {
            progress.progress = 0.50f;
        }
    });
}

- (void)URLSession:(NSURLSession *)s didBecomeInvalidWithError:(NSError *)error {
    s = nil;
}
-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webView stopLoading];
    [self.webView loadRequest:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)userTappedClose:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
