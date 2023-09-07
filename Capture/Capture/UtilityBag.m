//
//  UtilityBag.m
//  Capture
//
//  Created by Gary Barnett on 7/25/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "UtilityBag.h"
#import <AVFoundation/AVFoundation.h>
#include <sys/param.h>
#include <sys/mount.h>
#import <ImageIO/ImageIO.h>
#import "Flurry.h"
#import <Security/Security.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SSKeychain.h"
#import "SSKeychainQuery.h"


@implementation UtilityBag {
    NSShadow *blackShadowForText;
    NSDate *operationStartTime;
    NSTimeInterval lastInterval;
}

static UtilityBag  *sharedSettingsManager = nil;

+ (UtilityBag *)bag
{
    if (sharedSettingsManager == nil) {
        sharedSettingsManager = [[super allocWithZone:NULL] init];
    }
    
    return sharedSettingsManager ;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self bag];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


-(void)removeClip:(NSString *)clip {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSString *fPath = [[self docsPath] stringByAppendingPathComponent:clip];
    //NSLog(@"Deleting:%@",fPath );
    [fileManager removeItemAtPath:fPath error:&error];
}


-(UIColor*)colorWithHexString:(NSString*)hex withAlpha:(float)alpha {
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    // strip # if it appears
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:alpha];
}

-(UIColor*)colorWithHexString:(NSString*)hex
{
    return [self colorWithHexString:hex withAlpha:1.0f];
}

-(NSShadow *)getBlackShadowForText {
    if (!blackShadowForText) {
        blackShadowForText = [[NSShadow alloc] init];
        blackShadowForText.shadowColor = [[UtilityBag bag] colorWithHexString:@"#000000"];
        blackShadowForText.shadowOffset = CGSizeMake(1,1.0f);
    }
    return blackShadowForText;
}

-(NSString *)docsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

- (NSString *)pathForNewResourceWithExtension:(NSString *)prefix suggestedFileName:(NSString *)suggested
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *result = nil;
    
    NSFileManager *fM = [[NSFileManager alloc] init];
    BOOL fileAlreadyExists = YES;
    
    NSString *resourceFileName = nil;
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    resourceFileName =[NSString stringWithFormat:@"%@.%@", suggested,
                       prefix ? prefix : @"noext"
                       ];
    
    if ([fM fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:resourceFileName]]) {
        while (fileAlreadyExists) {
            resourceFileName = [NSString stringWithFormat:@"%@%@.%@",
                                suggested,
                                [uuid substringToIndex:8],
                                prefix ? prefix : @"noext"
                                ];
            
            if ([fM fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:resourceFileName]]) {
                [NSThread sleepForTimeInterval:1];
            } else {
                fileAlreadyExists = NO;
            }
        }
    }
    
    result = resourceFileName;
    
    assert(result != nil);
    
    return result;
}

- (NSString *)pathForNewResourceWithExtension:(NSString *)prefix
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *result = nil;
    
    NSFileManager *fM = [[NSFileManager alloc] init];
    BOOL fileAlreadyExists = YES;
    
    NSString *resourceFileName = nil;
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    while (fileAlreadyExists) {
        resourceFileName = [NSString stringWithFormat:@"%@.%@",
                            [uuid substringToIndex:16],
                            prefix ? prefix : @"noext"
                            ];
        
        if ([fM fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:resourceFileName]]) {
            [NSThread sleepForTimeInterval:1];
        } else {
            fileAlreadyExists = NO;
        }
    }
    
    result = resourceFileName;
    
    assert(result != nil);
    
    return result;
}

- (NSString *)pathForNewUnreviewedStillWithExtension:(NSString *)prefix
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"unreviewedStills"];
    
    NSString *result = nil;
    
    NSFileManager *fM = [[NSFileManager alloc] init];
    BOOL fileAlreadyExists = YES;
    
    NSString *resourceFileName = nil;
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    while (fileAlreadyExists) {
        resourceFileName = [NSString stringWithFormat:@"%@.%@",
                            [uuid substringToIndex:16],
                            prefix ? prefix : @"noext"
                            ];
        
        if ([fM fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:resourceFileName]]) {
            [NSThread sleepForTimeInterval:1];
        } else {
            fileAlreadyExists = NO;
        }
    }
    
    result = resourceFileName;
    
    assert(result != nil);
    
    return result;
}




-(NSArray *)engineImageList {
    NSFileManager *fM = [[NSFileManager alloc] init];
    NSError *error = nil;
    
    NSArray *list = [fM  contentsOfDirectoryAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] error:&error];
    
    if (list) {
        return list;
    }
    
    return @[ ];
}



- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize usingImage:(UIImage *)sourceImage rotated:(BOOL)rotated mirror:(BOOL)mirror {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
        {
            scaleFactor = widthFactor; // scale to fit height
        }
        else
        {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }

    UIGraphicsBeginImageContext(targetSize); // this will crop
   
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (rotated) {
        CGContextTranslateCTM( context, 0.5f * targetSize.width, 0.5f * targetSize.height ) ;
        CGContextRotateCTM( context, M_PI ) ;
        if (mirror) {
            CGContextScaleCTM(context, -1, 1);
        }
        CGContextTranslateCTM( context, -(0.5f * targetSize.width), -(0.5f * targetSize.height) ) ;
    } else if (mirror) {
        CGContextTranslateCTM( context, 0.5f * targetSize.width, 0.5f * targetSize.height ) ;
        if (mirror) {
            CGContextScaleCTM(context, -1, 1);
        }
        CGContextTranslateCTM( context, -(0.5f * targetSize.width), -(0.5f * targetSize.height) ) ;
    }
 
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil)
    {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}


typedef struct {
    long nominator;
    long denominator;
    double error;
} Fraction;

/*
 * Find rational approximation to given real number
 * David Eppstein / UC Irvine / 8 Aug 1993
 *
 * With corrections from Arno Formella, May 2008
 * Function wrapper by Regexident, April 2011
 *
 * usage: fractionFromReal(double realNumber, long maxDenominator)
 *   realNumber: is real number to approx
 *   maxDenominator: is the maximum denominator allowed
 *
 * based on the theory of continued fractions
 * if x = a1 + 1/(a2 + 1/(a3 + 1/(a4 + ...)))
 * then best approximation is found by truncating this series
 * (with some adjustments in the last term).
 *
 * Note the fraction can be recovered as the first column of the matrix
 *  ( a1 1 ) ( a2 1 ) ( a3 1 ) ...
 *  ( 1  0 ) ( 1  0 ) ( 1  0 )
 * Instead of keeping the sequence of continued fraction terms,
 * we just keep the last partial product of these matrices.
 */
Fraction fractionFromReal(double realNumber, long maxDenominator) {
    double atof();
    int atoi();
    void exit();
    
    long m[2][2];
    double startx;
    long ai;
    
    startx = realNumber;
    
    // initialize matrix:
    m[0][0] = m[1][1] = 1;
    m[0][1] = m[1][0] = 0;
    
    // loop finding terms until denom gets too big:
    while (m[1][0] *  (ai = (long)realNumber) + m[1][1] <= maxDenominator) {
        long t;
        t = m[0][0] * ai + m[0][1];
        m[0][1] = m[0][0];
        m[0][0] = t;
        t = m[1][0] * ai + m[1][1];
        m[1][1] = m[1][0];
        m[1][0] = t;
        
        if (realNumber == (double)ai) {
            // AF: division by zero
            break;
        }
        
        realNumber = 1 / (realNumber - (double)ai);
        
        if (realNumber > (double)0x7FFFFFFF) {
            // AF: representation failure
            break;
        }
    }
    
    ai = (maxDenominator - m[1][1]) / m[1][0];
    m[0][0] = m[0][0] * ai + m[0][1];
    m[1][0] = m[1][0] * ai + m[1][1];
    return (Fraction) { .nominator = m[0][0], .denominator = m[1][0], .error = startx - ((double)m[0][0] / (double)m[1][0]) };
}
        
-(NSString *)rationalToFraction:(NSNumber*)rational{
    double aReal = [rational doubleValue];
    
    long maxDenominator = 100;
    Fraction aFraction = fractionFromReal(aReal, maxDenominator);
   
    return [NSString stringWithFormat:@"%ld/%ld", aFraction.nominator, aFraction.denominator];
}

-(NSString *)convertShutterSpeed:(NSNumber *)n {
    float r = pow(2.0f, [n floatValue]);
    
    NSInteger d = (NSInteger)r;
    
    
    return [NSString stringWithFormat:@"1/%ld", (long)d];
    
}

-(void)makeThumbnail:(NSString *)moviePath {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:moviePath] isDirectory:NO] options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = YES;
    [generate setMaximumSize:CGSizeMake(110,62)];
    NSError *err = NULL;
    CMTime time = CMTimeMake(0, 30);
    CGImageRef thumbCGImage = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    
    UIImage *i = [UIImage imageWithCGImage:thumbCGImage];
    
    NSData *thumbData = UIImagePNGRepresentation(i);
    
    NSString *movieBaseName = [moviePath stringByDeletingPathExtension];
    
    NSString *metaPath = [[[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:movieBaseName] stringByAppendingPathExtension:@"png"];
    NSError *error = nil;
    [thumbData writeToFile:metaPath options:NSDataWritingFileProtectionNone error:&error];
    
    if (error) {
        NSLog(@"Unable to create thumbnail for:%@", moviePath);
    }
    
}

