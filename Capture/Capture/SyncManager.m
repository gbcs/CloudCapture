//
//  SyncManager.m
//  Capture
//
//  Created by Gary Barnett on 7/19/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "SyncManager.h"
#import <DropboxSDK/DropboxSDK.h>
#import "GSDropboxActivity.h"
#import "AppDelegate.h"

@implementation SyncManager {
    
    UIView *progressContainer;
    UIProgressView *progressView;
    UILabel *progressLabel;

}

static SyncManager  *sharedSettingsManager = nil;

+ (SyncManager *)manager
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
        
      
        
        
    }
    
    return sharedSettingsManager ;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self manager];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(BOOL)handleOpenURL:(NSURL *)url {
    
    BOOL useDropbox = YES;
    
    BOOL handled = NO;
    
    if ((!handled) && useDropbox) {
       if ([[DBSession sharedSession] handleOpenURL:url]) {
            if ([[DBSession sharedSession] isLinked]) {
                NSLog(@"App linked successfully!");
            }
           handled = YES;
        }
    }
    
    return handled;
}


-(UIView *)progressContainer {
    return progressContainer;
}

-(void)updateProgress:(CGFloat)progress {
    progressView.progress = progress;
}

-(void)updateProgressTitle:(NSString *)title {
    progressLabel.text = title;
}

-(void)prepareUploadTargets {
    
    if (!progressContainer) {
        progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0,2,140,30)];
        progressContainer.backgroundColor = [UIColor clearColor];
        
        progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(5,3,70,10)];
        [progressLabel setFont:[UIFont systemFontOfSize:10.0]];
        [progressLabel setTextColor:[UIColor colorWithWhite:0.8 alpha:1.0]];
        [progressContainer addSubview:progressLabel];
        
        progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        [progressView setProgressTintColor:[UIColor redColor]];
        [progressContainer addSubview:progressView];
        progressView.frame = CGRectMake(5, 20, 130, 3);
    }
    
    [self prepareDropbox];
}

-(void)prepareDropbox {
    NSString *dropboxAppKey = @"157tdk1b315pjk8";
    NSString *dropboxAppSecret = @"9drr1uml45jb8os";
    NSString *dropboxRoot = kDBRootDropbox;
    
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:dropboxAppKey
                                                   appSecret:dropboxAppSecret
                                                        root:dropboxRoot];
    [DBSession setSharedSession:dbSession];

}

-(BOOL)loginToUploadTargets {
    
    BOOL okToProceed = YES;
    
    okToProceed = [self loginToDropbox];
    
    return okToProceed;
}

-(BOOL)loginToDropbox {
   
    BOOL useDropbox = YES;
    
    if (!useDropbox) {
        return YES;
    }
    
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:[appD.navController.viewControllers lastObject]];
        return NO;
    }
    
    return YES;
}


@end
