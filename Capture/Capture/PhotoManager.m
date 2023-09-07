//
//  PhotoManager.m
//  Capture
//
//  Created by Gary Barnett on 10/29/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "PhotoManager.h"

@implementation PhotoManager{
    BOOL ready;
    ALAssetsLibrary *assetLibrary;
    NSMutableArray *groups;
    NSMutableArray *emptyGroups;
    NSMutableArray *groupAssets;
    NSMutableArray *masterGroupList;
    
    NSMutableDictionary *currentGroupDict;
    
    NSArray *unreviewedStillGroupList;
    NSMutableDictionary *unreviewedStillGroupDict;
    
}

static PhotoManager  *sharedSettingsManager = nil;

+ (PhotoManager *)manager
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

-(void)cleanup {
    ready = NO;

    [groups removeAllObjects];
    [emptyGroups removeAllObjects];
    [groupAssets removeAllObjects];
    [masterGroupList removeAllObjects];
    [currentGroupDict removeAllObjects];
}

-(void)addGroup:(ALAssetsGroup *)group {
    if ([groups indexOfObject:group] == NSNotFound) {
        [groups addObject:group];
        [groupAssets addObject:currentGroupDict];
        currentGroupDict = nil;
    }
    
    if ([emptyGroups indexOfObject:group] != NSNotFound) {
        [emptyGroups removeObject:group];
    }
}

-(NSArray *)emptyGroups {
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[emptyGroups count]];
    
    for (ALAssetsGroup *group in emptyGroups) {
        NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
        [list addObject:name ? name : @"Unnamed Group" ];
    }
    
    return [list copy];
}

-(NSArray *)masterGroupAssetList {
    return masterGroupList;
}

-(NSArray *)masterGroupList {
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[masterGroupList count]];
    
    for (ALAssetsGroup *group in masterGroupList) {
        NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
        [list addObject:name ? name : @"Unnamed Group" ];
    }
    
    NSMutableArray *reverse = [[NSMutableArray alloc] initWithCapacity:[list count]];
    for (id obj in [list reverseObjectEnumerator]) {
        [reverse addObject:obj];
    }
    return [reverse copy];
}

-(void)update {
    ready = NO;
    
    [self updateUnreviewedStillDataSource];
    
    if (assetLibrary) {
        assetLibrary = nil;
    }
    
    assetLibrary = [[ALAssetsLibrary alloc] init];
    
    [emptyGroups removeAllObjects];
    [groups removeAllObjects];
    [groupAssets removeAllObjects];
    
    groups = [[NSMutableArray alloc] initWithCapacity:10];
    masterGroupList = [[NSMutableArray alloc] initWithCapacity:10];
    emptyGroups = [[NSMutableArray alloc] initWithCapacity:10];
    groupAssets = [[NSMutableArray alloc] initWithCapacity:10];
    
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        ready = YES;
        return;
    }

    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!group) {
            ready = YES;
        } else {
            [emptyGroups addObject:group];
            [masterGroupList addObject:group];
            currentGroupDict = [[NSMutableDictionary alloc] initWithCapacity:10];
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if(result && [[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                    [self addEntry:result];
                } else if ( (!result) && ([currentGroupDict count]>0) ) {
                    [self addGroup:group];
                }
            }];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"failure reading asset groups:%@", error);
        ready = YES;
    }];
}

-(void)addEntry:(ALAsset *)asset {
    NSInteger index = [currentGroupDict count];
    [currentGroupDict setObject:asset forKey:[NSNumber numberWithInteger:index]];
}

-(BOOL)isReady {
    return ready;
}

-(NSArray *)groups {
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[groups count]];
    
    for (ALAssetsGroup *group in groups) {
        NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
        [list addObject:name ? name : @"Unnamed Group" ];
    }
    
    return [list copy];
}

-(NSInteger )groupEntryCount:(NSInteger )index {
    NSDictionary *groupDict = [groupAssets objectAtIndex:index];
    
    return [groupDict count];
}

-(ALAsset *)entryForGroupAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index {
    NSDictionary *groupDict = [groupAssets objectAtIndex:libIndex];
    
    return [groupDict objectForKey:[NSNumber numberWithInteger:index]];
}

-(NSDictionary *)photoDictForRemote {
    NSDictionary *dict = @{ };
    
    return @{ @"cmd" : @"libraryPhoto", @"attr" : dict };
}

-(NSString *)basePath {
    return [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"unreviewedStills"];
}

