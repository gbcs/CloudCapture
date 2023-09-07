//
//  SyncManager.h
//  Capture
//
//  Created by Gary Barnett on 7/19/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyncManager : NSObject


+(SyncManager *)manager;

-(void)prepareUploadTargets;

-(BOOL)loginToUploadTargets;

-(BOOL)handleOpenURL:(NSURL *)url;

-(UIView *)progressContainer;
-(void)updateProgress:(CGFloat)progress;
-(void)updateProgressTitle:(NSString *)title;

@end
