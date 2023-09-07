//
//  VideoSourceManager.m
//  Cloud Director
//
//  Created by Gary Barnett on 8/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "VideoSourceManager.h"

@implementation VideoSourceManager {
    NSMutableArray *sourcesList;
}

static VideoSourceManager *sharedSettingsManager = nil;

+ (VideoSourceManager*)manager
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

- (id)init
{
    self = [super init];
    if (self) {
            NSData *diskData = [NSData dataWithContentsOfFile:[self sourcesFilePath]];
            NSArray *diskList = [NSKeyedUnarchiver unarchiveObjectWithData:diskData];
            
            if (diskList && ([diskList count]>0)) {
                sourcesList = [diskList mutableCopy];
            } else {
                sourcesList = [[NSMutableArray alloc] initWithCapacity:1];
            }
    }
    return self;
}

-(NSString *)sourcesFilePath {
    return [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"videoSources.list"];
}

-(NSInteger)indexOfSourceWithID:(NSString *)ID {
    NSInteger index = -1;
    
    for (int x=0;x<[sourcesList count];x++) {
        NSDictionary *dict = sourcesList[x];
        if ([[dict objectForKey:@"id"] isEqualToString:ID]) {
            index = x;
            break;
        }
    }
    
    return index;
}

-(NSInteger)addSource:(NSDictionary *)sourceEntry {
    NSInteger count = [sourcesList count];
    
    if (!sourceEntry) {
        return -1;
    }
    
    [sourcesList addObject:sourceEntry];
    
    [self saveSourcesFile];
    
    return count;
}

-(void)removeSourceAtIndex:(NSInteger)index {
    if (index >= [self sourceCount]) {
        return;
    }
    
    [sourcesList removeObjectAtIndex:index];
    
    [self saveSourcesFile];
}

-(void)saveSourcesFile {
    [NSKeyedArchiver archiveRootObject:[sourcesList copy] toFile:[self sourcesFilePath]];
}

-(NSInteger)sourceCount {
    return [sourcesList count];
}

-(NSData *)passswordForSourceWithID:(NSString *)ID {
   
    NSData *password = nil;
    
    for (int x=0;x<[sourcesList count];x++) {
        NSDictionary *dict = sourcesList[x];
        if ([[dict objectForKey:@"id"] isEqualToString:ID]) {
            password = [dict objectForKey:@"password"];
            break;
        }
    }
    
    if (!password) {
        password = [@"a" dataUsingEncoding:NSStringEncodingConversionAllowLossy];
    }
    
    return password;
}

-(void)updateThumbnail:(NSData *)thumbData forSourceWithID:(NSString *)ID {
    if (!thumbData) {
        return;
    }
    for (int x=0;x<[sourcesList count];x++) {
        NSDictionary *dict = sourcesList[x];
        if ([[dict objectForKey:@"id"] isEqualToString:ID]) {
            NSMutableDictionary *mDict = [dict mutableCopy];
            [mDict setObject:thumbData  forKey:@"thumb"];
            [sourcesList replaceObjectAtIndex:x withObject:[mDict copy]];
            [self saveSourcesFile];
            break;
        }
    }
}


-(NSString *)nameForSource:(NSString *)source {
    NSString *name = @"Unknown";
    for (int x=0;x<[sourcesList count];x++) {
        NSDictionary *dict = sourcesList[x];
        if ([[dict objectForKey:@"id"] isEqualToString:source]) {
            name = [dict objectForKey:@"name"];
            break;
        }
    }
    
    return name;
}

-(void)updateName:(NSString *)name forSourceWithID:(NSString *)ID {
    for (int x=0;x<[sourcesList count];x++) {
        NSDictionary *dict = sourcesList[x];
        if ([[dict objectForKey:@"id"] isEqualToString:ID]) {
            NSMutableDictionary *mDict = [dict mutableCopy];
            if (![[mDict objectForKey:@"name"] isEqualToString:name]) {
                [mDict setObject:name forKey:@"name"];
                [sourcesList replaceObjectAtIndex:x withObject:[mDict copy]];
                [self saveSourcesFile];
            }
            break;
        }
    }
}

-(void)updateLastSeenForSourceWithID:(NSString *)ID {
    for (int x=0;x<[sourcesList count];x++) {
        NSDictionary *dict = sourcesList[x];
        if ([[dict objectForKey:@"id"] isEqualToString:ID]) {
            NSMutableDictionary *mDict = [dict mutableCopy];
            [mDict setObject:[NSDate date] forKey:@"lastSeen"];
            [sourcesList replaceObjectAtIndex:x withObject:[mDict copy]];
            [self saveSourcesFile];
            break;
        }
    }
}



-(void)updatePassword:(NSData *)password forSourceWithID:(NSString *)ID {
    for (int x=0;x<[sourcesList count];x++) {
        NSDictionary *dict = sourcesList[x];
        if ([[dict objectForKey:@"id"] isEqualToString:ID]) {
            NSMutableDictionary *mDict = [dict mutableCopy];
            [mDict setObject:password forKey:@"password"];
            [sourcesList replaceObjectAtIndex:x withObject:[mDict copy]];
            [self saveSourcesFile];
            break;
        }
    }
}

-(NSDictionary *)infoDictForSourceAtIndex:(NSInteger)index {
    if (index >= [self sourceCount]) {
        return nil;
    }
    return [sourcesList objectAtIndex:index];
}

@end