-(AVMutableMetadataItem *)uniqueMetadataEntry {
   AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.locale = [NSLocale currentLocale];
    item.key = AVMetadataCommonKeyDescription;
    item.value = [NSString stringWithFormat:@"%@", [self generateGUID]];
    return item;
}

-(NSString *)generateGUID {
    NSString * result;
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    
    result =[NSString stringWithFormat:@"%@", string];
    CFRelease(string);
    
    assert(result != nil);
    
    return result;
}

-(NSString *)strForOSSStatus:(OSStatus )status {
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    return [error localizedDescription];
}

-(NSNumber *)getfreeDiskSpaceInBytes {
    NSDictionary *atDict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[[UtilityBag bag] docsPath] error:NULL];
    return [atDict objectForKey:NSFileSystemFreeSize];
}


-(void)saveCGImageAsPicture:(CGImageRef )pic {
    UIImage *still = [UIImage imageWithCGImage:pic];
    
    NSData *d = UIImagePNGRepresentation(still);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache, nil];
    
    
    CGImageSourceRef r = CGImageSourceCreateWithData((__bridge CFDataRef)(d), (__bridge CFDictionaryRef)options);
    
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(r, 0, (__bridge CFDictionaryRef)options);
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageDataToSavedPhotosAlbum:d metadata:(__bridge NSDictionary *)(imageProperties) completionBlock:^(NSURL *assetURL, NSError *error) {
        CFRelease(r);
    }];
}

-(UIFont *)standardFont {
    return [UIFont systemFontOfSize:12];
}

-(UIFont *)standardFontBold {
    return [UIFont boldSystemFontOfSize:12];
}

-(CGFloat)hueForColorwithR:(CGFloat)r G:(CGFloat)g B:(CGFloat)b {
    float hsv[3];
    
    float min, max, delta;
    //float *h = hsv[0], *s = hsv[1], *v = hsv[2];
    
    min = MIN( r, MIN( g, b ));
    max = MAX( r, MAX( g, b ));
    hsv[2] = max;               // v
    delta = max - min;
    if( max != 0 )
        hsv[1] = delta / max;       // s
    else {
            // r = g = b = 0        // s = 0, v is undefined
        hsv[1] = 0;
        hsv[0] = -1;
        return hsv[0];
    }
    if( r == max )
        hsv[0] = ( g - b ) / delta;     // between yellow & magenta
    else if( g == max )
        hsv[0] = 2 + ( b - r ) / delta; // between cyan & yellow
    else
        hsv[0] = 4 + ( r - g ) / delta; // between magenta & cyan
    hsv[0] *= 60;               // degrees
    if( hsv[0] < 0 )
        hsv[0] += 360;
    hsv[0] /= 360.0;

    
    return hsv[0];
}

-(NSString *)deviceTypeSpecificNibName:(NSString *)nibNameIn {
    
    NSString *nibName = nibNameIn;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        nibName = [nibName stringByAppendingString:@"iPad"];
    }
    
    return nibName;
}

-(NSString *)durationStr:(NSInteger )seconds {
    NSString *str = @"--:--:--";
    if (seconds >= 0) {
        NSInteger hours = seconds / (60 * 60);
        NSInteger mins = (seconds - (hours * 60*60)) / 60;
        NSInteger secs = seconds - (hours * 60 * 60) - (mins * 60);
        str = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)mins, (long)secs];
    }
    return str;
}

-(void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)dict {
    [Flurry logEvent:eventName withParameters:dict];
   // NSLog(@"Logged Flurry Event:%@:%@", eventName, dict);
    [[SettingsTool settings] incrementInterestingActions];
}

-(void)logEventEnd:(NSString *)event withParameters:(NSDictionary *)dict {
    [Flurry endTimedEvent:event withParameters:dict];
}

-(void)rateApp {
    NSString *rateStr = @"http://cloudcapt.com/rating.free.url";
#ifdef CCPRO
    rateStr = @"http://cloudcapt.com/rating.pro.url";
#endif
    NSString *rateURLStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:rateStr] encoding:NSStringEncodingConversionAllowLossy error:nil];
    if (rateURLStr) {
        if ([rateURLStr hasPrefix:@"https://itunes.apple.com/"] || [rateURLStr hasPrefix:@"http://itunes.apple.com/"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:rateURLStr]];
        }
    }
    
    
}

-(void)buyApp {
    NSString *rateStr = @"http://cloudcapt.com/purchase.url";
    NSString *rateURLStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:rateStr] encoding:NSStringEncodingConversionAllowLossy error:nil];
    if (rateURLStr) {
        if ([rateURLStr hasPrefix:@"https://itunes.apple.com/"] || [rateURLStr hasPrefix:@"http://itunes.apple.com/"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:rateURLStr]];
        }
    }
}

