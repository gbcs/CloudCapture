//
//  PresetHandler.h
//  Capture
//
//  Created by Gary Barnett on 11/25/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PresetHandler : NSObject


+(PresetHandler *)tool;

-(NSArray *)presetList;
-(void)loadPresetWithName:(NSString *)name;
-(void)saveCurrentPreset;
-(void)deletePresetWithName:(NSString *)name;
-(void)addPresetWithName:(NSString *)name;
-(NSString *)currentPreset;

@end
