//
//  CameraViewController.m
//  Cloud Director
//
//  Created by Gary Barnett on 12/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CameraViewController.h"
#import "LabeledButton.h"
#import <CoreMotion/CoreMotion.h>
#import "AppDelegate.h"

@interface CameraViewController () {
    
    GLKView *previewView;
    CIContext *_ciContext;
    EAGLContext *_eaglContext;
    CGRect _videoPreviewViewBounds;
    UIDynamicAnimator *animator;
    UIView *presetView;
    NSArray *presetList;
    
    LabeledButton *zoomButton1;
    LabeledButton *zoomButton2;
    LabeledButton *zoomButton3;
 
    BOOL canZoom;
    
    CGImageRef image;
    CGImageRef oldImage;
    CIContext *context;
    BOOL pausePreview;
    CMAttitude *startingAttitude;
    CMDeviceMotion *lastMotion;
    BOOL galileoConnected;
    BOOL galileoVelocityModeEngaged;
    CGFloat lastRoll;
    CGFloat lastYaw;
    NSString *lastPreset;
    NSString *cameraName;
}

@end

@implementation CameraViewController
@synthesize cameraID;

-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    previewView = nil;
    _ciContext = nil;
    _eaglContext = nil;
    
    animator = nil;
    presetView = nil;
    
    presetList = nil;
    zoomButton1 = nil;
    zoomButton2 = nil;
    zoomButton3 = nil;
}



-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    while ([self.view.subviews count] >0) {
        [(UIView *)[self.view.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    [self dealloc2];
    
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)userTappedZoomButton1:(NSNotification *)n {
    [self sendMessage:@{@"cmd" : @"zoomButton1" }];
}

-(void)sendMessage:(NSDictionary *)dict {
     [[RemoteBrowserManager manager] sendMessage:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] toID:self.cameraID];
}

-(void)userTappedZoomButton2:(NSNotification *)n {
    [self sendMessage:@{@"cmd" : @"zoomButton2" }];
}

-(void)userTappedZoomButton3:(NSNotification *)n {
    [self sendMessage:@{@"cmd" : @"zoomButton3" }];
}

-(void)setupZoomButtons {

    if (!zoomButton1) {
        zoomButton1 = [[LabeledButton alloc] initWithFrame:CGRectZero];
        zoomButton2 = [[LabeledButton alloc] initWithFrame:CGRectZero];
        zoomButton3 = [[LabeledButton alloc] initWithFrame:CGRectZero];
        
        zoomButton1.caption = @"z1";
        zoomButton2.caption = @"z2";
        zoomButton3.caption = @"Z3";
        
        zoomButton1.notifyStringDown = @"userTappedZoomButton1";
        zoomButton2.notifyStringDown = @"userTappedZoomButton2";
        zoomButton3.notifyStringDown = @"userTappedZoomButton3";
    }
    
    [zoomButton1 justify:2];
    [zoomButton2 justify:2];
    [zoomButton3 justify:2];
    
    float x = previewView.frame.size.width - 44;
    float h = (previewView.frame.size.height - 50)/3;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [previewView addSubview:zoomButton1];
        [previewView addSubview:zoomButton2];
        [previewView addSubview:zoomButton3];
        zoomButton1.frame = CGRectMake(x, 70 + (h * 0), 44,44);
        zoomButton2.frame = CGRectMake(x, 70 + (h * 1), 44,44);
        zoomButton3.frame = CGRectMake(x, 70 + (h * 2), 44,44);
    } else {
        [self.view addSubview:zoomButton1];
        [self.view addSubview:zoomButton2];
        [self.view addSubview:zoomButton3];
        
        x = self.view.frame.size.width - 44;
        h = (self.view.frame.size.height - 50)/3;
        zoomButton1.frame = CGRectMake(x, 55 + (h * 0), 44,44);
        zoomButton2.frame = CGRectMake(x, 55 + (h * 1), 44,44);
        zoomButton3.frame = CGRectMake(x, 55 + (h * 2), 44,44);
    }

    if (!canZoom) {
        zoomButton1.hidden = YES;
        zoomButton2.hidden = YES;
        zoomButton3.hidden = YES;
    } else {
        zoomButton1.hidden = NO;
        zoomButton2.hidden = NO;
        zoomButton3.hidden = NO;
    }
 
}

