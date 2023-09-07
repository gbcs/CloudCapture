//
//  NetworkServer.h
//  MCServer
//
//  Created by Gary  Barnett on 3/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol NetworkServerDelegate <NSObject>
-(void)networkServerDidLoginUser:(MCPeerID *)peer;
-(void)networkServerPeerDidFailLoginWithPassword:(NSString *)password peer:(MCPeerID *)peer;
-(void)networkServerDidLogoutUser;
-(void)networkServerReceivedMessage:(NSData *)msg;
@end

@interface NetworkServer : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, NSStreamDelegate>
@property (nonatomic, weak) NSObject <NetworkServerDelegate> *delegate;

-(void)allowConnection:(BOOL)allow;
-(void)logoutUser;

-(void)sendMessage:(NSData *)msg preview:(BOOL)preview;



@end