-(void)updateUnreviewedStillDataSource {
    NSError *error = nil;
    NSArray *unsortedList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self basePath] error:&error];
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsPath = [[searchPaths objectAtIndex: 0] stringByAppendingPathComponent:@"unreviewedStills"];
    
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[unsortedList count]];
    
    for(NSString* file in unsortedList) {
        NSString *ext = [[file pathExtension] lowercaseString];
        if ((![ext isEqualToString:@"jpeg"]) && (![ext isEqualToString:@"tiff"])) {
            continue;
        }
        
        NSString* filePath = [documentsPath stringByAppendingPathComponent:file];
        NSDictionary* properties = [[NSFileManager defaultManager]
                                    attributesOfItemAtPath:filePath
                                    error:&error];
        NSDate* modDate = [properties objectForKey:NSFileModificationDate];
        
        if (error == nil) {
            [list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           file, @"p",
                                           modDate, @"d",
                                           nil]];
        }
    }
    
    NSArray* sortedFiles = [list sortedArrayUsingComparator:
                            ^(id path1, id path2)
                            {
                                // compare
                                NSComparisonResult comp = [[path1 objectForKey:@"d"] compare:
                                                           [path2 objectForKey:@"d"]];
                                // invert ordering
                                if (comp == NSOrderedDescending) {
                                    comp = NSOrderedAscending;
                                }
                                else if(comp == NSOrderedAscending){
                                    comp = NSOrderedDescending;
                                }
                                return comp;
                            }];
    
    
    NSMutableArray *groupList = [@[ ] mutableCopy];
    NSMutableDictionary *groupDict = [@{ } mutableCopy];
    
    NSDate *lastDate;
    NSDate *firstDate;
    NSMutableArray *curList  = [@[ ] mutableCopy];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
    
    for (NSDictionary *args in sortedFiles) {
        NSDate *date = [args objectForKey:@"d"];
        NSString *path = [args objectForKey:@"p"];
        
        if (!lastDate) {
            lastDate = date;
        }
        
        if (!firstDate) {
            firstDate = date;
        }
        
        if ([lastDate timeIntervalSinceDate:date] < 60) {
            [curList addObject:path];
        } else {
            NSString *dateStr = [[LocationHandler tool] timeAgoFromDateStr:[dateFormatter stringFromDate:firstDate]];
            [groupList addObject:dateStr];

            [groupDict setObject:[curList copy] forKey:@([[groupDict allKeys] count])];
           
            curList  = [@[ ] mutableCopy];
            [curList addObject:path];
            firstDate = nil;
        }
        
        lastDate = date;
    }
    
    if ([curList count]>0) {
        [groupDict setObject:[curList copy] forKey:@([[groupDict allKeys] count])];
        NSString *dateStr = [[LocationHandler tool] timeAgoFromDateStr:[dateFormatter stringFromDate:firstDate]];
        [groupList addObject:dateStr];
    }
    
    unreviewedStillGroupList = [groupList copy];
    
    unreviewedStillGroupDict = [groupDict copy];
}

-(NSArray *)unreviewedStillGroups {
    return unreviewedStillGroupList;
}

-(NSInteger )unreviewedStillGroupEntryCount:(NSInteger)index {
    NSInteger found = 0;
    
    if ([unreviewedStillGroupList count] > index) {
        NSArray *itemList = [unreviewedStillGroupDict objectForKey:@(index)];
        found = [itemList count];
    }
    
    return found;
}

-(NSString *)nameForUnreviewedStillGroupAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index {
    NSString *str = nil;
    
    if ([unreviewedStillGroupList count] > libIndex) {
        NSArray *itemList = [unreviewedStillGroupDict objectForKey:@(libIndex)];
        if ([itemList count] > index) {
            str = [itemList objectAtIndex:index];
        }
    }
    
    return str;
}

-(void)moveDataAtPathToCameraRoll:(NSString *)path andMasterGroupIndex:(NSInteger )index {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedAlways error:&error];
    if ( (!data) || error) {
        NSLog(@"moveDataToCameraRoll:%@:%@", @"no data", [error localizedDescription]);
        return;
    }
    
    [assetLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"moveDataToCameraRoll:%@:%@", path, [error localizedDescription]);
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
        ALAssetsGroup *group = [masterGroupList objectAtIndex:index];
        [assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            if ([group addAsset:asset]) {
                NSLog(@"added to group:%@:%@", asset, group);
            } else {
                NSLog(@"unable to add asset to group:%@:%@", asset, group);
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"unable to add asset to group:%@:%@", assetURL, @(index));
        }];
    }];
}

-(void)addPhotoAlbumWithName:(NSString *)name {
    [assetLibrary addAssetsGroupAlbumWithName:name resultBlock:^(ALAssetsGroup *group) {
        [[SettingsTool settings] setStillDefaultAlbum:name];
        [[PhotoManager manager] update];
    } failureBlock:^(NSError *error) {
        NSLog(@"Unable to create photo album with name:%@:%@", name, [error localizedDescription]);
    }];
}

@end
