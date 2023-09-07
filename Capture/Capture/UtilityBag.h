//
//  UtilityBag.h
//  Capture
//
//  Created by Gary Barnett on 7/25/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define DEGREES_TO_RADIANS(x) (M_PI * x / 180.0)
#define TICK   NSDate *startTime = [NSDate date]
#define TOCK   NSLog(@"Time: %f", -[startTime timeIntervalSinceNow])

@protocol AssetCopyDelegate <NSObject>
-(void)assetCopyProgress:(CGFloat )f;
-(void)assetCopyDidCompleteWithError:(BOOL)hadError andMessage:(NSString *)message;
@end

@interface UtilityBag : NSObject
@property (nonatomic, weak) NSObject <AssetCopyDelegate> *assetCopyDelegate;
+(UtilityBag *)bag;

-(UIColor*)colorWithHexString:(NSString*)hex withAlpha:(float)alpha;
-(UIColor*)colorWithHexString:(NSString*)hex;

-(NSShadow *)getBlackShadowForText;

-(NSString *)docsPath;

-(void)removeClip:(NSString *)clip;

- (NSString *)pathForNewResourceWithExtension:(NSString *)prefix suggestedFileName:(NSString *)suggested;
- (NSString *)pathForNewResourceWithExtension:(NSString *)prefix;
- (NSString *)pathForNewUnreviewedStillWithExtension:(NSString *)prefix;

-(NSString *)rationalToFraction:(NSNumber*)rational;
-(NSString *)convertShutterSpeed:(NSNumber *)n;

-(void)makeThumbnail:(NSString *)moviePath;

-(AVMutableMetadataItem *)uniqueMetadataEntry;
-(NSString *)generateGUID;

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize usingImage:(UIImage *)sourceImage rotated:(BOOL)rotated mirror:(BOOL)mirror;
-(NSArray *)engineImageList;

-(NSString *)strForOSSStatus:(OSStatus )status;
-(NSNumber *)getfreeDiskSpaceInBytes;
-(void)saveCGImageAsPicture:(CGImageRef )pic;
-(UIFont *)standardFont;
-(UIFont *)standardFontBold;

-(CGFloat)hueForColorwithR:(CGFloat)r G:(CGFloat)g B:(CGFloat)b;

-(NSString *)deviceTypeSpecificNibName:(NSString *)nibNameIn;
-(NSString *)durationStr:(NSInteger )seconds;

-(void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)dict;
-(void)logEventEnd:(NSString *)event withParameters:(NSDictionary *)dict;


-(NSString *)passwordFromKeychainForServer:(NSString *)server andUsername:(NSString *)user;
-(void)deleteFromKeychainForServer:(NSString *)server andUsername:(NSString *)user;


-(void)saveInKeychainForServer:(NSString *)server withUsername:(NSString *)user andPassword:(NSString *)password;

-(void)logTime:(NSString *)label;
-(void)makeCopyOfAsset:(ALAssetRepresentation *)rep withDelegate:(NSObject <AssetCopyDelegate> *)delegate;
-(void)rateApp;
-(void)buyApp;

-(void)startTimingOperation;
-(NSString *)returnRemainingTimeForOperationWithProgress:(CGFloat )progress;

@end
