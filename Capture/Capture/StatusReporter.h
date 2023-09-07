//
//  StatusReporter.h
//  Capture
//
//  Created by Gary Barnett on 7/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatusReporter : NSObject
@property (nonatomic, assign) float battery;
@property (nonatomic, assign) float disk;
@property (nonatomic, assign) Float64 lastReportedFrameRate;
@property (nonatomic, readonly) BOOL recording;
@property (nonatomic, assign) float currentZoomLevel;
@property (nonatomic, assign) float FNumber;
@property (nonatomic, assign) float focalLength;
@property (nonatomic, assign) int isoRating;
@property (nonatomic, copy) NSNumber *shutterSpeedRational;
@property (nonatomic, copy) NSNumber *aperture;
@property (nonatomic, assign) BOOL huntingISO;
@property (nonatomic, assign) BOOL badFrameRate;
@property (nonatomic, assign) BOOL galileoConnected;
+(StatusReporter *)manager;
-(NSString *)recordTime;

-(void)startRecording;
-(void)stopRecording;
-(void)shutdown;
-(void)startup;


@end
