//
//  NetworkServer.m
//  MCServer
//
//  Created by Gary  Barnett on 3/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "NetworkServer.h"
#import <CoreGraphics/CoreGraphics.h>

typedef void (^InviteBlock)(BOOL accept, MCSession *session);
#define sessionServiceType @"cloudcapt"

@implementation NetworkServer {
    MCSession *mcSession;
    MCNearbyServiceAdvertiser *advertiser;
    
    MCPeerID *localPeer;
    MCPeerID *remotePeer;
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    NSMutableArray *outputMessages;
    
    uint8_t buf[4096];
    NSMutableData *inputData;
    NSInteger inputStreameCurrentMessageSize;
    
}
@synthesize delegate;

-(void)dealloc {
    //NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



-(void)allowConnection:(BOOL)allow {
    [inputStream close];
    [outputStream close];
    
    inputStream = nil;
    outputStream = nil;
    
    remotePeer = nil;
    
    if (allow) {
        if (!mcSession) {
            localPeer = [[MCPeerID alloc] initWithDisplayName:[NSString stringWithFormat:@"%@", [[UIDevice currentDevice] name]]];
            mcSession = [[MCSession alloc] initWithPeer:localPeer];
            mcSession.delegate = self;
            
            advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:localPeer
                                                           discoveryInfo:@{ @"id" : [[[UIDevice currentDevice] identifierForVendor] UUIDString]}
                                                             serviceType:sessionServiceType];
            advertiser.delegate = self;
        }
        [advertiser startAdvertisingPeer];
    } else {
        [advertiser stopAdvertisingPeer];
    }



}

-(void)loginUser {
    if (remotePeer) {
        [advertiser stopAdvertisingPeer];
        [delegate networkServerDidLoginUser:remotePeer];
    }
}

-(void)logoutUser {
    [delegate networkServerDidLogoutUser];
}




-(void)outputDataThroughStream:(NSData *)data {
    NSLog(@"SentMsg:%@", [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil]);
    
    NSInteger len = [data length];
    NSInteger sizeOfLen = 4;
    
    __block NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:len + sizeOfLen];
    
    Byte *byteData = (Byte*)malloc(9);
    
    byteData[3] = len & 0xff;
    byteData[2] = (len & 0xff00) >> 8;
    byteData[1] = (len & 0xff0000) >> 16;
    byteData[0] = (len & 0xff000000) >> 24;
    
    [outputData appendBytes:byteData length:sizeOfLen];
    [outputData appendBytes:[data bytes] length:len];
    free(byteData);
    
    NSInteger bytesWritten = 0;
    bytesWritten = [outputStream write:[outputData bytes] maxLength:len + sizeOfLen];
    
    if (bytesWritten != [outputData length]) {
        NSLog(@"output stream failure");
        dispatch_async(dispatch_get_main_queue(), ^{
            [mcSession disconnect];
        });
    }
}


-(NSString *)getPassword {
    return [[SettingsTool settings] engineRemotePassword];
}


- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {
    InviteBlock inviteBlock = invitationHandler;
    [NSThread sleepForTimeInterval:0.05];
    BOOL decline = YES;
    
    if (!remotePeer) {
        NSString *p = [[NSString alloc] initWithData:context encoding:NSStringEncodingConversionAllowLossy];
        
        if (p && [[self getPassword] isEqualToString:p]) {
            decline = NO;
            inviteBlock(YES, mcSession);
            NSLog(@"Invite accepted for %@", peerID.displayName);
        } else {
            if (p && ([p length] >0) ) {
                [delegate networkServerPeerDidFailLoginWithPassword:p peer:remotePeer];
            }
        }
    }
    
    if (decline) {
        inviteBlock(NO, mcSession);
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser start error:%@", error);
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    if (state == MCSessionStateConnected) {
        if (remotePeer) {
            [self logoutUser];
            NSLog(@"User connected while user already logged in; resetting session");
            return;
        }
        remotePeer = peerID;
        [self loginUser];
        
        NSError *error = nil;
        outputStream = [session startStreamWithName:@"streamToClient" toPeer:remotePeer error:&error];
    
      
            outputStream.delegate = self;
            [outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            
            outputMessages = [[NSMutableArray alloc] init];
          
            [outputStream open];
            
            [[NSRunLoop currentRunLoop] run];
        
   
        
        
    } else if (state == MCSessionStateNotConnected) {
        [self logoutUser];
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    if (inputStream) {
        NSLog(@"incoming input stream when already have input stream; skipping");
        return;
    }
    
    
        inputStream = stream;
        inputStream.delegate = self;
        inputData = [[NSMutableData alloc] init];
        
        inputStreameCurrentMessageSize = 0;
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inputStream open];
        [[NSRunLoop currentRunLoop] run];
    
}



- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventEndEncountered:
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Stream Error; disconnecting; %@", aStream == inputStream ? @"Input" : @"Output");
            [self logoutUser];
        }
            break;
        case NSStreamEventNone:
        {
            
        }
            break;
        case NSStreamEventOpenCompleted:
        {
            if ([aStream isEqual:inputStream]) {
                inputData = [[NSMutableData alloc] init];
                inputStreameCurrentMessageSize = 0;
            }
            
            NSLog(@"Stream opened: %@", aStream == inputStream ? @"Input" : @"Output");
        }
            break;
        case NSStreamEventHasBytesAvailable:
        {
            //@synchronized (inputData) {
            if (inputStream) {
                NSInteger getLen = 4096;
                NSInteger readLen = [inputStream read:buf maxLength:getLen];
                if (readLen <1) {
                    NSLog(@"zero length reading input stream");
                    return;
                }
                
                [inputData appendBytes:buf length:readLen];
                
                BOOL keepLooking = YES;
                
                while (keepLooking) {
                    NSInteger existingLen = [inputData length];
                    if (inputStreameCurrentMessageSize > 0) {
                        if (inputStreameCurrentMessageSize <= existingLen) {
                            NSData *data = [NSData dataWithBytes:[inputData bytes] length:inputStreameCurrentMessageSize];
                            [inputData replaceBytesInRange:NSMakeRange(0,inputStreameCurrentMessageSize) withBytes:NULL length:0];
                            [delegate networkServerReceivedMessage:data];
                            inputStreameCurrentMessageSize = 0;
                        } else {
                            keepLooking = NO;
                        }
                    } else if (inputStreameCurrentMessageSize == 0) {
                        if (existingLen > 4) {
                            NSData *len = [NSData dataWithBytes:[inputData bytes] length:4];
                            uint8_t *lenBytes = (uint8_t *)[len bytes];
                            NSInteger nextLen = (int)lenBytes[0] << 24;
                            nextLen |= (int)lenBytes[1] << 16;
                            nextLen |= (int)lenBytes[2] << 8;
                            nextLen |= (int)lenBytes[3];
                            
                            inputStreameCurrentMessageSize = (long)nextLen;
                            [inputData replaceBytesInRange:NSMakeRange(0, 4) withBytes:NULL length:0];
                        } else {
                            keepLooking = NO;
                        }
                    }
                }
            }
            //}
        }
            break;
        case NSStreamEventHasSpaceAvailable:
        {
            // NSLog(@"HasSpaceAvailable");
            [self sendMessageFromStreamOutputQueue];
        }
            break;
    }
}
-(void)outputMessageThroughStream:(NSData *)data {

   // NSLog(@"Sending %@ bytes through outputStream", @([data length]));
    NSInteger len = [data length];
    NSInteger sizeOfLen = 4;
    
    __block NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:len + sizeOfLen];
    
    Byte *byteData = (Byte*)malloc(9);
    
    byteData[3] = len & 0xff;
    byteData[2] = (len & 0xff00) >> 8;
    byteData[1] = (len & 0xff0000) >> 16;
    byteData[0] = (len & 0xff000000) >> 24;
    
    [outputData appendBytes:byteData length:sizeOfLen];
    [outputData appendBytes:[data bytes] length:len];
    free(byteData);
    
    __block NSInteger bytesWritten = bytesWritten = [outputStream write:[outputData bytes] maxLength:len + sizeOfLen];
    
    if (bytesWritten != [outputData length]) {
        [self streamFailed];
    }
    

}

-(void)streamFailed {
    NSLog(@"stream failure");
    dispatch_async(dispatch_get_main_queue(), ^{
        [mcSession disconnect];
    });
}

-(void)addMessageToStreamOutputQueue:(NSData *)data {
    @synchronized (outputMessages ) {
        if ([outputMessages count]>100) {
            NSLog(@">100 messages outstanding; skipping");
            return;
        }
        [outputMessages addObject:data];
    };
}

-(void)sendMessageFromStreamOutputQueue {
    @synchronized (outputMessages) {
        if ([outputMessages count] >0) {
            NSData *data = [outputMessages objectAtIndex:0];
            [outputMessages removeObjectAtIndex:0];
            [self outputMessageThroughStream:data];
        }
    }
}

-(void)sendMessage:(NSData *)data preview:(BOOL)preview {
    
    NSInteger len = [data length];
    NSMutableData *msg = [[NSMutableData alloc] initWithCapacity:len + 1];
    
    Byte *byteData = (Byte*)malloc(1);
    byteData[0] = preview ? 0xff : 0x00;

    [msg appendBytes:byteData length:1];
    [msg appendBytes:[data bytes] length:len];
    free(byteData);

    if (outputStream && [outputStream hasSpaceAvailable] && ([outputMessages count] <1) ) {
        [self outputMessageThroughStream:msg];
    } else {
        [self addMessageToStreamOutputQueue:msg];
    }
}



- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
}
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}


@end
