//
//  MovieManager.m
//  Capture
//
//  Created by Gary Barnett on 9/6/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "MovieManager.h"
#import "AppDelegate.h"

@implementation MovieManager {
    __strong MPMoviePlayerController *movieController;
    __strong MPMoviePlayerViewController *movieViewController;
}

static MovieManager  *sharedSettingsManager = nil;

+ (MovieManager *)manager
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

-(void)playClipAtPath:(NSString *)videoPath {
    [[AudioManager manager] playbackMode:YES];
    
    NSURL* videoURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:videoPath]];
    [self playClipWithURL:videoURL];
}

-(void)closePlayer {
    if (movieViewController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [movieController stop];
        [movieViewController dismissMoviePlayerViewControllerAnimated];
        movieViewController = nil;
        movieController = nil;
    }
    
    [[AudioManager manager] resetForCaptureAfterMoviePlayer];
}

-(void)playClipWithURL:(NSURL *)url {
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
    [[AudioManager manager] setupForMoviePlayer];
   
    if (!movieViewController) {
        movieViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [movieViewController.moviePlayer setAllowsAirPlay:YES];
        movieController = movieViewController.moviePlayer;
        [appD.navController presentMoviePlayerViewControllerAnimated:movieViewController];
    } else {
        [movieController stop];
        [movieViewController.moviePlayer setContentURL:url];
    }
    
    [movieController performSelector:@selector(play) withObject:nil afterDelay:0.5];
}

-(void)movieFinished {
   
    [self closePlayer];
}


@end
