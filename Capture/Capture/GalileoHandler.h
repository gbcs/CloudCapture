//
//  GalileoHandler.h
//  Capture
//
//  Created by Gary  Barnett on 2/23/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GalileoControl/GalileoControl.h>

@interface GalileoHandler : NSObject <GCGalileoDelegate, GCPositionControlDelegate, GCVelocityControlDelegate>

+(GalileoHandler *)tool;
@property (nonatomic, readonly) BOOL isReady;
-(void)shutdown;
-(void)startup;

-(void)stopMoving;

-(void)handleVelocityDict:(NSDictionary *)dict;
-(void)handlePositionDict:(NSDictionary *)dict;

@end