/*

 
 - (BOOL)saveCredentials:(NSError **)error {
 SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
 query.password = @"MySecretPassword";
 query.service = @"MyAwesomeService";
 query.account = @"John Doe";
 query.synchronizable = YES;
 return [query save:&error];
 }
 
 - (NSString *)savedPassword:(NSError **)error {
 SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
 query.service = @"MyAwesomeService";
 query.account = @"John Doe";
 query.synchronizable = YES;
 query.password = nil;
 if ([query fetch:&error]) {
 return query.password;
 }
 return nil;
 }*/


-(void)saveInKeychainForServer:(NSString *)server withUsername:(NSString *)user andPassword:(NSString *)password {
    [self deleteFromKeychainForServer:server andUsername:user];
 
    NSError *error = nil;
     SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
     query.password = password;
     query.service = server;
     query.account = user;
        // query.synchronizable = YES;
    
   [query save:&error];
     
}

-(NSString *)passwordFromKeychainForServer:(NSString *)server andUsername:(NSString *)user {
    NSError *error = nil;
    SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
    query.service = server;
    query.account = user;
        //query.synchronizable = YES;
    query.password = nil;
    if ([query fetch:&error]) {
        return query.password;
    }
    return nil;
}

-(void)deleteFromKeychainForServer:(NSString *)server andUsername:(NSString *)user {
    NSError *error = nil;
    SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
    query.service = server;
    query.account = user;
        // query.synchronizable = YES;
    
    [query deleteItem:&error];
    
}

-(void)logTime:(NSString *)label {
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    NSLog(@"%@:%0.4f", label ? label : @"", timeInMiliseconds);
}

-(void)makeCopyOfAsset:(ALAssetRepresentation *)rep withDelegate:(NSObject <AssetCopyDelegate> *)delegate {
    _assetCopyDelegate = delegate;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *tmpFilePath = nil;
        
        if (1 == 2) {
            [NSThread sleepForTimeInterval:5.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_assetCopyDelegate assetCopyDidCompleteWithError:YES andMessage:@"Test Failure Message Goes Here; with some extra padding"];
                _assetCopyDelegate = nil;
            });
            return;
        }
        
        
        NSString *filePath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[UtilityBag bag] pathForNewResourceWithExtension:@"mov"]];
        
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        if (!handle) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_assetCopyDelegate assetCopyDidCompleteWithError:YES andMessage:@"Unable to create a local file for the copy."];
                _assetCopyDelegate = nil;
            });
            return;
        }
        
        NSNumber *fileSpace = [NSNumber numberWithLongLong:[rep size]];
        NSNumber *freeSpace = [[UtilityBag bag] getfreeDiskSpaceInBytes];
        
        if ([freeSpace compare:fileSpace] == NSOrderedAscending) {
            [_assetCopyDelegate assetCopyDidCompleteWithError:YES andMessage:@"Not enough free space to store the required temporary copy."];
            _assetCopyDelegate = nil;
            return;
        }
        
        static const NSUInteger BufferSize = 1024*1024;
        
        uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
        NSUInteger offset = 0, bytesRead = 0;
        NSUInteger totalRead = 0;
        do {
            @try {
                bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:nil];
                [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
                offset += bytesRead;
            } @catch (NSException *exception) {
                free(buffer);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_assetCopyDelegate assetCopyDidCompleteWithError:YES andMessage:@"Unable to complete the copy."];
                    _assetCopyDelegate = nil;
                });
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                return ;
            }
            totalRead += bytesRead;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_assetCopyDelegate assetCopyProgress:(float)[rep size] / (float)totalRead];
            });
        } while (bytesRead > 0);
        
        free(buffer);
        tmpFilePath = filePath;
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_assetCopyDelegate assetCopyDidCompleteWithError:NO andMessage:[filePath lastPathComponent]];
            _assetCopyDelegate = nil;
        });
    });
}

-(void)startTimingOperation {
    operationStartTime = [NSDate date];
    lastInterval = 999999999;
}

-(NSString *)returnRemainingTimeForOperationWithProgress:(CGFloat )progress {
    if (progress >= 1.0f) {
        return @"Complete";
    } else if ( (!operationStartTime) || (progress < 0.1f) ) {
        return @"Processing";
    }
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:operationStartTime];
    
    NSTimeInterval estimated = elapsed / progress;
    
    NSTimeInterval timeLeft = estimated - elapsed;
    
    if (timeLeft > lastInterval) {
        timeLeft = lastInterval;
    } else {
        lastInterval = timeLeft;
    }
    
    NSInteger hours = (long)(timeLeft / 3600.0f);
    NSInteger mins = (long)((timeLeft - (hours * 3600.0f)) / 60.0f);
    NSInteger secs = timeLeft - (hours * 3600.0f) - (mins * 60.0f);

    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)mins, (long)secs];
}

@end
