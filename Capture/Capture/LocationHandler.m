//
//  LocationHandler.m
//  Capture
//
//  Created by Gary Barnett on 9/5/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "LocationHandler.h"
#import <AddressBookUI/AddressBookUI.h>

@implementation LocationHandler {
    CMMotionManager *motionHandler;
    CLLocationManager *locationHandler;
    CLGeocoder *geoCoder;
    NSMutableDictionary *knownLocations;
    NSDateFormatter *dateFormatter;
    NSOperationQueue *queue;
}

static LocationHandler  *sharedSettingsManager = nil;

+ (LocationHandler *)tool
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


-(void)load {
    NSDictionary *list = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathForLocationList]];
    if (list) {
        knownLocations = [list mutableCopy];
    } else {
        knownLocations = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
}

-(void)save {
    [NSKeyedArchiver archiveRootObject:[knownLocations copy] toFile:[self pathForLocationList]];
}

-(NSString *)pathForLocationList {
    return [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:@"location.list"];
}

- (id)init {
    self = [super init];
    if (self) {
        [self load];
        [self startup];
    }
    return self;
}

-(void)notifyReverseGeocode:(NSString *)address notification:(NSArray *)cellData  originalLocationStr:(NSString *)origLocStr {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"locationFound" object:@[cellData[0], cellData[1], address]];
}

-(void)reverseGeocodeAddressWithNotification:(NSString *)location notification:(NSArray *)cellData {
    
    NSArray *latlong = [location componentsSeparatedByString:@","];
    
    if ([latlong count] != 2) {
        [self notifyReverseGeocode:@"" notification:cellData originalLocationStr:location];
        return;
    }
    
    CLLocation *l = [[CLLocation alloc] initWithLatitude:[[latlong objectAtIndex:0] doubleValue] longitude:[[latlong objectAtIndex:1] doubleValue]];

#warning optimization opportunity in reverseGeocodeAddressWithNotification

    NSString *address = [knownLocations objectForKey:location];

    if (address) {
        [self notifyReverseGeocode:[knownLocations objectForKey:location] notification:cellData originalLocationStr:location];
    } else {
        [geoCoder reverseGeocodeLocation:l completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error || ([placemarks count]<1)) {
                [self notifyReverseGeocode:@"" notification:cellData originalLocationStr:location];
            }
            
            CLPlacemark *p = [placemarks objectAtIndex:0];
            NSString *address = [NSString stringWithFormat:@"%@, %@", [p.addressDictionary objectForKey:@"SubLocality"], [p.addressDictionary objectForKey:@"State"]];
            
            if (address) {
                [knownLocations setObject:address forKey:location];
                [self save];
                [self notifyReverseGeocode:address notification:cellData originalLocationStr:location];
            }
        }];
    }
}

- (NSString *)timeAgoFromDateStr:(NSString *)dateStr {
    NSDate *date = [dateFormatter dateFromString:dateStr];
    
    double seconds = [date timeIntervalSince1970];
    
    if (seconds < 30) {
        return @"Just Now";
    }
    
    double difference = [[NSDate date] timeIntervalSince1970] - seconds;
    NSMutableArray *periods = [NSMutableArray arrayWithObjects:@"second", @"minute", @"hour", @"day", @"week", @"month", @"year", @"decade", nil];
    NSArray *lengths = [NSArray arrayWithObjects:@60, @60, @24, @7, @4.35, @12, @10, nil];
    NSInteger j = 0;
    for(j=0; difference >= [[lengths objectAtIndex:j] doubleValue]; j++)
    {
        difference /= [[lengths objectAtIndex:j] doubleValue];
    }
    difference = roundl(difference);
    if(difference != 1)
    {
        [periods insertObject:[[periods objectAtIndex:j] stringByAppendingString:@"s"] atIndex:j];
    }
    return [NSString stringWithFormat:@"%li %@%@", (long)difference, [periods objectAtIndex:j], @" ago"];
}


-(void)startup {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
    
    [self sendLocationUpdates:[[SettingsTool settings] useGPS]];
    [self handleGeocoder:YES];
    [self sendMotionUpdates:[[SettingsTool settings] horizonGuide]];
}

-(void)shutdown {
    [self sendLocationUpdates:NO];
    [self handleGeocoder:NO];
    [self sendMotionUpdates:NO];
}

-(void)handleGeocoder:(BOOL)enable {
    if (!enable) {
        if (geoCoder) {
            [geoCoder cancelGeocode];
            geoCoder = nil;
        }
    } else if (!geoCoder) {
        geoCoder = [[CLGeocoder alloc] init];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (locations) {
        self.location = [locations lastObject];
    }
}

-(void)sendLocationUpdates:(BOOL)enabled {
    
    if (locationHandler) {
        [locationHandler stopUpdatingLocation];
        locationHandler = nil;
    }
    
    if (enabled) {
        locationHandler = [[CLLocationManager alloc] init];
        locationHandler.delegate = self;
        locationHandler.distanceFilter = 300;
        locationHandler.desiredAccuracy = kCLLocationAccuracyKilometer;
        [locationHandler startUpdatingLocation];
        NSLog(@"Location Services enabled");
    } else {
       NSLog(@"Location Services disabled");
    }
}


-(void)sendMotionUpdates:(BOOL)enabled {
    
    if ( (!enabled) && motionHandler) {
        [motionHandler stopDeviceMotionUpdates];
        queue = nil;
        motionHandler = nil;
        return;
    }
    
    if (!enabled) {
        return;
    }
    
    if (!motionHandler) {
        motionHandler = [[CMMotionManager alloc] init];
    }
    
    if ([motionHandler isDeviceMotionAvailable] != YES) {
        NSLog(@"Unable to work with motion updates !isDeviceMotionAvailable");
        return;
    }
    
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:2];
    
    
    float updateInterval = 1.0f / 30.0f;
    [motionHandler setDeviceMotionUpdateInterval:updateInterval];
    
    NSLog(@"Setting up motion Updater with interval:%0.2f", updateInterval);
    [motionHandler startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"motionUpdate" object:deviceMotion];
    }];
  
}

@end
