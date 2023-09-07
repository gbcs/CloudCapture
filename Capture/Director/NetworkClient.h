//
//  NetworkClient.h
//  MCClient
//
//  Created by Gary  Barnett on 3/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol NetworkClientDelegate <NSObject>
-(void)networkClientDidConnectToServerWithID:(MCPeerID *)peer;
-(void)networkClientIsConnectingToServerWithID:(MCPeerID *)peer;
-(void)networkClientDidDisconnectFromServerWithID:(MCPeerID *)peer;
-(void)networkClientReceivedMessage:(NSData *)msg fromServerWithID:(MCPeerID *)peer;
-(void)networkClientBrowseList:(NSDictionary *)dict;
@end

@interface NetworkClient : NSObject <MCNearbyServiceBrowserDelegate, MCSessionDelegate, NSStreamDelegate>
@property (nonatomic, weak) NSObject <NetworkClientDelegate> *delegate;
@property (nonatomic, readonly) MCPeerID *localPeer;

-(void)startup;
-(void)shutdown;
-(void)loginToServerWithPeer:(MCPeerID *)peer usingPassword:(NSString *)password;
-(void)browseListRequest;
-(void)sendMessage:(NSData *)msg;

@end
