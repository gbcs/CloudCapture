//
//  AssetManager.h
//  Capture
//
//  Created by Gary Barnett on 9/14/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AssetManager : NSObject 


+(AssetManager *)manager;

-(BOOL)isReady;

-(void)update;
-(void)cleanup;

-(NSArray *)groups;
-(ALAssetsGroup *)groupForIndex:(NSInteger)index;
-(NSInteger )groupEntryCount:(NSInteger)index;
-(ALAsset *)entryForGroupAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index;

-(NSArray *)emptyGroups;
-(void)moveClipToAlbum:(NSString *)filePath;
-(void)copyClipToAppLibrary:(NSURL *)clipURL;
-(NSArray *)sortCutList:(NSArray *)cutList;

-(NSDictionary *)videoDictForRemote;
-(NSArray *)videoList;

-(void)cleanupMoviePhotosTemp;

@end
