//
//  GuidePane.m
//  Capture
//
//  Created by Gary Barnett on 7/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "GuidePane.h"

@implementation GuidePane {
    double horizonOfset;
    CGFloat framingGuideOffset;
}

-(void)dealloc {
    //NSLog(@"%s", __func__);
     [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pitchUpdated:) name:@"motionUpdate" object:nil];
    }
    return self;
}

-(void)pitchUpdated:(NSNotification *)n {
    CMDeviceMotion *motion = (CMDeviceMotion *)n.object;

    horizonOfset = motion.attitude.pitch;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self setNeedsDisplay];
    });
}

-(void)updateFramingGuideOffset:(CGFloat )offset {
    framingGuideOffset = offset;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.5 alpha:1.0].CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(0.5,0.5), 0.5, [UIColor blackColor].CGColor);
    
    //framing size;
    
    CGRect f = self.frame;
    
    
    if (self.framingMode == 0) { // off
        if (self.thirdsEnabled) {
            //split up the 16:9 area in thirds
           
            float x1 = f.size.width * (1.0f/3.0f);
            float x2 = f.size.width * (2.0f/3.0f);
            
            CGContextMoveToPoint(context, x1, 0);
            CGContextAddLineToPoint(context, x1, f.size.height);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, x2, 0);
            CGContextAddLineToPoint(context, x2, f.size.height);
            CGContextStrokePath(context);
 
            float y1 = f.size.height * (1.0f/3.0f);
            float y2 = f.size.height * (2.0f/3.0f);

            CGContextMoveToPoint(context, 0, y1);
            CGContextAddLineToPoint(context, f.size.width, y1);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, 0, y2);
            CGContextAddLineToPoint(context, f.size.width, y2);
            CGContextStrokePath(context);

        } else {
            //do nothing
        }
    } else if (self.framingMode == 1) { //4:3
        //display two vertical lines for 4:3 framing
        
        float widthAt4 = f.size.width/(4.0f/3.0f);
        
        float leftX =  (f.size.width -  widthAt4) / 2.0f;
        
        if (framingGuideOffset < -(leftX)) {
            framingGuideOffset = -(leftX);
        } else if (framingGuideOffset > leftX) {
            framingGuideOffset = leftX;
        }
        
        leftX -= framingGuideOffset;
        
        float rightX = widthAt4 + leftX;
        
        
        //NSLog(@"%f:%f:%f:%f", f.size.width, widthAt4, leftX, rightX);
        
        CGContextMoveToPoint(context, leftX, 0);
        CGContextAddLineToPoint(context, leftX, f.size.height);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, rightX, 0);
        CGContextAddLineToPoint(context, rightX, f.size.height);
        CGContextStrokePath(context);

        if (self.thirdsEnabled) {
            //split up the 4:3 area in thirds
            
           // float leftX = f.size.width
            
            float x1 = widthAt4 * (1.0f/3.0f);
            float x2 = widthAt4 * (2.0f/3.0f);
            
            x1 += leftX;
            x2 += leftX;
            
            CGContextMoveToPoint(context, x1, 0);
            CGContextAddLineToPoint(context, x1, f.size.height);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, x2, 0);
            CGContextAddLineToPoint(context, x2, f.size.height);
            CGContextStrokePath(context);
            
            float y1 = f.size.height * (1.0f/3.0f);
            float y2 = f.size.height * (2.0f/3.0f);
            
            CGContextMoveToPoint(context, leftX, y1);
            CGContextAddLineToPoint(context, leftX + widthAt4, y1);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, leftX, y2);
            CGContextAddLineToPoint(context, leftX + widthAt4, y2);
            CGContextStrokePath(context);
        }
    } else if (self.framingMode == 2) { //1:1
        //display two vertical lines for 1:1 framing
        
        float widthAt4 = f.size.height;
        
        float leftX =  (f.size.width -  widthAt4) / 2.0f;
        
        if (framingGuideOffset < -(leftX)) {
            framingGuideOffset = -(leftX);
        } else if (framingGuideOffset > leftX) {
            framingGuideOffset = leftX;
        }
        
        leftX -= framingGuideOffset;
        
        float rightX = widthAt4 + leftX;

        
        
        
        //NSLog(@"%f:%f:%f:%f", f.size.width, widthAt4, leftX, rightX);
        
        CGContextMoveToPoint(context, leftX, 0);
        CGContextAddLineToPoint(context, leftX, f.size.height);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, rightX, 0);
        CGContextAddLineToPoint(context, rightX, f.size.height);
        CGContextStrokePath(context);
        
        if (self.thirdsEnabled) {
            //split up the 1:1 area in thirds
            
            // float leftX = f.size.width
            
            float x1 = widthAt4 * (1.0f/3.0f);
            float x2 = widthAt4 * (2.0f/3.0f);
            
            x1 += leftX;
            x2 += leftX;
            
            CGContextMoveToPoint(context, x1, 0);
            CGContextAddLineToPoint(context, x1, f.size.height);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, x2, 0);
            CGContextAddLineToPoint(context, x2, f.size.height);
            CGContextStrokePath(context);
            
            float y1 = f.size.height * (1.0f/3.0f);
            float y2 = f.size.height * (2.0f/3.0f);
            
            CGContextMoveToPoint(context, leftX, y1);
            CGContextAddLineToPoint(context, leftX + widthAt4, y1);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, leftX, y2);
            CGContextAddLineToPoint(context, leftX + widthAt4, y2);
            CGContextStrokePath(context);
        }
    }

    
    //Horizon Guide
    if (self.displayHorizon) {
       
        float width = self.frame.size.width * .60f;
        
        float leftX = (self.frame.size.width - width) / 2.0f;
        
        float ySpacing = self.frame.size.height / 6.0;
        
        float topY = self.frame.size.height - (ySpacing * 4.0);
        
        float angleOfset = (tan(horizonOfset) * width) / 2.0f;
        
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) {
            angleOfset = -(angleOfset);
        }
        
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.3 alpha:0.5].CGColor);
        CGContextSetShadowWithColor(context, CGSizeMake(0.5,0.5), 0.5, NULL);
        
        CGContextMoveToPoint(context, 0,topY);
        CGContextAddLineToPoint(context, self.frame.size.width, topY);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, 0,topY + (ySpacing * 1));
        CGContextAddLineToPoint(context, self.frame.size.width, topY+ (ySpacing * 1));
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context,0,topY+ (ySpacing * 2));
        CGContextAddLineToPoint(context, self.frame.size.width, topY+ (ySpacing * 2));
        CGContextStrokePath(context);
        
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.5 alpha:1.0].CGColor);
        CGContextSetShadowWithColor(context, CGSizeMake(0.5,0.5), 0.5, [UIColor blackColor].CGColor);
    
        CGContextMoveToPoint(context, leftX,topY - angleOfset);
        CGContextAddLineToPoint(context, leftX + width, topY + angleOfset);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, leftX,topY + (ySpacing * 1) - angleOfset);
        CGContextAddLineToPoint(context, leftX + width, topY+ (ySpacing * 1) + angleOfset);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, leftX,topY+ (ySpacing * 2) - angleOfset);
        CGContextAddLineToPoint(context, leftX + width, topY+ (ySpacing * 2) + angleOfset);
        CGContextStrokePath(context);
    }
}


@end
