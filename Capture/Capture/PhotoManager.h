//
//  PhotoManager.h
//  Capture
//
//  Created by Gary Barnett on 10/29/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoManager : NSObject


+(PhotoManager *)manager;

-(BOOL)isReady;

-(void)update;
-(void)cleanup;

-(NSArray *)groups;
-(NSInteger )groupEntryCount:(NSInteger)index;
-(ALAsset *)entryForGroupAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index;
-(NSDictionary *)photoDictForRemote;
-(NSArray *)emptyGroups;
-(NSArray *)masterGroupList;
-(NSArray *)masterGroupAssetList;

-(void)updateUnreviewedStillDataSource;
-(NSArray *)unreviewedStillGroups;
-(NSInteger )unreviewedStillGroupEntryCount:(NSInteger)index;
-(NSString *)nameForUnreviewedStillGroupAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index;

-(void)moveDataAtPathToCameraRoll:(NSString *)path andMasterGroupIndex:(NSInteger )index;
-(void)addPhotoAlbumWithName:(NSString *)name;

@end
