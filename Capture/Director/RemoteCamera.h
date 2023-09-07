//
//  RemoteCamera.h
//  Cloud Director
//
//  Created by Gary  Barnett on 3/9/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkClient.h"
#import "RemoteBrowserManager.h"

@protocol RemoteBrowserManagerDelegate;

@interface RemoteCamera : NSObject <NetworkClientDelegate>
@property (nonatomic, weak) NSObject <RemoteBrowserManagerDelegate> *browserDelegate;
@property (nonatomic, copy) MCPeerID *serverPeer;
@property (nonatomic, copy) MCPeerID *clientPeer;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, copy) NSData *lastThumbnail;
@property (nonatomic, copy) NSString *cameraID;
@property (nonatomic, assign) BOOL recording;
@property (nonatomic, copy) NSDictionary *status;
-(void)startByBrowsing;
-(void)stop;
-(void)connectToPeer:(MCPeerID *)peer;
-(void)sendMessage:(NSData *)msg;
@end
