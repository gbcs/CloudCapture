//
//  EngineLines.m
//  Capture
//
//  Created by Gary Barnett on 7/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "EngineLines.h"

@implementation EngineLines 
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
-(void)dealloc {
    //NSLog(@"%s", __func__);
}


- (void)drawRect:(CGRect)rect
{
  //using positiondict and statusdict, figure out and draw lines between engine components
  
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.8 alpha:1.0].CGColor);
    
    CGRect cameraLoc = [[self.positionDict objectForKey:@"camera"] CGRectValue];
    CGRect diskLoc = [[self.positionDict objectForKey:@"disk"] CGRectValue];
    CGRect previewLoc = [[self.positionDict objectForKey:@"preview"] CGRectValue];
    
    if ([[self.statusDict objectForKey:@"audioControlsOnly"] boolValue] == YES) {
        
    } else if (self.directMode) {
        CGContextMoveToPoint(context, cameraLoc.origin.x + cameraLoc.size.width, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,diskLoc.origin.x - 15, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context,diskLoc.origin.x - 15, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,diskLoc.origin.x - 15, diskLoc.origin.y + (diskLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,diskLoc.origin.x, diskLoc.origin.y + (diskLoc.size.height * 0.50f));
        CGContextStrokePath(context);
        
        
        CGContextMoveToPoint(context,previewLoc.origin.x - 15, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,previewLoc.origin.x - 15, previewLoc.origin.y + (previewLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,previewLoc.origin.x, previewLoc.origin.y + (previewLoc.size.height * 0.50f));
        CGContextStrokePath(context);
    } else {
        if ([[self.statusDict objectForKey:@"histogram"] boolValue] == YES) {
            CGRect histogramLoc = [[self.positionDict objectForKey:@"histogram"] CGRectValue];
            
            CGContextMoveToPoint(context, cameraLoc.origin.x + cameraLoc.size.width, cameraLoc.origin.y + (cameraLoc.size.height * 0.67f));
            CGContextAddLineToPoint(context,cameraLoc.origin.x + cameraLoc.size.width + 10, cameraLoc.origin.y + (cameraLoc.size.height * 0.67f));
            CGContextAddLineToPoint(context,cameraLoc.origin.x + cameraLoc.size.width + 10, histogramLoc.origin.y + (histogramLoc.size.height * 0.33f));
            CGContextAddLineToPoint(context,cameraLoc.origin.x + cameraLoc.size.width, histogramLoc.origin.y + (histogramLoc.size.height * 0.33f));
            CGContextStrokePath(context);
        }
        
        CGRect cameraLoc = [[self.positionDict objectForKey:@"camera"] CGRectValue];
        CGRect chromaKeyLoc = [[self.positionDict objectForKey:@"chromakey"] CGRectValue];
        CGRect colorControlLoc = [[self.positionDict objectForKey:@"colorcontrol"] CGRectValue];
        CGRect imageEffectLoc = [[self.positionDict objectForKey:@"imageeffect"] CGRectValue];
        CGRect processLoc = [[self.positionDict objectForKey:@"overlay"] CGRectValue];
        CGRect titlingLoc = [[self.positionDict objectForKey:@"titling"] CGRectValue];
        CGRect remoteLoc = [[self.positionDict objectForKey:@"remote"] CGRectValue];
        
        BOOL chromaKeyEnabled = NO;
        BOOL colorControlEnabled = NO;
        BOOL imageEffectEnabled = NO;
        BOOL processEnabled = NO;
        BOOL titlingEnabled = NO;
        BOOL remoteEnabled = NO;
        
        //Chroma Key
        if ([[self.statusDict objectForKey:@"chromakey"] boolValue] == YES) {
            chromaKeyEnabled = YES;
        }
        
        if ([[SettingsTool settings] isiPhone4S] || [[SettingsTool settings] isIPadMini]) {
            chromaKeyEnabled = NO;
        }
        
        if (chromaKeyEnabled) {
            CGRect cameraLoc = [[self.positionDict objectForKey:@"camera"] CGRectValue];
            
            CGContextMoveToPoint(context, cameraLoc.origin.x + cameraLoc.size.width, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            CGContextAddLineToPoint(context,  chromaKeyLoc.origin.x,cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            CGContextStrokePath(context);
        } else {
            //draw from camera to bottom rail
            CGContextMoveToPoint(context, cameraLoc.origin.x + cameraLoc.size.width, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            float midX =  cameraLoc.origin.x + cameraLoc.size.width + ((chromaKeyLoc.origin.x - (cameraLoc.origin.x + cameraLoc.size.width)) /2.0f);
            
            CGContextAddLineToPoint(context,  midX , cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            CGContextAddLineToPoint(context,  midX , cameraLoc.origin.y + cameraLoc.size.height + 25);
            CGContextAddLineToPoint(context,  chromaKeyLoc.origin.x + chromaKeyLoc.size.width , cameraLoc.origin.y + cameraLoc.size.height + 25);
            CGContextStrokePath(context);
        }
        
        float startingY = cameraLoc.origin.y + cameraLoc.size.height + 25;
        
        
        //ColorControl
        if (chromaKeyEnabled ) {
            startingY = cameraLoc.origin.y + (cameraLoc.size.height * 0.50f);
        }
        
        if ([[self.statusDict objectForKey:@"colorcontrol"] boolValue] == YES) {
            colorControlEnabled = YES;
            
            CGContextMoveToPoint(context, chromaKeyLoc.origin.x + chromaKeyLoc.size.width, startingY);
            if (chromaKeyEnabled) {
                CGContextAddLineToPoint(context, colorControlLoc.origin.x, startingY);
            } else {
                float midX = chromaKeyLoc.origin.x + chromaKeyLoc.size.width + ((colorControlLoc.origin.x - (chromaKeyLoc.origin.x + chromaKeyLoc.size.width)) / 2.0f);
                
                CGContextAddLineToPoint(context, midX, startingY);
                CGContextAddLineToPoint(context, midX, colorControlLoc.origin.y + (colorControlLoc.size.height / 2.0f));
                CGContextAddLineToPoint(context, colorControlLoc.origin.x, colorControlLoc.origin.y + (colorControlLoc.size.height / 2.0f));
                
            }
            
            CGContextStrokePath(context);
            
        } else {
            if (chromaKeyEnabled ) {
                CGContextMoveToPoint(context, chromaKeyLoc.origin.x + chromaKeyLoc.size.width, startingY);
                float midX =  chromaKeyLoc.origin.x + chromaKeyLoc.size.width + ((colorControlLoc.origin.x - (chromaKeyLoc.origin.x + chromaKeyLoc.size.width)) /2.0f);
                
                CGContextAddLineToPoint(context,  midX , startingY);
                CGContextAddLineToPoint(context,  midX , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextAddLineToPoint(context,  colorControlLoc.origin.x + colorControlLoc.size.width , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextStrokePath(context);
                
                
            } else {
                CGContextMoveToPoint(context, chromaKeyLoc.origin.x + chromaKeyLoc.size.width, startingY);
                CGContextAddLineToPoint(context, colorControlLoc.origin.x + colorControlLoc.size.width, startingY);
                CGContextStrokePath(context);
            }
        }
        
        //Image Effect
        startingY = cameraLoc.origin.y + cameraLoc.size.height + 25;
        if (colorControlEnabled ) {
            startingY = cameraLoc.origin.y + (cameraLoc.size.height * 0.50f);
        }
        
        if ([[self.statusDict objectForKey:@"imageeffect"] boolValue] == YES) {
            imageEffectEnabled = YES;
            
            CGContextMoveToPoint(context, colorControlLoc.origin.x + colorControlLoc.size.width, startingY);
            if (colorControlEnabled) {
                CGContextAddLineToPoint(context, imageEffectLoc.origin.x, startingY);
            } else {
                float midX = colorControlLoc.origin.x + colorControlLoc.size.width + ((imageEffectLoc.origin.x - (colorControlLoc.origin.x + colorControlLoc.size.width)) / 2.0f);
                
                CGContextAddLineToPoint(context, midX, startingY);
                CGContextAddLineToPoint(context, midX, imageEffectLoc.origin.y + (imageEffectLoc.size.height / 2.0f));
                CGContextAddLineToPoint(context, imageEffectLoc.origin.x, imageEffectLoc.origin.y + (imageEffectLoc.size.height / 2.0f));
                
            }
            
            CGContextStrokePath(context);
            
        } else {
            if (colorControlEnabled ) {
                
                CGContextMoveToPoint(context, colorControlLoc.origin.x + colorControlLoc.size.width, colorControlLoc.origin.y + (colorControlLoc.size.height / 2.0f));
                
                
                
                float midX =  colorControlLoc.origin.x + colorControlLoc.size.width + ((imageEffectLoc.origin.x - (colorControlLoc.origin.x + colorControlLoc.size.width)) /2.0f);
                
                CGContextAddLineToPoint(context,  midX , startingY);
                CGContextAddLineToPoint(context,  midX , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextAddLineToPoint(context,  imageEffectLoc.origin.x + imageEffectLoc.size.width , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextStrokePath(context);
                
                
            } else {
                CGContextMoveToPoint(context, colorControlLoc.origin.x + colorControlLoc.size.width, startingY);
                CGContextAddLineToPoint(context, imageEffectLoc.origin.x + imageEffectLoc.size.width, startingY);
                CGContextStrokePath(context);
            }
        }
        
        //Overlay
        startingY = cameraLoc.origin.y + cameraLoc.size.height + 25;
        if (imageEffectEnabled ) {
            startingY = cameraLoc.origin.y + (cameraLoc.size.height * 0.50f);
        }
        
        if ([[self.statusDict objectForKey:@"overlay"] boolValue] == YES) {
            processEnabled = YES;
            
            CGContextMoveToPoint(context, imageEffectLoc.origin.x + imageEffectLoc.size.width, startingY);
            if (imageEffectEnabled) {
                CGContextAddLineToPoint(context, processLoc.origin.x, startingY);
            } else {
                float midX = imageEffectLoc.origin.x + imageEffectLoc.size.width + ((processLoc.origin.x - (imageEffectLoc.origin.x + imageEffectLoc.size.width)) / 2.0f);
                
                CGContextAddLineToPoint(context, midX, startingY);
                CGContextAddLineToPoint(context, midX, processLoc.origin.y + (processLoc.size.height / 2.0f));
                CGContextAddLineToPoint(context, processLoc.origin.x, processLoc.origin.y + (processLoc.size.height / 2.0f));
                
            }
            
            CGContextStrokePath(context);
            
        } else {
            if (imageEffectEnabled ) {
                CGContextMoveToPoint(context, imageEffectLoc.origin.x + imageEffectLoc.size.width, startingY);
                float midX =  imageEffectLoc.origin.x + imageEffectLoc.size.width + ((processLoc.origin.x - (imageEffectLoc.origin.x + imageEffectLoc.size.width)) /2.0f);
                
                CGContextAddLineToPoint(context,  midX , startingY);
                CGContextAddLineToPoint(context,  midX , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextAddLineToPoint(context,  processLoc.origin.x + processLoc.size.width , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextStrokePath(context);
                
                
            } else {
                CGContextMoveToPoint(context, imageEffectLoc.origin.x + imageEffectLoc.size.width, startingY);
                CGContextAddLineToPoint(context, processLoc.origin.x + processLoc.size.width, startingY);
                CGContextStrokePath(context);
            }
        }
        
        //Titling
        startingY = cameraLoc.origin.y + cameraLoc.size.height + 25;
        if (processEnabled ) {
            startingY = cameraLoc.origin.y + (cameraLoc.size.height * 0.50f);
        }
        
        if ([[self.statusDict objectForKey:@"titling"] boolValue] == YES) {
            titlingEnabled = YES;
            
            CGContextMoveToPoint(context, processLoc.origin.x + processLoc.size.width, startingY);
            if (processEnabled) {
                CGContextAddLineToPoint(context, titlingLoc.origin.x, startingY);
            } else {
                float midX = processLoc.origin.x + processLoc.size.width + ((titlingLoc.origin.x - (processLoc.origin.x + processLoc.size.width)) / 2.0f);
                
                CGContextAddLineToPoint(context, midX, startingY);
                CGContextAddLineToPoint(context, midX, titlingLoc.origin.y + (titlingLoc.size.height / 2.0f));
                CGContextAddLineToPoint(context, titlingLoc.origin.x, titlingLoc.origin.y + (titlingLoc.size.height / 2.0f));
                
            }
            
            CGContextStrokePath(context);
            
        } else {
            if (processEnabled ) {
                CGContextMoveToPoint(context, processLoc.origin.x + processLoc.size.width, startingY);
                float midX =  processLoc.origin.x + processLoc.size.width + ((titlingLoc.origin.x - (processLoc.origin.x + processLoc.size.width)) /2.0f);
                
                CGContextAddLineToPoint(context,  midX , startingY);
                CGContextAddLineToPoint(context,  midX , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextAddLineToPoint(context,  titlingLoc.origin.x + titlingLoc.size.width , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextStrokePath(context);
                
                
            } else {
                CGContextMoveToPoint(context, processLoc.origin.x + processLoc.size.width, startingY);
                CGContextAddLineToPoint(context, titlingLoc.origin.x + titlingLoc.size.width, startingY);
                CGContextStrokePath(context);
            }
        }
        
        
        //Remote
        startingY = cameraLoc.origin.y + cameraLoc.size.height + 25;
        if (titlingEnabled ) {
            startingY = cameraLoc.origin.y + (cameraLoc.size.height * 0.50f);
        }
        
        if ([[self.statusDict objectForKey:@"remote"] boolValue] == YES) {
            remoteEnabled = YES;
            
            CGContextMoveToPoint(context, titlingLoc.origin.x + titlingLoc.size.width, startingY);
            if (titlingEnabled) {
                CGContextAddLineToPoint(context, remoteLoc.origin.x, startingY);
            } else {
                float midX = titlingLoc.origin.x + titlingLoc.size.width + ((remoteLoc.origin.x - (titlingLoc.origin.x + titlingLoc.size.width)) / 2.0f);
                
                CGContextAddLineToPoint(context, midX, startingY);
                CGContextAddLineToPoint(context, midX, remoteLoc.origin.y + (remoteLoc.size.height / 2.0f));
                CGContextAddLineToPoint(context, remoteLoc.origin.x, remoteLoc.origin.y + (remoteLoc.size.height / 2.0f));
                
            }
            
            CGContextStrokePath(context);
            
        } else {
            if (titlingEnabled ) {
                CGContextMoveToPoint(context, titlingLoc.origin.x + titlingLoc.size.width, startingY);
                float midX =  titlingLoc.origin.x + titlingLoc.size.width + ((remoteLoc.origin.x - (titlingLoc.origin.x + titlingLoc.size.width)) /2.0f);
                
                CGContextAddLineToPoint(context,  midX , startingY);
                CGContextAddLineToPoint(context,  midX , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextAddLineToPoint(context,  remoteLoc.origin.x + remoteLoc.size.width , cameraLoc.origin.y + cameraLoc.size.height + 25);
                CGContextStrokePath(context);
                
                
            } else {
                CGContextMoveToPoint(context, titlingLoc.origin.x + titlingLoc.size.width, startingY);
                CGContextAddLineToPoint(context, remoteLoc.origin.x + remoteLoc.size.width, startingY);
                CGContextStrokePath(context);
            }
        }
        
        
        if (remoteEnabled) {
            CGContextMoveToPoint(context,remoteLoc.origin.x + remoteLoc.size.width, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            CGContextAddLineToPoint(context,previewLoc.origin.x - 15, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            CGContextStrokePath(context);
        } else {
            CGContextMoveToPoint(context,remoteLoc.origin.x + remoteLoc.size.width,  cameraLoc.origin.y + cameraLoc.size.height + 25);
            CGContextAddLineToPoint(context,previewLoc.origin.x - 25, cameraLoc.origin.y + cameraLoc.size.height + 25);
            CGContextAddLineToPoint(context,previewLoc.origin.x - 25, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            CGContextAddLineToPoint(context,previewLoc.origin.x - 15, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
            CGContextStrokePath(context);
        }
        
        
        CGContextMoveToPoint(context,diskLoc.origin.x - 15, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,diskLoc.origin.x - 15, diskLoc.origin.y + (diskLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,diskLoc.origin.x, diskLoc.origin.y + (diskLoc.size.height * 0.50f));
        CGContextStrokePath(context);
        
        
        CGContextMoveToPoint(context,previewLoc.origin.x - 15, cameraLoc.origin.y + (cameraLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,previewLoc.origin.x - 15, previewLoc.origin.y + (previewLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,previewLoc.origin.x, previewLoc.origin.y + (previewLoc.size.height * 0.50f));
        CGContextStrokePath(context);
        
    }
    
    
    if ([[self.statusDict objectForKey:@"microphone"] boolValue] == YES) {
        
        CGRect microphoneLoc = [[self.positionDict objectForKey:@"microphone"] CGRectValue];
        
        CGRect audioDiskLoc = [[self.positionDict objectForKey:@"audioDisk"] CGRectValue];
        
        CGRect headphoneLoc = [[self.positionDict objectForKey:@"headphone"] CGRectValue];
        
        CGContextMoveToPoint(context, microphoneLoc.origin.x + microphoneLoc.size.width, microphoneLoc.origin.y + (microphoneLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,audioDiskLoc.origin.x - 15, microphoneLoc.origin.y + (microphoneLoc.size.height * 0.50f));
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context,audioDiskLoc.origin.x - 15, microphoneLoc.origin.y + (microphoneLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,audioDiskLoc.origin.x - 15, audioDiskLoc.origin.y + (audioDiskLoc.size.height * 0.50f));
        CGContextAddLineToPoint(context,audioDiskLoc.origin.x, audioDiskLoc.origin.y + (audioDiskLoc.size.height * 0.50f));
        CGContextStrokePath(context);
        
        if ([[self.statusDict objectForKey:@"headphone"] boolValue] == YES) {
             CGContextMoveToPoint(context,audioDiskLoc.origin.x - 15, microphoneLoc.origin.y + (microphoneLoc.size.height * 0.50f));
             CGContextAddLineToPoint(context,audioDiskLoc.origin.x - 15, headphoneLoc.origin.y + (headphoneLoc.size.height * 0.50f));
             CGContextAddLineToPoint(context,audioDiskLoc.origin.x, headphoneLoc.origin.y + (headphoneLoc.size.height * 0.50f));
             CGContextStrokePath(context);
        }
    }
}

@end
