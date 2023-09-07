//
//  RemoteBrowserManager.m
//  Cloud Director
//
//  Created by Gary Barnett on 8/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "RemoteBrowserManager.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>


#define sessionServiceType @"cloudcapt"


@implementation RemoteBrowserManager {
    BOOL previewRequested;
 
    CGImageRef previewImage;
    CGImageRef oldPreviewImage;
    
    NSMutableDictionary *peerList;
    
    NSMutableArray *clientList;

}

-(void)endSession {
    for (RemoteCamera *camera in clientList) {
        if (camera.connected) {
            NSString *ID = [self IDForPeer:camera.serverPeer];
            [[VideoSourceManager manager] updateLastSeenForSourceWithID:ID];
            [[VideoSourceManager manager] updateThumbnail:camera.lastThumbnail forSourceWithID:ID];
        }
        [camera stop];
        [clientList removeObject:camera];
    }
}

static RemoteBrowserManager *sharedSettingsManager = nil;

+ (RemoteBrowserManager*)manager
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

-(void)cameraDidDisconnect:(RemoteCamera *)camera {
    NSString *ID = [self IDForPeer:camera.serverPeer];
    [[VideoSourceManager manager] updateLastSeenForSourceWithID:ID];
    [[VideoSourceManager manager] updateThumbnail:camera.lastThumbnail forSourceWithID:ID];
    [clientList removeObject:camera];
    [camera stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"peerListChanged" object:nil];
    
    [self startBrowser];
    
}

-(MCPeerID *)peerForID:(NSString *)ID {
    if (!peerList) {
        peerList = [@{ } mutableCopy];
    }
    MCPeerID *peer = [peerList objectForKey:ID];
    return peer;
}

-(NSString *)IDForPeer:(MCPeerID *)peer {
    NSString *ID = @"";
    
    NSArray *keys = [peerList allKeys];
    
    for (int x=0;x<[peerList count];x++) {
        NSString *key = [keys objectAtIndex:x];
        NSString *value = [peerList objectForKey:key];
         if ([peer isEqual:value]) {
            ID = key;
            break;
        }
    }
    
    return ID;
}

-(BOOL)isRunning {
    return [clientList count] >0;
}
-(void)startSession {
    if (!peerList) {
        peerList = [@{ } mutableCopy];
    }
    if (!clientList) {
        clientList = [@[ ] mutableCopy];
    }
    if ([clientList count]>0) {
        NSLog(@"Start session while clients exist.");
        return;
    }
    
    [self startBrowser];
}

-(void)stopSession {
    for (RemoteCamera *camera in clientList) {
        [camera stop];
    }
    
    [clientList removeAllObjects];
}

-(void)startBrowser {
    BOOL browserRunning = NO;
    
    for (RemoteCamera *camera in clientList) {
        if (!camera.connected) {
            browserRunning = YES;
            break;
        }
    }
    
    if (!browserRunning) {
        RemoteCamera *camera = [[RemoteCamera alloc] init];
        camera.browserDelegate = self;
        [camera startByBrowsing];
        [clientList addObject:camera];
    }
}

-(void)stopBrowser {
    NSMutableArray *list = [@[ ] mutableCopy];
    for (RemoteCamera *camera in clientList) {
        if (!camera.connected) {
            [camera stop];
        } else {
            [list addObject:camera];
        }
    }
    
    clientList = list;
}

-(BOOL)isIDConnected:(NSString *)ID {
    BOOL answer = NO;
    
    for (RemoteCamera *camera in clientList) {
        if ([camera.cameraID isEqual:ID] && camera.connected) {
            answer = YES;
            break;
        }
    }
    
    return answer;
}

-(void)cameraDidConnect:(RemoteCamera *)camera {
    [self startBrowser];
}

-(NSMutableArray *)connectedCameraList {
    NSMutableArray *list = [@[ ] mutableCopy];
    for (RemoteCamera *camera in clientList) {
        if (camera.connected) {
            [list addObject:camera];
        }
    }
    return list;
}

-(void)invitePeerWithID:(NSString *)ID {
    MCPeerID *peer = [self peerForID:ID];
    
    RemoteCamera *browser = nil;
    
    for (RemoteCamera *camera in clientList) {
        if ([camera.serverPeer isEqual:peer]) {
            NSLog(@"already exists in clientList");
            return;
        } else if (!camera.connected) {
            browser = camera;
        }
    }
    
    if (!browser) {
        RemoteCamera *camera = [[RemoteCamera alloc] init];
        camera.browserDelegate = self;
        [clientList addObject:camera];
        [camera startByBrowsing];
    }
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:0.5];
        dispatch_async(dispatch_get_main_queue(), ^{
             [browser connectToPeer:peer];
            browser.cameraID = [self IDForPeer:peer];
        });
    });
}

-(void)sendMessage:(NSData *)cmd toIDList:(NSArray *)list {
    for (RemoteCamera *camera in clientList) {
        NSInteger index = [list indexOfObject:camera.cameraID];
        if (index != NSNotFound) {
            [camera sendMessage:cmd];
        }
    }
}

-(void)sendMessage:(NSData *)cmd toID:(NSString *)ID {
    BOOL found = NO;
    for (RemoteCamera *camera in clientList) {
        if ([camera.cameraID isEqual:ID]) {
            [camera sendMessage:cmd];
            found = YES;
            break;
        }
    }
    
    if (!found) {
        NSLog(@"sendMessage ID not found in clientList:%@", ID);
    }

}

-(void)disconnectCameraWithID:(NSString *)ID {
    for (RemoteCamera *camera in clientList) {
        if ([camera.cameraID isEqual:ID]) {
            [self cameraDidDisconnect:camera];
            break;
        }
    }
}

-(NSString *)passwordForPeer:(MCPeerID *)peer {
    NSString *pwd = @"";
    
    NSString *ID = [self IDForPeer:peer];
    
    if (ID) {
        NSData *data = [[VideoSourceManager manager] passswordForSourceWithID:ID];
        if (data) {
            pwd = [[NSString alloc] initWithData:data encoding:NSStringEncodingConversionAllowLossy];
        }
    }
    
    return pwd;
}


-(void)updatedBrowseList:(NSDictionary *)dict {
    
    peerList = [@{ } mutableCopy];
    
    NSArray *keys = [dict allKeys];
    for (MCPeerID *peer in keys) {
        NSString *cameraID = [dict objectForKey:peer];
        if ([cameraID isEqualToString:[[[UIDevice currentDevice] identifierForVendor] UUIDString]]) {
            continue;
        }
        
        NSInteger existingIndex = [[VideoSourceManager manager] indexOfSourceWithID:cameraID];
        if (existingIndex < 0) {
            NSDictionary *infoDict = @{ @"id" : cameraID,
                                    @"name" : peer.displayName,
                                    @"lastSeen" : [NSDate date]
                                    };
            [[VideoSourceManager manager] addSource:infoDict];
        } else {
            [[VideoSourceManager manager] updateLastSeenForSourceWithID:cameraID];
            [[VideoSourceManager manager] updateName:peer.displayName forSourceWithID:cameraID];
        }
        [peerList setObject:peer forKey:cameraID];
    }
    NSLog(@"PeerList:%@", peerList);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"peerListChanged" object:nil];
}
 
@end