-(void)previewDataForID:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSString *ID =  [args objectAtIndex:0];
    NSData *data = [args objectAtIndex:1];
    if (![self.cameraID isEqual:ID]) {
        return;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(data));
    image = CGImageCreateWithJPEGDataProvider (provider, NULL, true, kCGRenderingIntentDefault);
    
    if (oldImage) {
        CGImageRelease(oldImage);
    }
    
    oldImage = image;
    
    if (!context) {
        context = [CIContext contextWithEAGLContext:[EAGLContext currentContext]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (previewView) {
            CIImage *drawImage = [CIImage imageWithCGImage:image];
            [previewView bindDrawable];
            float scale = [UIScreen mainScreen].scale;
            
            [context drawImage:drawImage inRect:CGRectMake(0,0,previewView.bounds.size.width * scale, previewView.bounds.size.height * scale)  fromRect:drawImage.extent];
            [previewView display];
        }
        CGDataProviderRelease (provider);

        if (!pausePreview) {
            [self requestPreview];
        }
    });


}

-(void)requestPreview {
    NSDictionary *cmdDict = @{ @"cmd" : @"prv" };
    [[RemoteBrowserManager manager] sendMessage:[NSJSONSerialization dataWithJSONObject:cmdDict options:NSJSONWritingPrettyPrinted error:nil] toID:self.cameraID];
    
}

-(void)sourceDisconnected:(NSNotification *)n {
    NSString *sourceID = (NSString *)n.object;
    if ([self.cameraID isEqualToString:sourceID]) {
        dispatch_async(dispatch_get_main_queue(), ^{
             [self.navigationController popViewControllerAnimated:YES];
        });
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(motionUpdate:) name:@"motionUpdate" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPresetList:) name:@"showPresetList" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusDict:) name:@"statusDict" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceDisconnected:) name:@"sourceDisconnected" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedZoomButton1:) name:@"userTappedZoomButton1" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedZoomButton2:) name:@"userTappedZoomButton2" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedZoomButton3:) name:@"userTappedZoomButton3" object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewDataForID:) name:@"previewDataForID" object:nil];
    cameraName = [[VideoSourceManager manager] nameForSource:self.cameraID];
    self.navigationItem.title = cameraName;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"preset"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(userTappedPreset)];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : (id)CFBridgingRelease(colorSpace) } ];
    previewView.context = _eaglContext;

    self.navigationController.toolbarHidden  = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    
    self.toolbarItems = @[
                          [[UIBarButtonItem alloc] initWithTitle:@"Galileo" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedGalileoVelocity)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"barFocus"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(userTappedFocus)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"barExposure"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(userTappedExposure)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whiteBalance"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(userTappedWhiteBalance)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Picture" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedPicture)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Record" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedRecord)]
                          ];
    [self galileoVelocityButton].enabled = NO;
}

-(UIBarButtonItem *)galileoVelocityButton {
    return [self.toolbarItems objectAtIndex:0];
}

