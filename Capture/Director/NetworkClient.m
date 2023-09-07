//
//  NetworkClient.m
//  MCClient
//
//  Created by Gary  Barnett on 3/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "NetworkClient.h"
#define sessionServiceType @"cloudcapt"

@implementation NetworkClient {
    MCSession *mcSession;
    MCPeerID *localPeer;
    MCPeerID *serverPeer;
    
    MCNearbyServiceBrowser *browser;
    
    NSMutableDictionary *browseList;
    
    NSMutableArray *outputMessages;
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    NSMutableData *inputData;
    NSInteger inputStreameCurrentMessageSize;
    
    uint8_t buf[4096];
}

@synthesize delegate;
@synthesize localPeer;

-(void)startup {
    
     
    localPeer = [[MCPeerID alloc] initWithDisplayName:[NSString stringWithFormat:@"%@", [[UIDevice currentDevice] name]]];
   
    mcSession = [[MCSession alloc] initWithPeer:localPeer];
    mcSession.delegate = self;
    browseList = [@{ } mutableCopy];
    
    browser = [[MCNearbyServiceBrowser alloc] initWithPeer:localPeer serviceType:sessionServiceType];
    browser.delegate = self;
    [browser startBrowsingForPeers];
    
    
}



-(void)shutdown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (serverPeer) {
        inputStream = nil;
        outputStream = nil;
        [mcSession disconnect];
        serverPeer = nil;
    }

    delegate = nil;
    outputMessages = nil;
    inputStream = nil;
    inputData = nil;
    outputStream = nil;
    
    
    [browser stopBrowsingForPeers];
    browser.delegate = nil;
    browser = nil;
    [browseList removeAllObjects];
    browseList = nil;
    mcSession.delegate = nil;
    mcSession = nil;
}

-(void)browseListRequest {
    [delegate networkClientBrowseList:[browseList copy]];
}

-(void)streamFailed {
    NSLog(@"stream failure");
    dispatch_async(dispatch_get_main_queue(), ^{
        [mcSession disconnect];
    });
}

-(void)outputDataThroughStream:(NSData *)data {
        //NSLog(@"SentMsg:%@:%@",@([data length]), serverPeer.displayName);
        
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

-(void)addMessageToStreamOutputQueue:(NSData *)data {
    @synchronized (outputMessages) {
        if ([outputMessages count]>100) {
            NSLog(@">100 messages outstanding; skipping");
            return;
        }
        
        if (data ) {
           [outputMessages addObject:data];
        }
    };
}

-(void)sendMessageFromStreamOutputQueue {
    @synchronized (outputMessages) {
        if ([outputMessages count] >0) {
            NSData *data = [outputMessages objectAtIndex:0];
            [outputMessages removeObjectAtIndex:0];
            [self outputDataThroughStream:data];
        }
    }
}



-(void)sendMessage:(NSData *)msg {
        if (outputStream && [outputStream hasSpaceAvailable] && ([outputMessages count] <1) ) {
            [self outputDataThroughStream:msg];
        } else {
            [self addMessageToStreamOutputQueue:msg];
        }
}

-(void)loginToServerWithPeer:(MCPeerID *)peer usingPassword:(NSString *)password {
    [browser invitePeer:peer toSession:mcSession withContext:[password dataUsingEncoding:NSStringEncodingConversionAllowLossy]  timeout:5];
}

- (void)browser:(MCNearbyServiceBrowser *)aBrowser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"found peer:%@", peerID.displayName);
    [browseList setObject:[info objectForKey:@"id"] forKey:peerID];
    [delegate networkClientBrowseList:[browseList copy]];
}

 - (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
     NSLog(@"lost peer:%@", peerID.displayName);
     [browseList removeObjectForKey:peerID];
     [delegate networkClientBrowseList:[browseList copy]];
     if ([peerID isEqual:serverPeer]) {
         [self shutdown];
     }
}
 
 - (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
     NSLog(@"browser start error:%@", error);
 }

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    switch (state) {
        case MCSessionStateConnected:
        {
            serverPeer = peerID;
            [browser stopBrowsingForPeers];
            browser = nil;
            [delegate networkClientBrowseList:[browseList copy]];
          
            NSError *error = nil;
            outputStream = [session startStreamWithName:@"streamToServer" toPeer:serverPeer error:&error];
           
            
                [outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                        forMode:NSDefaultRunLoopMode];
                outputStream.delegate = self;
                [outputStream open];
                
               // [[NSRunLoop currentRunLoop] run];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
                [NSThread sleepForTimeInterval:1.0f];
                dispatch_async(dispatch_get_main_queue(), ^{
                     [delegate networkClientDidConnectToServerWithID:peerID];
                });
            });
        }
            break;
        case MCSessionStateConnecting:
            [delegate networkClientIsConnectingToServerWithID:peerID];
            break;
        case MCSessionStateNotConnected:
            [delegate networkClientDidDisconnectFromServerWithID:peerID];
            [self shutdown];
            break;
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    if (inputStream) {
        NSLog(@"Incoming stream when already incoming stream preset; disconnecting");
        [self shutdown];
        return;
    }
    
    inputStream = stream;
    inputData = [[NSMutableData alloc] init];
    inputStream.delegate = self;

   
        [inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                               forMode:NSDefaultRunLoopMode];
        
        [inputStream open];
        
       // [[NSRunLoop currentRunLoop] run];
    
}



- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventEndEncountered:
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Stream Error; disconnecting; %@", aStream == inputStream ? @"Input" : @"Output");
            [mcSession disconnect];
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
        }
            break;
        case NSStreamEventHasBytesAvailable:
        {
           // @synchronized (inputData) {
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
                                [delegate networkClientReceivedMessage:data fromServerWithID:serverPeer];
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
          //  }
        }
            break;
        case NSStreamEventHasSpaceAvailable:
        {
            if (outputStream) {
               // NSLog(@"HasSpaceAvailable");
                [self sendMessageFromStreamOutputQueue];
            }
        }
            break;
    }
}



//- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void(^)(BOOL accept))certificateHandler;
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}

 @end
