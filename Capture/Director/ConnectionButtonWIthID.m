//
//  ConnectionButtonWIthID.m
//  Cloud Director
//
//  Created by Gary  Barnett on 3/11/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "ConnectionButtonWIthID.h"
#import "RemoteCamera.h"

@implementation ConnectionButtonWIthID {
    BOOL listening;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}


-(void)listen {
    if (listening) {
        [self stopListening];
    }
    [self setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    listening = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionStatusForID:) name:@"updateConnectionStatusForID" object:nil];
    [self addTarget:self action:@selector(userTappedConnectionButton) forControlEvents:UIControlEventTouchUpInside];
}

-(void)userTappedConnectionButton {
    RemoteCamera *connectedCamera = nil;
    for (RemoteCamera *camera in [[RemoteBrowserManager manager] connectedCameraList]) {
        if ([camera.cameraID isEqual:self.ID]) {
            connectedCamera = camera;
            break;
        }
    }
    
    if (connectedCamera) {
        [[RemoteBrowserManager manager] disconnectCameraWithID:self.ID];
    } else {
        [self setTitle:@"" forState:UIControlStateNormal];
        self.userInteractionEnabled = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
           [[RemoteBrowserManager manager] invitePeerWithID:self.ID];
        });
    }
}

-(void)updateConnectionStatusForID:(NSNotification *)n {
    self.userInteractionEnabled = YES;
    NSArray *args = (NSArray *)n.object;
    NSString *IDStr =  [args objectAtIndex:0];
    if (![self.ID isEqual:IDStr]) {
        return;
    }
    NSString *title = @"";
    NSString *status = [args objectAtIndex:1];
    
    if ([status isEqualToString:@"Connected"]) {
        title = @"Disconnect";
    } else if ([status isEqualToString:@"Connecting"]) {
        title = @"Connecting";
    } else {
        title = @"Connect";
    }
    
    self.enabled = [title isEqualToString:@"Connecting"] ? NO : YES;
    
    [self setTitle:title forState:UIControlStateNormal];
}


-(void)stopListening {
    if (!listening) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dealloc {
    [self stopListening];
}


@end
