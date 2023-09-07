//
//  GalileoHandler.m
//  Capture
//
//  Created by Gary  Barnett on 2/23/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "GalileoHandler.h"
#import <CoreBluetooth/CoreBluetooth.h>

@implementation GalileoHandler {
  
}

static GalileoHandler  *sharedSettingsManager = nil;

+ (GalileoHandler *)tool
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
        
    }
    
    return sharedSettingsManager ;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self tool];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(void)startup {
    CBCentralManager *manager = [[CBCentralManager alloc] init];
    if (manager.state == CBCentralManagerStatePoweredOn) {
        [GCGalileo sharedGalileo].delegate = self;
        [[GCGalileo sharedGalileo] waitForConnection];
    }
}

-(void)shutdown {
    [[GCGalileo sharedGalileo] disconnect];
    [GCGalileo sharedGalileo].delegate = nil;
}

- (void) galileoDidConnect {
    _isReady = YES;
    [[SettingsTool settings] setGalileoConnected:YES];
}

- (void) galileoDidDisconnect {
    _isReady = NO;
    [[SettingsTool settings] setGalileoConnected:NO];
    [[GCGalileo sharedGalileo] waitForConnection];
}

- (void) controlDidReachTargetPosition { //position control
    if ([[GCGalileo sharedGalileo] isConnected]) {
        
    }
}

- (void) controlDidOverrideMovement { //position control
    
}

- (void) controlDidReachTargetVelocity {//velocity control
    if ([[GCGalileo sharedGalileo] isConnected]) {
        
    }
}

-(void)setVelocity:(double)velocity forAxis:(NSInteger )axis {
    if ([[GCGalileo sharedGalileo] isConnected]) {
        GCVelocityControl *control = [[GCGalileo sharedGalileo] velocityControlForAxis:axis == 0 ? GCControlAxisPan : GCControlAxisTilt];
        control.targetVelocity = velocity;
    }
}

-(void)setMode:(NSInteger)mode forAxis:(NSInteger )axis {
    if ([[GCGalileo sharedGalileo] isConnected]) {
        
        [[GCGalileo sharedGalileo] selectMode:mode == 0 ? GCModePositionControl : GCModeVelocityControl forAxis:axis == 0 ? GCControlAxisPan : GCControlAxisTilt];
    }
}

- (void)panClockwiseToPositionToPosition:(double)pos {
    void (^completionBlock) (BOOL) = ^(BOOL wasCommandPreempted)
    {
       
    };
    [[[GCGalileo sharedGalileo] positionControlForAxis:GCControlAxisPan] incrementTargetPosition:pos
                                                                                 completionBlock:completionBlock waitUntilStationary:NO];
}

- (void)panAnticlockwiseToPosition:(double)pos {
    void (^completionBlock) (BOOL) = ^(BOOL wasCommandPreempted)
    {
        
    };
    [[[GCGalileo sharedGalileo] positionControlForAxis:GCControlAxisPan] incrementTargetPosition:pos
                                                                                 completionBlock:completionBlock
                                                                             waitUntilStationary:NO];
}

- (void)tiltClockwiseToPosition:(double)pos {
 
    void (^completionBlock) (BOOL) = ^(BOOL wasCommandPreempted)
    {
        
    };
    [[[GCGalileo sharedGalileo] positionControlForAxis:GCControlAxisTilt] incrementTargetPosition:pos
                                                                                  completionBlock:completionBlock
                                                                              waitUntilStationary:NO];
}

- (void)tiltAnticlockwiseToPosition:(double)pos {

    void (^completionBlock) (BOOL) = ^(BOOL wasCommandPreempted)
    {
        
    };
    [[[GCGalileo sharedGalileo] positionControlForAxis:GCControlAxisTilt] incrementTargetPosition:pos
                                                                                  completionBlock:completionBlock
                                                                              waitUntilStationary:NO];
}

-(void)stopMoving {
    [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisPan].targetVelocity = 0.0f;
    [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisTilt].targetVelocity = 0.0f;
}


-(void)handleVelocityDict:(NSDictionary *)dict {
    NSNumber *tiltV = [dict objectForKey:@"tilt"];
    NSNumber *panV = [dict objectForKey:@"pan"];
    
    
    if (tiltV) {
        CGFloat val = fabs([tiltV floatValue]);
        if (val > [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisTilt].maxVelocity) {
            val = [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisTilt].maxVelocity;
        } else if ((val != 0.0f) && ( val < [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisTilt].minVelocity)) {
            val = [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisTilt].minVelocity;
        }
        
        [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisTilt].targetVelocity = [tiltV floatValue] > 0.0f ? val : -val;
    }
    
    if (panV) {
        CGFloat val = fabs([panV doubleValue]);
        if (val > [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisPan].maxVelocity) {
            val = [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisPan].maxVelocity;
        } else if ((val != 0.0f) && (val < [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisPan].minVelocity)) {
            val = [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisPan].minVelocity;
        }
        
        [[GCGalileo sharedGalileo] velocityControlForAxis:GCControlAxisPan].targetVelocity = [panV floatValue] > 0.0f ? val : -val;
    }
 
}

-(void)handlePositionDict:(NSDictionary *)dict {
    
}


@end
