//
//  AssetManager.m
//  Capture
//
//  Created by Gary Barnett on 9/14/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AssetManager.h"

@implementation AssetManager {
    BOOL ready;
    ALAssetsLibrary *assetLibrary;
    NSMutableArray *groups;
    NSMutableArray *emptyGroups;
    NSMutableArray *groupAssets;
    
    NSMutableDictionary *currentGroupDict;
    NSInteger assetManagerWaitCount;
}

static AssetManager  *sharedSettingsManager = nil;

+ (AssetManager *)manager
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


-(void)cleanup {
    ready = NO;

    [groups removeAllObjects];
    [emptyGroups removeAllObjects];
    [groupAssets removeAllObjects];
    [currentGroupDict removeAllObjects];
}

-(void)update {
    ready = NO;
    
    [self cleanup];
    
    groups = [[NSMutableArray alloc] initWithCapacity:10];
    emptyGroups = [[NSMutableArray alloc] initWithCapacity:10];
    groupAssets = [[NSMutableArray alloc] initWithCapacity:10];
    
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        ready = YES;
        return;
    }
    
    if (!assetLibrary) {
        assetLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!group) {
            ready = YES;
        } else {
            [emptyGroups addObject:group];
           currentGroupDict = [[NSMutableDictionary alloc] initWithCapacity:10];
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if(result && [[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
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
    NSDictionary *groupDict = [groupAssets objectAtIndex:index-1];
    
    return [groupDict count];
}

-(ALAsset *)entryForGroupAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index {
    NSDictionary *groupDict = [groupAssets objectAtIndex:libIndex];
    
    return [groupDict objectForKey:[NSNumber numberWithInteger:index]];
}

-(void)clipMoveStatusReport:(NSString *)filePath result:(BOOL)success msg:(NSString *)msg {
        //NSLog(@"clipMoveStatusReport:%@:%@:%@", filePath, @(success), msg);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clipMoveReport" object:@[ filePath, @(success), msg ? msg : @"" ] ];
}


-(void)clipCopyStatusReport:(NSString *)filePath result:(BOOL)success msg:(NSString *)msg {
        //NSLog(@"clipCopyStatusReport:%@:%@:%@", filePath, @(success), msg);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clipCopyReport" object:@[ filePath, @(success), msg ? msg : @"" ] ];
}

-(void)moveClipToAlbum:(NSString *)filePath {
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    if (!asset) {
        [self clipMoveStatusReport:filePath result:NO msg:@"invalid asset"];
        return;
    }
    
    if (![asset isCompatibleWithSavedPhotosAlbum]) {
        [self clipMoveStatusReport:filePath result:NO msg:@"Asset not compatible with saved photos album"];
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *attr = [fm attributesOfItemAtPath:filePath error:&error];
    if (attr && (!error)) {
        NSNumber *fileSpace = [attr objectForKey:NSFileSize];
        NSNumber *freeSpace = [[UtilityBag bag] getfreeDiskSpaceInBytes];
        if ([freeSpace compare:fileSpace] == NSOrderedAscending) {
            [self clipMoveStatusReport:filePath result:NO msg:@"Not enough free space to move clip."];
            return;
        }
    }
    
    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    
}

-(void)copyClipToAppLibrary:(NSURL *)clipURL {
    [assetLibrary assetForURL:clipURL resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        
        [self performSelectorInBackground:@selector(makeLocalCopyOf:) withObject:rep];

    } failureBlock:^(NSError *error) {
        [self clipCopyStatusReport:@"Photo Library Clip" result:NO msg:@"Unable to copy this clip."];
    }];
}


-(void)makeLocalCopyOf:(ALAssetRepresentation *)rep
{
    
    NSString *filePath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[UtilityBag bag] pathForNewResourceWithExtension:@"mov"]];
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!handle) {
        dispatch_async(dispatch_get_main_queue(), ^{
             [self clipCopyStatusReport:@"Photo Library Clip" result:NO msg:@"Unable to create a local file for the copy."];
        });
        return;
    }
    
    NSNumber *fileSpace = [NSNumber numberWithLongLong:[rep size]];
    NSNumber *freeSpace = [[UtilityBag bag] getfreeDiskSpaceInBytes];
    
    if ([freeSpace compare:fileSpace] == NSOrderedAscending) {
         [self clipCopyStatusReport:@"Photo Library Clip" result:NO msg:@"Not enough free space to store the copy."];
        return;
    }
    
    static const NSUInteger BufferSize = 1024*1024;
    
    uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    NSUInteger totalRead = 0;
    do {
        @try {
            bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:nil];
            [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
            offset += bytesRead;
        } @catch (NSException *exception) {
            free(buffer);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self clipCopyStatusReport:@"Photo Library Clip" result:NO msg:@"Unable to complete the copy."];
            });
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            return ;
        }
        totalRead += bytesRead;
    } while (bytesRead > 0);
    
    free(buffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UtilityBag bag] makeThumbnail:[filePath lastPathComponent]];
        [self clipCopyStatusReport:@"Photo Album Clip" result:YES msg:@"Success"];
    });

}


-(ALAssetsGroup *)groupForIndex:(NSInteger)index {
   return [groups objectAtIndex:index];
}

