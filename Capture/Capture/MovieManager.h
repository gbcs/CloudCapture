//
//  MovieManager.h
//  Capture
//
//  Created by Gary Barnett on 9/6/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>


@interface MovieManager : NSObject
+(MovieManager *)manager;

-(void)playClipAtPath:(NSString *)videoPath;
-(void)playClipWithURL:(NSURL *)url;
-(void)closePlayer;
@end
