//
//  RemoteCamera.m
//  Cloud Director
//
//  Created by Gary  Barnett on 3/9/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "RemoteCamera.h"

@implementation RemoteCamera {
    NetworkClient *client;
}


-(void)startByBrowsing {
    if (client) {
        NSLog(@"Remote camera attempt to startByBrowsing while already started.");
        return;
    }
    
    
    client = [[NetworkClient alloc] init];
    client.delegate = self;
    [client startup];
    self.clientPeer = client.localPeer;
    
}

-(void)connectToPeer:(MCPeerID *)peer {
    if (!client) {
        NSLog(@"Remote camera not already running in connectToPeer.");
        return;
    }
    
    if (self.connected) {
        NSLog(@"Remote camera attempt to connect to peer while already connected to peer.");
        return;
    }
    
    NSString *pwd = [self.browserDelegate passwordForPeer:peer];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateConnectionStatusForID" object:@[[self.browserDelegate IDForPeer:peer], @"Connecting" ] userInfo:nil];
    [client loginToServerWithPeer:peer usingPassword:pwd];
}


-(void)stop {
    if (!client) {
        NSLog(@"Remote camera attempt to stop while not started.");
        return;
    }
    
    self.connected = NO;
    [client shutdown];

}

-(void)sendMessage:(NSData *)msg {
    [client sendMessage:msg];
}

-(void)networkClientDidConnectToServerWithID:(MCPeerID *)peer {
    self.serverPeer = peer;
    _connected = YES;
     NSLog(@"connected:%@", peer.displayName);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateConnectionStatusForID" object:@[self.cameraID, @"Connected" ] userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"peerConnectedWithID" object:[self.browserDelegate IDForPeer:self.serverPeer] userInfo:nil];
    [self.browserDelegate cameraDidConnect:self];
}

-(void)networkClientIsConnectingToServerWithID:(MCPeerID *)peer {
    NSLog(@"connecting:%@", peer.displayName);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateConnectionStatusForID" object:@[self.cameraID, @"Connecting" ] userInfo:nil];
}

-(void)networkClientDidDisconnectFromServerWithID:(MCPeerID *)peer {
    _connected = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sourceDisconnected" object:self.cameraID userInfo:nil];
    
    [self.browserDelegate cameraDidDisconnect:self];
    NSLog(@"disconnected:%@", peer.displayName);
    self.serverPeer = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateConnectionStatusForID" object:@[self.cameraID, @"Disconnected" ] userInfo:nil];
    
}

- (NSData *)getSubData:(NSData *)source withRange:(NSRange)range
{
    UInt8 bytes[range.length];
    [source getBytes:&bytes range:range];
    return [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
}

-(void)networkClientReceivedMessage:(NSData *)msg fromServerWithID:(MCPeerID *)peer {
    if (!self.serverPeer) {
        NSLog(@"nil serverPer in networkClientReceivedMessage");
        return;
    }
   // NSLog(@"message:%@:%@ == %@", @([msg length]), peer.displayName, self.serverPeer.displayName);
    NSInteger msgLength = [msg length];
    
    if (msgLength < 5) {
        NSLog(@"Impossibly small incoming msg length:%@" , @(msgLength));
        return;
    }
    
    NSData *flagData = [self getSubData:msg withRange:NSMakeRange(0, 1)];
    NSData *msgData = [self getSubData:msg withRange:NSMakeRange(1, msgLength - 1)];
    
    const uint8_t *flagBytes = [flagData bytes];
    
    BOOL previewFrame = flagBytes[0] == 0xff;

    if (previewFrame) {
        [self processPreview:msgData];
    } else {
        NSError *error = nil;
        NSDictionary *remoteDict = [NSJSONSerialization JSONObjectWithData:msgData options:NSJSONReadingAllowFragments error:&error];
        if (remoteDict && (!error)) {
            [self processCommand:remoteDict];
        }
    }
}


-(void)networkClientBrowseList:(NSDictionary *)dict {
    [self.browserDelegate updatedBrowseList:dict];
}


-(void)processPreview:(NSData *)previewData {
    self.lastThumbnail = previewData;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"previewDataForID" object:@[self.cameraID, previewData]];
}

-(void)processCommand:(NSDictionary *)cmdDict {
    NSDictionary *statusDict = [cmdDict objectForKey:@"status"];

    if (statusDict) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"statusDict" object:@[self.cameraID, statusDict] userInfo:nil];
    } else {
        NSString *cmd =[cmdDict objectForKey:@"cmd"];
        if (cmd) {
            if ([cmd isEqualToString:@"libraryVideo"]) {
                NSDictionary *attrDict = [cmdDict objectForKey:cmd];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"libraryUpdate" object:@[@(0), attrDict] userInfo:nil];
            } else if ([cmd isEqualToString:@"libraryPhoto"]) {
                NSDictionary *attrDict = [cmdDict objectForKey:cmd];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"libraryUpdate" object:@[@(1), attrDict] userInfo:nil];
            } else if ([cmd isEqualToString:@"libraryAudio"]) {
                NSDictionary *attrDict = [cmdDict objectForKey:cmd];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"libraryUpdate" object:@[@(2), attrDict] userInfo:nil];
            }
        } else {
            if ([cmdDict objectForKey:@"preset"]) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"showPresetList" object:[cmdDict objectForKey:@"preset"] userInfo:nil];
            }
        }
    }
}

-(void)userPressedZoomButtonAtIndex:(NSInteger)index {
    
}

@end
