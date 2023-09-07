//
//  AppDelegate.m
//  Capture
//
//  Created by Gary Barnett on 7/4/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "SettingsTool.h"
#import "AudioManager.h"
#import "CreateMovieViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FirstStartViewController.h"
#import "NoCameraFoundViewController.h"
#import "Flurry.h"
#import "LaunchPadViewController.h"
#import "ConfigureViewController.h"
#import "HelpViewController.h"
#import "GridCollectionViewController.h"


@implementation AppDelegate {
    SettingsTool *settingsTool;
    AudioManager *audioMgr;
    StatusReporter *statusReporter;
    UtilityBag *utilityBag;
        //    HTTPServer *httpServer;
 
    BOOL noCameraWasFound;
}

-(void)allowRotation:(BOOL)allowed {
    self.allowRotation = allowed;
}

-(void)batteryChanged:(NSNotification *)n {
    
}


-(void)standardStartupOptions {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryChanged:) name:@"UIDeviceBatteryLevelDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryChanged:) name:@"UIDeviceBatteryStateDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeAfterFirstStart:) name:@"resumeAfterFirstStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NoCameraFound) name:@"NoCameraFound" object:nil];

}

-(void)NoCameraFound {
    noCameraWasFound = YES;
    NoCameraFoundViewController *vc = [[NoCameraFoundViewController alloc] initWithNibName:@"NoCameraFoundViewController" bundle:nil];
    [self.window setRootViewController:vc];
}

typedef int (*PYStdWriter)(void *, const char *, int);
static PYStdWriter _oldStdWrite;

int __pyStderrWrite(void *inFD, const char *buffer, int size)
{
    if ( strncmp(buffer, "AssertMacros:", 13) == 0 ) {
        return 0;
    }
    return _oldStdWrite(inFD, buffer, size);
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {

    BOOL handled = [[SyncManager manager] handleOpenURL:url];

    return handled;
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //Flurry
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"HGN8BQ465HCHVJ9PB53M"];
   
    NSError *error = nil;
   
    NSString *metaPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"];
    [[NSFileManager defaultManager] createDirectoryAtPath:metaPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    NSString *backgroundPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"];
    [[NSFileManager defaultManager] createDirectoryAtPath:backgroundPath withIntermediateDirectories:NO attributes:nil error:&error];
   
    NSString *titlingPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"titlingPages"];
    [[NSFileManager defaultManager] createDirectoryAtPath:titlingPath withIntermediateDirectories:NO attributes:nil error:&error];
   
    NSString *presetPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"presetFiles"];
    [[NSFileManager defaultManager] createDirectoryAtPath:presetPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    NSString *webPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"Web"];
    [[NSFileManager defaultManager] createDirectoryAtPath:webPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    NSString *photoPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"];
    [[NSFileManager defaultManager] createDirectoryAtPath:photoPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    
    NSString *stillPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"unreviewedStills"];
    [[NSFileManager defaultManager] createDirectoryAtPath:stillPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    
    [self standardStartupOptions];
    	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    _window.tintColor = [[UtilityBag bag] colorWithHexString:@"#f5deb3" withAlpha:1.0];
    
    settingsTool = [SettingsTool settings];
    utilityBag = [UtilityBag bag];
    
    self.allowRotation = YES;
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
      [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
    }
    
    BOOL firstStartupComplete = [[[NSUserDefaults standardUserDefaults] objectForKey:@"firstStartup"] boolValue];
    
    if (firstStartupComplete) {
        [self continueRegularStartup];
    } else {
        NSString *nibName = @"FirstStartViewController";
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            nibName = [nibName stringByAppendingString:@"iPad"];
        }
        
        FirstStartViewController *vc = [[FirstStartViewController alloc] initWithNibName:nibName bundle:nil];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [self.window setRootViewController:nav];
    }

    [self.window makeKeyAndVisible];
    return YES;
}

