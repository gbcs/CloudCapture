//
//  VideoSourceManager.h
//  Cloud Director
//
//  Created by Gary Barnett on 8/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoSourceManager : NSObject

+ (VideoSourceManager*)manager;

-(NSInteger)addSource:(NSDictionary *)sourceEntry;
-(void)removeSourceAtIndex:(NSInteger)index;
-(NSInteger)sourceCount;
-(NSDictionary *)infoDictForSourceAtIndex:(NSInteger)index;
-(NSInteger)indexOfSourceWithID:(NSString *)ID;
-(void)updatePassword:(NSData *)password forSourceWithID:(NSString *)ID;
-(NSData *)passswordForSourceWithID:(NSString *)ID;
-(void)updateLastSeenForSourceWithID:(NSString *)ID;
-(void)updateName:(NSString *)name forSourceWithID:(NSString *)ID;
-(void)updateThumbnail:(NSData *)thumbData forSourceWithID:(NSString *)ID;
-(NSString *)nameForSource:(NSString *)source;
@end
