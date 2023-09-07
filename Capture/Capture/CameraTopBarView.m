//
//  CameraTopBarView.m
//  Capture
//
//  Created by Gary Barnett on 7/5/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CameraTopBarView.h"


@implementation CameraTopBarView {
    UIFont *normalFont;
     UIFont *boldFont;
    
     UIColor *outlineColor;
     UIColor *batteryFillColor;
     UIColor *diskFillColor;
    
    UIColor *selectionLineColor;
    
    NSTimer *updateTimer;
    
    float recordingButtonGlowValue;
    BOOL recordingButtonGlowDirection;
    
    
}

-(void)dealloc {
    //NSLog(@"%s", __func__);
   
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    normalFont = nil;
    boldFont = nil;
    outlineColor = nil;
    batteryFillColor = nil;
    diskFillColor = nil;
    selectionLineColor = nil;
    updateTimer = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            normalFont = [UIFont fontWithName:@"LiquidCrystal" size:13];
            boldFont = [UIFont fontWithName:@"LiquidCrystal-Bold" size:13];
        } else {
            normalFont = [UIFont fontWithName:@"LiquidCrystal" size:13];
            boldFont = [UIFont fontWithName:@"LiquidCrystal-Bold" size:13];
        }
        
        recordingButtonGlowValue = 0.7f;
        outlineColor = [UIColor whiteColor];
        batteryFillColor = [UIColor greenColor];
        diskFillColor = [UIColor greenColor];
        selectionLineColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateTimerEvent) userInfo:nil repeats:YES];
  
    }
    return self;
}

-(void)updateTimerEvent {
    self.batteryPercentage = [[StatusReporter manager] battery];
    self.diskPercentage = [[StatusReporter manager] disk];
    self.recordingTime = [[StatusReporter manager]  recordTime];
    self.zoomScale = [StatusReporter manager].currentZoomLevel;
    [self setNeedsDisplay];
}

-(UIColor *)colorForSelection:(NSInteger)selectedValue {
    UIColor *c = [UIColor colorWithWhite:0.7 alpha:1.0];
    
    if (selectedValue == 1) {
        c = [UIColor blueColor];
    } else if (selectedValue == 2) {
        c = [UIColor redColor];
    }
    
    return c;
}

