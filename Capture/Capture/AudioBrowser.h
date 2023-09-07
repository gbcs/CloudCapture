//
//  AudioBrowser.h
//  Capture
//
//  Created by Gary Barnett on 12/10/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AudioBrowser : NSObject

+(AudioBrowser *)manager;

-(BOOL)isReady;
-(void)update;
-(void)cleanup;

-(NSArray *)artists;
-(NSInteger )songCountForArtistAtIndex:(NSInteger )index;

-(MPMediaItem *)entryForArtistAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index;

-(NSString *)entryforAppLibraryAtIndex:(NSInteger) index;

-(UIImage *)artworkForArtistAtIndex:(NSInteger )index withSize:(CGSize )size;

-(void)removeAppLibraryAudioItemAtIndex:(NSInteger)index;

-(NSInteger )durationforAppLibraryAtIndex:(NSInteger) index;

-(void)generateAudioSampleWithDuration:(NSInteger )duration;

-(NSDictionary *)audioDictForRemote;

@end
