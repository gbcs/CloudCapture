//
//  AddVideoArchiveOrgViewController.m
//  Capture
//
//  Created by Gary  Barnett on 2/25/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AddVideoArchiveOrgViewController.h"

@interface AddVideoArchiveOrgViewController ()

@end

@implementation AddVideoArchiveOrgViewController {
    
    NSURLSessionDownloadTask *task;
    NSURLSession *session;
    NSOperationQueue *queue;
    UIDynamicAnimator *animator;
    UIView *detailView;
    BOOL firstDownloadComplete;
}

@synthesize webview;

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (firstDownloadComplete) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateLibraryAndReload" object:nil];
    }
    [self cleanup];
}

-(void)cleanup {
    NSLog(@"AddVideoArchiveOrgViewController dealloc");
    
    [session finishTasksAndInvalidate];
    session = nil;
    task = nil;
    [queue cancelAllOperations];
    queue = nil;
    detailView = nil;
    animator = nil;
    webview.delegate = nil;
    webview = nil;
    
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
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
    self.navigationItem.title = @"archive.org Moving Image Archive";
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://archive.org/details/movies/"]]];
    queue = [NSOperationQueue mainQueue];
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:queue];
    
    self.toolbarItems = @[ [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(userTappedBack)],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(userTappedReload)],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
                           ];
    
        
}

-(void)userTappedBack {
    if (webview.canGoBack) {
        [webview goBack];
    }
}

-(void)userTappedReload {
    [webview reload];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!detailView) {
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200,-200,400,200)];
        [self.view addSubview:detailView];
        
        detailView.backgroundColor = [UIColor blackColor];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,400,150)];
        l.backgroundColor = [UIColor lightGrayColor];
        l.textColor = [UIColor whiteColor];
        l.textAlignment = NSTextAlignmentCenter;
        l.lineBreakMode = NSLineBreakByWordWrapping;
        l.numberOfLines = 0;
        l.text = @"Select the 'h.264' (preferred) or 'MPEG4' link under 'Individual Files' on a page with a video clip to download it to the App Library.\n\nPlease look for the Creative Commons (CC) link and review rights before downloading and/or using clips from this library.";
        l.tag = 1;
        [detailView addSubview:l];
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView ] ];
        CGFloat y = self.view.frame.size.height - 50;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            y = (self.view.frame.size.height / 2.0f) - 100;
        }
        [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
        [animator addBehavior:collision];
        [animator addBehavior:gravity];
        
        UIButton *faq = [[UIButton alloc] initWithFrame:CGRectMake(200, 150, 200, 44)];
        [faq setTitle:@"archive.org FAQ" forState:UIControlStateNormal];
        [faq addTarget:self action:@selector(userTappedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
        faq.tag = 0;
        [detailView addSubview:faq];
        
        UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake(0, 150, 200, 44)];
        [close setTitle:@"Ok" forState:UIControlStateNormal];
        [close addTarget:self action:@selector(userTappedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
        close.tag = 1;
        [detailView addSubview:close];
    }
    
}

-(void)userTappedInfoButton:(id)sender {
    UIButton *b = (UIButton *)sender;
    
    if (b.tag == 0) {
        [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://archive.org/about/faqs.php"]]];
    }
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [animator removeAllBehaviors];
    [animator addBehavior:gravity];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            animator = nil;
            [detailView removeFromSuperview];
            detailView = nil;
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"didFinishDownloadingToURL:%@", location);
}

/* Sent periodically to notify the delegate of download progress. */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"didWriteData:%@", @(totalBytesWritten));
    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"didBecomeInvalidWithError:%@", [error localizedDescription]);
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSLog(@"didReceiveChallenge:%@", challenge);
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    completionHandler(disposition, nil);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"didResumeAtOffset");
}

-(void)downloadFile:(NSURLRequest *)request withFilename:(NSString *)fname {
    if (detailView) {
        return;
    }
    
    NSString *urlStr = [request.URL absoluteString];
    NSLog(@"Download link:%@", urlStr);
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200,-200,400,200)];
    [self.view addSubview:detailView];
    
    detailView.backgroundColor = [UIColor blackColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,400,50)];
    l.backgroundColor = [UIColor lightGrayColor];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Downloading";
    l.tag = 1;
    [detailView addSubview:l];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activity.frame = CGRectMake(180,100,40,40);
    activity.color = [UIColor whiteColor];
    [detailView addSubview:activity];
    [activity startAnimating];
    activity.tag = 2;
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView ] ];
    CGFloat y = self.view.frame.size.height - 50;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = (self.view.frame.size.height / 2.0f) - 100;
    }
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    
    
    NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    NSMutableURLRequest *r = [request mutableCopy];
    [r setAllHTTPHeaderFields:headers];
    
    task = [session downloadTaskWithRequest:[r copy] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSString *fname2 = [[UtilityBag bag] pathForNewResourceWithExtension:@"mp4" suggestedFileName:fname];
            NSString *mp3File = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:fname2];
            [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:mp3File error:&error];
            if (error) {
                [self updateDetailMessage:@"Error saving file"];
            } else {
                [[UtilityBag bag] makeThumbnail:fname2];
                [self updateDetailMessage:@"Complete"];
                [webview performSelector:@selector(goBack) withObject:Nil afterDelay:0.25f];
                firstDownloadComplete = YES;
                [[SettingsTool settings] setHasDoneSomethingAdWorthy:YES];
            }
            
        } else {
            NSLog(@"download request:%@ error:%@", response.URL.absoluteString, [error localizedDescription]);
            [self updateDetailMessage:@"Error downloading file"];
        }
    }];
    
    [task resume];
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *urlStr = [request.URL absoluteString];
    NSLog(@"url:%@", urlStr);
    
    NSString *prefix = @"https://archive.org/download/";
    
    if ([urlStr hasPrefix:prefix] && [urlStr hasSuffix:@".mp4"]) {
        
        NSString *title = [urlStr lastPathComponent];
        NSLog(@"download:%@ title:%@", urlStr, title);

        [self downloadFile:request withFilename:[title stringByDeletingPathExtension]];
        return NO;
    }
    
    
    return YES;
}

-(void)updateDetailMessage:(NSString *)s {
    UILabel *l = (UILabel *)[detailView viewWithTag:1];
    l.text = s;
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [animator removeAllBehaviors];
    [animator addBehavior:gravity];
    
    UIActivityIndicatorView  *progress = (UIActivityIndicatorView *)[detailView viewWithTag:2];
    [progress stopAnimating];
    progress.hidden = YES;
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}



@end