-(void)statusDict:(NSNotification *)n {
    NSArray *args = (NSArray *)n.object;
    NSString *ID = [args objectAtIndex:0];
    if (![self.cameraID isEqualToString:ID]) {
        return;
    }
    NSDictionary *status = [[args objectAtIndex:1] copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *focus = [self.toolbarItems objectAtIndex:2];
        UIBarButtonItem *exposure = [self.toolbarItems objectAtIndex:4];
        UIBarButtonItem *whiteBalance = [self.toolbarItems objectAtIndex:6];
        UIBarButtonItem *record = [self.toolbarItems objectAtIndex:10];
        
        focus.tintColor = ([[status objectForKey:@"f"] boolValue] == YES) ? [UIColor redColor] : [UIColor blueColor];
        exposure.tintColor = ([[status objectForKey:@"e"] boolValue] == YES) ? [UIColor redColor] : [UIColor blueColor];
        whiteBalance.tintColor = ([[status objectForKey:@"w"] boolValue] == YES) ? [UIColor redColor] : [UIColor blueColor];
        canZoom = [[status objectForKey:@"z"] boolValue];
    
        BOOL galStatus = [[status objectForKey:@"g"] boolValue];
        if (galileoConnected != galStatus) {
            galileoConnected = galStatus;
            [self galileoVelocityButton].enabled = galileoConnected;
            [[LocationHandler tool] sendMotionUpdates:galileoConnected || [[SettingsTool settings] horizonGuide] ];
            [self galileoVelocityButton].enabled = galileoConnected;
        }
        
        if (canZoom && (zoomButton1.hidden == YES)) {
            [self setupZoomButtons];
        } else if ( (!canZoom) && (zoomButton1.hidden == NO) ) {
            [self setupZoomButtons];
        }
       
        NSString *preset = [status objectForKey:@"p"];
        if ((!lastPreset) || (![lastPreset isEqualToString:preset])) {
            lastPreset = preset;
            self.navigationItem.title = [NSString stringWithFormat:@"%@ (%@)", cameraName, preset];
        }
      
        
        BOOL recording = [[status objectForKey:@"r"] boolValue];
        record.tintColor = (recording == YES) ? [UIColor redColor] : [UIColor blueColor];
        record.title = (recording == YES) ? @"Stop" : @"Record";
    });
}

-(void)showPresetList:(NSNotification *)n {
    if (presetView) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        presetList = (NSArray *)n.object;
        
        presetView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 150, -200, 300, 200)];
        presetView.backgroundColor = [UIColor whiteColor];
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,300,50)];
        l.textColor = [UIColor whiteColor];
        l.backgroundColor = [UIColor darkGrayColor];
        l.text = @"Select A Preset";
        l.textAlignment = NSTextAlignmentCenter;
        [presetView addSubview:l];
        
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectMake(0,50,300,150)];
        tv.delegate = self;
        tv.dataSource = self;
        [presetView addSubview:tv];
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(240, 3, 50, 44)];
        [closeButton setTitle:@"Close" forState:UIControlStateNormal];
        [closeButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(userTappedPresetClose) forControlEvents:UIControlEventTouchUpInside];
        [presetView addSubview:closeButton];

        closeButton.tag = -1;
        tv.tag = -1;
        l.tag = -2;
        
        [self.view addSubview:presetView];
        
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ presetView ] ];
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ presetView ] ];
        CGFloat y = self.view.frame.size.height - 50;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            y = self.view.frame.size.height - 300;
        }
        
        [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, y) toPoint:CGPointMake(self.view.frame.size.width, y)];
        [animator addBehavior:collision];
        [animator addBehavior:gravity];

    });
}

-(void)userTappedPresetClose {
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ presetView ] ];
    [animator removeAllBehaviors];
    [animator addBehavior:gravity];
    [self performSelector:@selector(removePresetView) withObject:nil afterDelay:1.0f];
}

-(void)removePresetView {
    [animator removeAllBehaviors];
    animator = nil;
    [presetView removeFromSuperview];
    presetView = nil;
}

-(void)userTappedFocus {
    [self sendMessage:@{@"cmd" : @"focus" }];
}

-(void)userTappedExposure {
    [self sendMessage:@{@"cmd" : @"exposure" }];
}

-(void)userTappedWhiteBalance {
    [self sendMessage:@{@"cmd" : @"whiteBalance" }];
}

-(void)userTappedPreset {
    [self sendMessage:@{@"cmd" : @"preset" }];
}