-(void)update {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextDrawingMode(context, kCGTextFill);
    
    CGPoint p2 = CGPointZero;
    CGPoint p3 = CGPointZero;
    CGPoint p4 = CGPointZero;
    CGPoint p5 = CGPointZero;
    
    CGPoint pRecGlow = CGPointZero;
    
    if (self.frame.size.width > 480.0f) {
        p2 = CGPointMake(500,2);
        pRecGlow= CGPointMake(549,2);
    } else {
        p2 = CGPointMake(412,2);
        pRecGlow = CGPointMake(457,2);
    }
    
    p3 = CGPointMake(110,2);
    p4 = CGPointMake(146,2);
    p5 = CGPointMake(185,2);
    
    NSDictionary *stdDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:boldFont,[UIColor colorWithWhite:0.7 alpha:1.0], [[UtilityBag bag] getBlackShadowForText], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, nil]];
    
    CGContextSetFillColorWithColor(context, batteryFillColor.CGColor);
    CGContextFillRect(context, CGRectMake(3, 5, 16 * self.batteryPercentage, 6));
    
    CGContextSetStrokeColorWithColor(context, outlineColor.CGColor);
    CGContextStrokeRect(context, CGRectMake(2, 4, 18,8));
    CGContextStrokeRect(context, CGRectMake(20, 6, 3, 4));
    
    CGContextSetFillColorWithColor(context, batteryFillColor.CGColor);
    CGContextFillRect(context, CGRectMake(3, 5, 16 * self.batteryPercentage, 6));
    
    CGContextSetStrokeColorWithColor(context, outlineColor.CGColor);
    
    CGContextSetFillColorWithColor(context, diskFillColor.CGColor);
    CGContextFillRect(context, CGRectMake(30, 12 - (8 * self.diskPercentage), 18, 8 * self.diskPercentage));
    
    CGContextSetFillColorWithColor(context, outlineColor.CGColor);
    
    CGContextStrokeRect(context, CGRectMake(30, 4, 18,8));
    
    CGContextMoveToPoint(context, 37, 9);
    CGContextAddLineToPoint(context, 39, 12);
    CGContextAddLineToPoint(context, 42, 9);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, 39, 4);
    CGContextAddLineToPoint(context, 39, 12);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, 30, 12);
    CGContextAddLineToPoint(context, 48, 12);
    CGContextStrokePath(context);
    
    CGContextSetStrokeColorWithColor(context, outlineColor.CGColor);
    if (self.audioLPercentage == -2000.0f) {
       //Display nothing during transition
    } else if (self.audioLPercentage == -1000.0f) {
        [@"SILENT" drawAtPoint:CGPointMake(65,2)  withAttributes:stdDrawAttrbs];
    } else {
        NSDictionary *audioLRDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[UIFont systemFontOfSize:5],outlineColor, nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil]];
        
        [@"L" drawAtPoint:CGPointMake(54.5,2) withAttributes:audioLRDrawAttrbs];
        
        [@"R" drawAtPoint:CGPointMake(54.5,8) withAttributes:audioLRDrawAttrbs];
        
        int maxXL =  37 * self.audioLPercentage;
        int maxXR =  37 * self.audioRPercentage;
        
        for (int x=0;x<40;x = x + 3) {
            if (maxXL >= x ) {
                CGContextStrokeRect(context, CGRectMake(60 + x, 4.5, 1,1));
            }
            
            if (maxXR >= x ) {
                CGContextStrokeRect(context, CGRectMake(60 + x, 11, 1,1));
            }
        }
    }
  
    NSString *cameraName = [[SettingsTool settings] cameraIsBack] ? @" Back" : @"Front";
    NSString *resolution = [NSString stringWithFormat:@"% 03ld", (long)[[SettingsTool settings] captureOutputResolution]];
    
    NSInteger reportFrameRate = (long)[StatusReporter manager].lastReportedFrameRate;
    NSInteger captureFrameRate= [[SettingsTool settings] videoCameraFrameRate];
    
    if (reportFrameRate - 1 == captureFrameRate) {
        reportFrameRate--;
    }
 
    if ( [[SettingsTool settings] isOldDevice] || [[SettingsTool settings] fastCaptureMode] ) {
        NSString *frameRate = [NSString stringWithFormat:@"%02ld FPS", (long)captureFrameRate];
        NSMutableAttributedString *ratings = [[NSMutableAttributedString alloc] initWithString:frameRate attributes:stdDrawAttrbs];
        
        if (self.selected < 0) {
            CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.4 alpha:1.0] CGColor]);
        } else {
            CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.7 alpha:1.0] CGColor]);
        }
        
        [cameraName drawAtPoint:p3  withAttributes:stdDrawAttrbs];
        [resolution drawAtPoint:p4  withAttributes:stdDrawAttrbs];
        [ratings drawAtPoint:p5];
    } else {

        NSString *frameRate = [NSString stringWithFormat:@"%02ld/%02ld FPS (%@) %0.1fx" ,(long)reportFrameRate, (long)captureFrameRate, [[UtilityBag bag] convertShutterSpeed:[StatusReporter manager].shutterSpeedRational], self.zoomScale];
        
        frameRate = [frameRate stringByAppendingFormat:@" f/%0.1f ISO:%d", [StatusReporter manager].FNumber, [StatusReporter manager].isoRating];
        
        NSMutableAttributedString *ratings = [[NSMutableAttributedString alloc] initWithString:frameRate attributes:stdDrawAttrbs];
        
        if (self.selected < 0) {
            CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.4 alpha:1.0] CGColor]);
        } else {
            CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.7 alpha:1.0] CGColor]);
        }
        
        [cameraName drawAtPoint:p3  withAttributes:stdDrawAttrbs];
        [resolution drawAtPoint:p4  withAttributes:stdDrawAttrbs];
        [ratings drawAtPoint:p5 ];
        
        
        
        CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.7 alpha:1.0] CGColor]);
        
        if ([StatusReporter manager].badFrameRate) {
            NSDictionary *redDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:boldFont,[UIColor redColor], [[UtilityBag bag] getBlackShadowForText], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, nil]];
            
            NSString *timeStatus = @"Low Frame Rate; reduce load/resolution";
            [timeStatus drawAtPoint:CGPointMake(2,17) withAttributes:redDrawAttrbs];
        } else if ([StatusReporter manager].huntingISO) {
            
            NSDictionary *redDrawAttrbs = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:boldFont,[UIColor redColor], [[UtilityBag bag] getBlackShadowForText], nil] forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSShadowAttributeName, nil]];
            
            NSString *timeStatus = @"Adjust light source to acquire ISO lock";
            [timeStatus drawAtPoint:CGPointMake(2,17) withAttributes:redDrawAttrbs];
        }
    }
    
    if ([StatusReporter manager].recording) {
        NSString *timeStatus = [[StatusReporter manager] recordTime];
        [timeStatus drawAtPoint:p2 withAttributes:stdDrawAttrbs];
        if (!recordingButtonGlowDirection) {
            recordingButtonGlowValue -= 0.01f;
            if (recordingButtonGlowValue <= 0.70f) {
                recordingButtonGlowDirection = YES;
            }
        } else {
            recordingButtonGlowValue += 0.01f;
            if (recordingButtonGlowValue >= 1.0f) {
                recordingButtonGlowDirection = NO;
            }
        }
        CGContextSetFillColorWithColor(context, [UIColor colorWithRed:recordingButtonGlowValue green:0 blue:0 alpha:1.0].CGColor);
        CGContextFillEllipseInRect(context, CGRectMake(pRecGlow.x, pRecGlow.y, 12,12));
    }

}

@end
