//
//  StatusReporter.m
//  Capture
//
//  Created by Gary Barnett on 7/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "StatusReporter.h"

@implementation StatusReporter {
    NSTimer *updateTimer;
    NSDate *startDate;
    NSDateFormatter *dateFormatter;
}


static StatusReporter  *sharedSettingsManager = nil;


- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}


+ (StatusReporter *)manager
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
        
    }
    
    return sharedSettingsManager ;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self manager];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(void)startRecording {
    startDate = [NSDate date];
     _recording = YES;
}

-(void)stopRecording {
    startDate = nil;
    _recording = NO;

}


-(void)shutdown {
    [updateTimer invalidate];
    updateTimer = nil;
}


-(void)startup {
    if (!updateTimer) {
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(collectStats) userInfo:nil repeats:YES];
    }
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
        [dateFormatter setDateFormat: @"HH:mm:ss"];
    }


    [self collectStats];
}

-(NSString *)recordTime {
  NSString *r = @"00:00:00";
    
    if (startDate) {
        NSInteger elapsed = abs([startDate timeIntervalSinceNow]);
        
        NSInteger h = elapsed / (60*60);
        
        NSInteger m = (elapsed - (60 *h) ) / 60;
        
        NSInteger s  = elapsed - (h * 60 * 60) - (m * 60);
        
        r = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    }
    
    return r;
}


-(void)collectStats {
    
    self.battery = [[UIDevice currentDevice] batteryLevel];
    if (_battery < 0.0f) {
        _battery = 0.0f;
    }
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
        
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
        
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        //NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
        
        self.disk = ((double)totalFreeSpace / (double)totalSpace);
    }
    
    
   // NSLog(@"collected:battery:%0.1f disk:%0.1f recordTime:%@", self.battery, self.disk, self.recordTime);
    
}


@end