-(void)userTappedRecord {
     [self sendMessage:@{@"cmd" : @"record" }];
}

-(void)updateViewPositions {
    CGRect r = CGRectMake(45,60,390,220);
    if (self.view.frame.size.width == 568.0f) {
        r = CGRectMake(88,60,391,220);
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            r = CGRectMake(0,96,1024,574);
        } else {
            r = CGRectMake(0,296,768,432);
        }
    }
    
    if (!previewView) {
        previewView = [[GLKView alloc] initWithFrame:r context:_eaglContext];
        [self.view addSubview:previewView];
    } else {
        previewView.frame = r;
    }
    
    [self setupZoomButtons];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateViewPositions];
    
   
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    pausePreview = NO;
    [self performSelector:@selector(requestPreview) withObject:nil afterDelay:0.45];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    pausePreview = YES;
}


-(void)userTappedClose {
    pausePreview = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *presetName = [presetList objectAtIndex:indexPath.row];
    pausePreview = YES;
    
    while ([presetView viewWithTag:-1]) {
        UIView *v = [presetView viewWithTag:-1];
        [v removeFromSuperview];
    }
    
    UILabel *t = (UILabel *)[presetView viewWithTag:-2];
    t.text = @"Loading Preset";
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,50,300,150)];
    l.backgroundColor = [UIColor whiteColor];
    l.textColor = [UIColor blackColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = presetName;
    [presetView addSubview:l];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
           [self sendMessage:@{@"cmd" : @"loadPreset", @"attr" : presetName}];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [NSThread sleepForTimeInterval:3.0f];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     pausePreview = NO;
                     [self sendMessage:@{@"cmd" : @"prv"}];
                     [self userTappedPresetClose];
                 });
            });
        });
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   return 44.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    
    if (presetList) {
        count = [presetList count];
    }
    
	return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [presetList objectAtIndex:indexPath.row];
    
    return cell;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateViewPositions];
}

-(void)handlePreviewImage:(NSData *)previewData {
    
}

-(void)motionUpdate:(NSNotification *)n {
    lastMotion = (CMDeviceMotion *)n.object;
    
    if (!startingAttitude) {
        return;
    }
    
    CMAttitude *delta = [lastMotion.attitude copy];
    [delta multiplyByInverseOfAttitude:startingAttitude];
    //NSLog(@"attitude delta:%@", delta);
    
    CGFloat roll = 0.0f;
    CGFloat pitch = 0.0f;
    
    CGFloat r = delta.roll * 57.2957795;
    CGFloat y = delta.pitch * 57.2957795;
    
    if (r < -25) {
        roll = 12;
    } else if (r > 25) {
        roll = -12;
    }
    
    if (y < -25) {
        pitch = -12;
    } else if (y > 25) {
        pitch = 12;
    }
    
    
    
    if ( (lastRoll != roll) || (lastYaw != pitch) ) {
        lastYaw = pitch;
        lastRoll = roll;
        NSDictionary *dict =@{ @"cmd" : @"galileoVelocity", @"attr" : @{ @"tilt" : @(roll), @"pan" : @(pitch) }  };
        NSLog(@"GalileoCommand:%@", dict);
        [[RemoteBrowserManager manager] sendMessage:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] toID:self.cameraID];
    }
}

-(void)motionCircleCenterTapped:(id)sender {
    startingAttitude = [lastMotion.attitude copy];
}

-(void)userTappedGalileoVelocity {
    galileoVelocityModeEngaged = !galileoVelocityModeEngaged;
    [self galileoVelocityButton].tintColor = galileoVelocityModeEngaged ? [UIColor greenColor] : nil;
    

    if (!galileoVelocityModeEngaged) {
        startingAttitude = nil;
        return;
    }
    
    startingAttitude = [lastMotion.attitude copy];
}

-(void)userTappedPicture {
    [self sendMessage:@{@"cmd" : @"picture" }];
}




@end