-(void)waitOnAssetManagerAfterSave:(NSString *)videoPath {
    if (![[AssetManager manager] isReady]) {
        assetManagerWaitCount++;
        if (assetManagerWaitCount >= 4) {
            [self clipMoveStatusReport:videoPath result:NO msg:@"Asset Manager failed to enumerate photo albums"];
        } else {
            [self performSelector:@selector(waitOnAssetManagerAfterSave:) withObject:videoPath afterDelay:0.25];
        }
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    NSString *udid = nil;
    for (AVMetadataItem *item in asset.commonMetadata) {
        if ([(NSString *)item.key isEqualToString:@"com.apple.quicktime.description"]) {
            udid = (NSString *)item.value;
            break;
        }
    }
    
    if (!udid) {
        [self clipMoveStatusReport:videoPath result:NO msg:@"Unable to extract udid from source asset metadata"];
        return;
    }
    
  
    
    //Find the clip in the camera roll
    __block BOOL found = NO;
    __block ALAsset *foundAsset = nil;
    
    NSInteger count = [[[AssetManager manager] groups] count];
    
    for (int index=0;index<count;index++) {
        ALAssetsGroup *group = [self groupForIndex:index];
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:[[result defaultRepresentation] url]];
            NSString *assetUDID = nil;
            for (AVMetadataItem *item in asset.commonMetadata) {
                if ([(NSString *)item.key isEqualToString:@"com.apple.quicktime.description"]) {
                    assetUDID = (NSString *)item.value;
                    break;
                }
            }
            
            if (assetUDID && [assetUDID isEqualToString:udid]) {
                *stop = YES;
                found = YES;
                foundAsset = result;
            }
        }];
        
        if (found) {
            break;
        }
    }
    
    if (!found) {
        [self clipMoveStatusReport:videoPath result:NO msg:@"Not Found in Camera Roll after Save Operation Completed"];
        return;
    }
    
    [self deleteMovedClip:videoPath];
    [self clipMoveStatusReport:videoPath result:YES msg:nil];
    
}

-(void)deleteMovedClip:(NSString *)videoPath {
    NSFileManager *fM = [[NSFileManager alloc] init];
    NSError *error = nil;
    [fM removeItemAtPath:videoPath error:&error];
}

-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        assetManagerWaitCount = 0;
        [[AssetManager manager] performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(waitOnAssetManagerAfterSave:) withObject:videoPath waitUntilDone:YES];
    } else {
        [self clipMoveStatusReport:videoPath result:NO msg:[error localizedDescription]];
    }
}

-(NSArray *)sortCutList:(NSArray *)cutList {
    NSLog(@"startSort:%@", cutList);
    
    NSArray *cuts = [cutList copy];
    
    if([cutList count]>1) {
        NSArray *sortedCutList = [cutList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSValue *a = (NSValue *)obj1[0];
            NSValue *b = (NSValue *)obj2[0];
            
            if ([a CMTimeValue].value < [b CMTimeValue].value) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if ([a CMTimeValue].value > [b CMTimeValue].value) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            return (NSComparisonResult)NSOrderedSame;
        }];
        
        cuts = [sortedCutList copy];
    }
    
    NSLog(@"endSort:%@", cuts);
    
    return cuts;
}


-(NSArray *)videoList {
    NSArray *videoList = nil;
    NSError * error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UtilityBag bag] docsPath] error:&error];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ( (!error) && directoryContents) {
        NSMutableDictionary *vMap = [[NSMutableDictionary alloc] initWithCapacity:[directoryContents count]];
        NSMutableDictionary *vSort = [[NSMutableDictionary alloc] initWithCapacity:[directoryContents count]];
        
        for (NSString *entry in directoryContents) {
            if ([[[entry pathExtension] lowercaseString] isEqualToString:@"mov"] || [[[entry pathExtension] lowercaseString] isEqualToString:@"mp4"]) {
                NSDictionary *attribs = [fileManager attributesOfItemAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:entry] error:&error];
                if (!attribs) {
                    NSLog(@"No file attribs; skipping:%@", entry);
                } else {
                    [vMap setObject:attribs forKey:entry];
                    [vSort setObject:[attribs objectForKey:NSFileModificationDate] forKey:entry];
                }
            }
        }
        
        NSArray *sortedKeys = [[[vSort keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
            
            if ([obj1 compare: obj2] == NSOrderedDescending) {
                
                return (NSComparisonResult)NSOrderedDescending;
            }
            if ([obj1 compare: obj2] == NSOrderedAscending) {
                
                return (NSComparisonResult)NSOrderedAscending;
            }
            
            return (NSComparisonResult)NSOrderedSame;
        }] reverseObjectEnumerator] allObjects];
        
        
        NSMutableArray *vList = [[NSMutableArray alloc] initWithCapacity:[sortedKeys count]];
        
        for (NSString *key in sortedKeys) {
            [vList addObject: @[key, [vMap objectForKey:key]] ];
        }
        videoList = [vList copy];
    } else {
        videoList = [NSArray array];
    }
    
    return videoList;
}

-(void)cleanupMoviePhotosTemp {
    NSFileManager *manager = [[NSFileManager alloc] init];
    
    NSString *path = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"];
    NSError *error = nil;
    NSArray * directoryContents = [manager contentsOfDirectoryAtPath:path error:&error];
   
    if (error || (!directoryContents)) {
        return;
    }
  
    for (NSString *entry in directoryContents) {
        [manager removeItemAtPath:[path stringByAppendingPathComponent:entry] error:&error];
    }
}

-(NSDictionary *)videoDictForRemote {
    
    NSArray *videoList = [self videoList];
       
    NSDictionary *library = @{ @"appLibraryList" : videoList};

    return @{ @"cmd" : @"libraryVideo", @"attr" : library };
}


@end
