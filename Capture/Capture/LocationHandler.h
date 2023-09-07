//
//  LocationHandler.h
//  Capture
//
//  Created by Gary Barnett on 9/5/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface LocationHandler : NSObject <CLLocationManagerDelegate>

+(LocationHandler *)tool;

@property (nonatomic, strong) CLLocation *location;

-(void)shutdown;
-(void)startup;

-(void)reverseGeocodeAddressWithNotification:(NSString *)location notification:(NSArray *)cellData;

-(void)sendMotionUpdates:(BOOL)enabled;
-(void)sendLocationUpdates:(BOOL)enabled;

- (NSString *)timeAgoFromDateStr:(NSString *)dateStr;

@end
