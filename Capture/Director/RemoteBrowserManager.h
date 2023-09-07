//
//  RemoteBrowserManager.h
//  Cloud Director
//
//  Created by Gary Barnett on 8/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <GLKit/GLKit.h>
#import "RemoteCamera.h"

@protocol RemoteBrowserManagerDelegate <NSObject>
-(void)updatedBrowseList:(NSDictionary *)dict;
-(NSString *)passwordForPeer:(MCPeerID *)peer;
-(NSString *)IDForPeer:(MCPeerID *)peer;
-(void)cameraDidDisconnect:(RemoteCamera *)camera;
-(void)cameraDidConnect:(RemoteCamera *)camera;
@end

@interface RemoteBrowserManager : NSObject <RemoteBrowserManagerDelegate>

+ (RemoteBrowserManager*)manager;
-(void)endSession;
-(void)startBrowser;
-(void)stopBrowser;
-(void)stopSession;
-(void)startSession;
-(BOOL)isRunning;
-(MCPeerID *)peerForID:(NSString *)ID;
-(NSString *)IDForPeer:(MCPeerID *)peer;
-(void)invitePeerWithID:(NSString *)ID;
-(BOOL)isIDConnected:(NSString *)ID;
-(NSMutableArray *)connectedCameraList;
-(void)disconnectCameraWithID:(NSString *)ID;
-(void)sendMessage:(NSData *)cmd toID:(NSString *)ID;
-(void)sendMessage:(NSData *)cmd toIDList:(NSArray *)list;
@end