-(void)continueRegularStartup {
    statusReporter = [[StatusReporter alloc] init];
    [statusReporter startup];
    
    
    if ([[SettingsTool settings] engineRemote]) {
        [self handleRemoteSessionSetup];
    }
   
    [[SyncManager manager] prepareUploadTargets];
    [[PurchaseObject manager] updatePurchaseStatus];
   
    [self performSelector:@selector(startStore) withObject:nil afterDelay:8.0f];
    /*
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
     
        iPadTabController *tc = [[iPadTabController alloc] init];
        PlaceholderViewController *pl1 = [[PlaceholderViewController alloc] initWithNibName:@"PlaceholderViewController" bundle:nil];
        PlaceholderViewController *pl2 = [[PlaceholderViewController alloc] initWithNibName:@"PlaceholderViewController" bundle:nil];
        GridCollectionViewController *grid = [[GridCollectionViewController alloc] initWithNibName:@"GridCollectionViewControlleriPad" bundle:nil];
        PlaceholderViewController *pl4 = [[PlaceholderViewController alloc] initWithNibName:@"PlaceholderViewController" bundle:nil];
        PlaceholderViewController *pl5 = [[PlaceholderViewController alloc] initWithNibName:@"PlaceholderViewController" bundle:nil];
        
        pl1.index = 1;
        pl2.index = 2;
        pl4.index = 4;
        pl5.index = 5;
        
        NavController *nav1 = [[NavController alloc] initWithRootViewController:pl1];
        NavController *nav2 = [[NavController alloc] initWithRootViewController:pl2];
        NavController *nav3 = [[NavController alloc] initWithRootViewController:grid];
        NavController *nav4 = [[NavController alloc] initWithRootViewController:pl4];
        NavController *nav5 = [[NavController alloc] initWithRootViewController:pl5];
       
        [tc setViewControllers:@[nav1, nav2, nav3, nav4, nav5 ] animated:NO];
        
        UITabBarItem *item = [tc.tabBar.items objectAtIndex:0];
        item.title = @"Video Camera";
        item = [tc.tabBar.items objectAtIndex:1];
        item.title = @"Still Camera";
        item = [tc.tabBar.items objectAtIndex:2];
        item.title = @"Edit Studio";
        item = [tc.tabBar.items objectAtIndex:3];
        item.title = @"Setup";
        item = [tc.tabBar.items objectAtIndex:4];
        item.title = @"Help  ";
        
        [self.window setRootViewController:tc];

        _splitVC = [[SplitViewController alloc] init];
        
        GridCollectionViewController *grid = [[GridCollectionViewController alloc] initWithNibName:@"GridCollectionViewControlleriPad" bundle:nil];
        NavController *nav3 = [[NavController alloc] initWithRootViewController:grid];
        
        [_splitVC setViewControllers:@[ [[iPadLaunchPadViewController alloc] initWithNibName:@"iPadLaunchPadViewController" bundle:nil], nav3 ]];
        [self.window setRootViewController:_splitVC];
    } else {
        LaunchPadViewController *vc = [[LaunchPadViewController alloc] initWithNibName:@"LaunchPadViewController" bundle:nil];
        _navController = [[NavController alloc] initWithRootViewController:vc];
        [self.window setRootViewController:_navController];
    }

*/
    
    LaunchPadViewController *vc = [[LaunchPadViewController alloc] initWithNibName:@"LaunchPadViewController" bundle:nil];
    _navController = [[NavController alloc] initWithRootViewController:vc];
    [self.window setRootViewController:_navController];

    [AppsfireSDK connectWithAPIKey:@"DD7B9A8EC98C74C9EDA2829B7E524191"];
    [AppsfireSDK setFeatures:AFSDKFeatureMonetization];
#ifdef DEBUG
    [AppsfireAdSDK setDebugModeEnabled:YES];
#endif
    [AppsfireAdSDK prepare];

}

-(void)resumeAfterFirstStart:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(YES) forKey:@"firstStartup"];
        [defaults synchronize];
        [self continueRegularStartup];
    });
}

-(UIViewController *)rootController {
    return self.window.rootViewController;
}

-(void)startStore {
     [[SKPaymentQueue defaultQueue] addTransactionObserver:[PurchaseObject manager]];
}

-(void)askForMicrophone {
    AVAudioSession *audioSession = [[AVAudioSession alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [audioSession requestRecordPermission:^ (BOOL granted){
            self.audioRecordingAllowed = granted;
        }];
    });
    
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {} failureBlock:^(NSError *error) {}];
    }
}


-(void)stopRemoteSessions {
    [[RemoteAdvertiserManager manager] stopAdvertiser];
    [[RemoteAdvertiserManager manager] stopSession];
}

-(void)handleRemoteSessionSetup {
    BOOL stopSession = NO;
  
    if ([[SettingsTool settings] fastCaptureMode]) {
        stopSession = YES;
    }
    
    if (![[SettingsTool settings] engineRemote]) {
        stopSession = YES;
    }
    
    if (stopSession) {
        [self stopRemoteSessions];
    } else if (![RemoteAdvertiserManager manager].advertising) {
        [[RemoteAdvertiserManager manager] startSession];
        [[RemoteAdvertiserManager manager] startAdvertiser];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    _wasInterrupted = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"firstStartup"] boolValue]) {
        [[AudioManager manager] shutdown];
        [[LocationHandler tool] shutdown];
        [[GalileoHandler tool] shutdown];
        [self stopRemoteSessions];
    }
    _wasInterrupted = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"stopCameraForPlayback" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //if (![_containerVC cameraIsRunning]) {
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"restartCameraForFeatureChange" object:nil];
    //}
     [[NSNotificationCenter defaultCenter] postNotificationName:@"returnedFromSuspend" object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"firstStartup"] boolValue]) {
        [[AudioManager manager] startup];
        [[LocationHandler tool] performSelector:@selector(startup) withObject:nil afterDelay:0.15];
        [[GalileoHandler tool] performSelector:@selector(startup) withObject:nil afterDelay:0.25];
        [self performSelector:@selector(handleRemoteSessionSetup) withObject:nil afterDelay:0.5];
        
    }

    _wasInterrupted = NO;
#ifdef CCFREE
    [AppsfireSDK connectWithAPIKey:@"DD7B9A8EC98C74C9EDA2829B7E524191"];
#endif
}


-(void)sendCameraStartCommand {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"restartCameraForFeatureChange" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
    
}

@end
