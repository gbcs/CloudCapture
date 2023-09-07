//
//  RemoteAdvertiserManager.h
//  Capture
//
//  Created by Gary Barnett on 8/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "FilterTool.h"
#import "NetworkServer.h"

@interface RemoteAdvertiserManager : NSObject <FilterToolRemotePreviewDelegate, NetworkServerDelegate>
+ (RemoteAdvertiserManager*)manager;
@property (nonatomic, readonly) BOOL advertising;

-(void)startAdvertiser;
-(void)stopAdvertiser;

-(void)stopSession;
-(void)startSession;

-(BOOL)isReadyForVideoFrame;

-(NSString *)generatePassword;
-(void)sendStatusResponse;

@end
