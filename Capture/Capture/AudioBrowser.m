//
//  AudioBrowser.m
//  Capture
//
//  Created by Gary Barnett on 12/10/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioBrowser.h"

@implementation AudioBrowser {
    MPMediaQuery *artistQuery;
    BOOL ready;
    NSArray *artists;
    NSMutableDictionary *itemsDict;
    NSArray *appLibraryDurations;
    __strong AVAssetExportSession *exporter;
    __strong AVComposition *composition;
}

static AudioBrowser  *sharedSettingsManager = nil;

+ (AudioBrowser *)manager
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


-(BOOL)isReady {
    return ready;
}


-(void)resetStorage {
    
}

-(void)cleanup {
    ready = NO;
    artists = @[ ];
    [itemsDict removeAllObjects];
    artistQuery = nil;
    appLibraryDurations = nil;
}

-(void)update {
    ready = NO;
    
    if (artistQuery) {
        artistQuery = nil;
    }
    
    artistQuery = [MPMediaQuery artistsQuery];
                    
    [itemsDict removeAllObjects];
    
    artists = @[ ];
    itemsDict = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    NSMutableArray *artistList = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (MPMediaItemCollection *collection in [[MPMediaQuery artistsQuery] collections]) {
        MPMediaItem *item = [collection representativeItem];
        NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        
        if (!assetURL) {
                // NSLog(@"Skipping %@; no AssetURL", [item valueForProperty:MPMediaItemPropertyAlbumTitle]);
            continue;
        }
       NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL options:asset_options];
        if ([asset hasProtectedContent]) {
                // NSLog(@"Skipping %@; hasProtectedContent", [item valueForProperty:MPMediaItemPropertyAlbumTitle]);
            continue;
        }
        
        NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
        NSInteger artistIndex = [artistList indexOfObject:artist];
        
        if (artistIndex == NSNotFound) {
            [artistList addObject:artist];
            [itemsDict setObject:@[ ] forKey:artist];
            [itemsDict setObject:[collection items] forKey:artist];
        } else {
            NSLog(@"Duplicate artist:%@", artist);
        }
    }
    
    NSArray *artistsTmp = [artistList sortedArrayUsingSelector:@selector(compare:)];
    
    artists = [@[@"App Library"] arrayByAddingObjectsFromArray:artistsTmp];
    
    [itemsDict setObject:[self enumerateLocalAudioFiles] forKey:@"App Library"];

    ready = YES;
}

-(void)removeAppLibraryAudioItemAtIndex:(NSInteger)index {
    NSError * error;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *list = [itemsDict objectForKey:[artists objectAtIndex:0]];
    NSString *filename = [list objectAtIndex:index];
    
    NSMutableArray *l = [list mutableCopy];
    [l removeObjectAtIndex:index];
    [itemsDict setObject:[l copy] forKey:[artists objectAtIndex:0]];
    
    [fileManager removeItemAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:filename] error:&error];
}



-(NSArray *)enumerateLocalAudioFiles {
    
    NSError * error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UtilityBag bag] docsPath] error:&error];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSMutableArray *audioList = [[NSMutableArray alloc] initWithCapacity:10];
    NSMutableArray *durationList = [[NSMutableArray alloc] initWithCapacity:10];
    
    if ( (!error) && directoryContents) {
        NSMutableDictionary *vMap = [[NSMutableDictionary alloc] initWithCapacity:[directoryContents count]];
        NSMutableDictionary *vSort = [[NSMutableDictionary alloc] initWithCapacity:[directoryContents count]];
        
        for (NSString *entry in directoryContents) {
            NSString *ext = [[entry pathExtension] lowercaseString];
            if ([ext isEqualToString:@"wav"] || [ext isEqualToString:@"aac"] || [ext isEqualToString:@"m4a"] || [ext isEqualToString:@"mp3"] || [ext isEqualToString:@"aif"] || [ext isEqualToString:@"aiff"]) {
                NSDictionary *attribs = [fileManager attributesOfItemAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:entry] error:&error];
                if (!attribs) {
                    NSLog(@"No file attribs; skipping:%@", entry);
                } else {
                    [vMap setObject:attribs forKey:entry];
                    [vSort setObject:[attribs objectForKey:NSFileModificationDate] forKey:entry];
                }
            }
        }
        
        NSArray *sortedKeys = [[[vSort keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
            
            if ([obj1 compare: obj2] == NSOrderedDescending) {
                
                return (NSComparisonResult)NSOrderedDescending;
            }
            if ([obj1 compare: obj2] == NSOrderedAscending) {
                
                return (NSComparisonResult)NSOrderedAscending;
            }
            
            return (NSComparisonResult)NSOrderedSame;
        }] reverseObjectEnumerator] allObjects];
        
        for (NSString *key in sortedKeys) {
            [audioList addObject: key ];
            NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:key]] options:asset_options];
            CMTime audioDuration = audioAsset.duration;
            [durationList addObject:[NSValue valueWithCMTime:audioDuration]];
        }
    }
    appLibraryDurations = [durationList copy];
    return [audioList copy];
}

-(NSArray *)artists {
    return artists;
}

-(UIImage *)artworkForArtistAtIndex:(NSInteger )index withSize:(CGSize )size {
    UIImage *i = nil;
    
    if (index == 0) {
        return nil;
    }
    
    NSArray *list = [itemsDict objectForKey:[artists objectAtIndex:index]];
    if ([list count] > 0) {
        MPMediaItem *item = [list objectAtIndex:0];
        MPMediaItemArtwork *artWork = [item valueForProperty:MPMediaItemPropertyArtwork];
        if (artWork) {
            i = [artWork imageWithSize:size];
        }
    }
    
    return i;
}

-(NSInteger )songCountForArtistAtIndex:(NSInteger )index {
    NSString *artist = [artists objectAtIndex:index];
    NSArray *songList = [itemsDict objectForKey:artist];
    
    return [songList count];
}

-(NSString *)entryforAppLibraryAtIndex:(NSInteger) index {
    NSArray *songList = [itemsDict objectForKey:[artists objectAtIndex:0]];
    return [songList objectAtIndex:index];
}


-(NSInteger )durationforAppLibraryAtIndex:(NSInteger) index {
    NSInteger d = -1;
    
    NSValue *v = [appLibraryDurations objectAtIndex:index];
    
    if (v) {
        d = CMTimeGetSeconds([v CMTimeValue]);
    }
    
    return d;
}


-(MPMediaItem *)entryForArtistAtIndex:(NSInteger)libIndex atEntryIndex:(NSInteger)index {
    NSString *artist = [artists objectAtIndex:libIndex];
    NSArray *songList = [itemsDict objectForKey:artist];
    return [songList objectAtIndex:index];
}


-(void)unableToRecord {
    
}

-(void)generateAudioSampleWithDuration:(NSInteger )duration {
    if (duration < 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"silentAudioFileCreated" object:@(-1)];
        return;
    }
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    NSError *editError;
   
    AVMutableCompositionTrack *audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSString *oneSecPath = [[NSBundle mainBundle] pathForResource:@"one_sec_silence" ofType:@"wav"];
    AVURLAsset *assetSec = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:oneSecPath]];
    AVAssetTrack *clipSecondTrack = [[assetSec tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
   
    NSString *oneMinPath = [[NSBundle mainBundle] pathForResource:@"one_min_silence" ofType:@"m4a"];
    AVURLAsset *assetMin = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:oneMinPath]];
    AVAssetTrack *clipMinuteTrack = [[assetMin tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    CMTimeRange oneMinRange = CMTimeRangeMake(CMTimeMake(0, 1), CMTimeMake(60, 1));
   
    CMTime curTime = kCMTimeZero;
    
    NSInteger mins = duration / 60;
    
    if (duration >= 60) {
        for (NSInteger x=0;x<mins;x++) {
            NSError *error = nil;
            [audioTrack insertTimeRange:oneMinRange ofTrack:clipMinuteTrack atTime:CMTimeMake(x * 60, 1) error:&error];
            if (error) {
                NSLog(@"err:%@", [error localizedDescription]);
            }
        }
        curTime = CMTimeMake(60*mins,1);
    }
    
    
    NSInteger secs = duration - (mins * 60);

    if (secs > 0) {
        for (NSInteger x=0;x<secs;x++) {
            CMTimeRange oneSecRange = CMTimeRangeMake(CMTimeMake(0, 1), CMTimeMake(1, 1));
            [audioTrack insertTimeRange:oneSecRange ofTrack:clipSecondTrack atTime:curTime error:&editError];
            curTime = CMTimeAdd(curTime, CMTimeMake(1,1));
        }
    }

    composition  = [mutableComposition copy];
   
    NSString *audioFile = [[UtilityBag bag] pathForNewResourceWithExtension:@"m4a"];
    NSString *audioPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:audioFile];
 
    exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    exporter.outputFileType=AVFileTypeAppleM4A;
    exporter.outputURL= [NSURL fileURLWithPath:audioPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *originalTimeStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableArray *metadata = [[NSMutableArray alloc] initWithCapacity:3];
        
    AVMutableMetadataItem *item = nil;
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.key = AVMetadataCommonKeyCreationDate;
    item.value = originalTimeStr;
    [metadata addObject:item];
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceQuickTimeUserData;
    item.key = AVMetadataQuickTimeUserDataKeyTrack;
    item.value = [NSNumber numberWithInt:1];
    [metadata addObject:item];
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.locale = [NSLocale currentLocale];
    item.key = AVMetadataCommonKeyTitle;
    item.value = [NSString stringWithFormat:@"%ld second(s) of silence", (long)duration];
    [metadata addObject:item];
    
    AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
    [metadata addObject:descUID];
    
    exporter.metadata = [metadata copy];
    exporter.timeRange=CMTimeRangeFromTimeToTime(CMTimeMake(0,composition.duration.timescale), composition.duration);
    NSLog(@"composition.duration:%@", [NSValue valueWithCMTime:composition.duration]);
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"exp:%ld", (long)exporter.status);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"silentAudioFileCreated" object:@([exporter status])];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                composition = nil;
                exporter = nil;
            });
        });
    }];
    
    [self updateExportStatus];
    
    return;
}


-(void)updateExportStatus {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"silentAudioFileCreationStatus" object:@([exporter progress])];
    });
   
    if (exporter) {
        [self performSelector:@selector(updateExportStatus) withObject:nil afterDelay:0.25];
    }
}

-(NSDictionary *)audioDictForRemote {
    NSDictionary *dict = nil;
    
    NSArray *list = [self enumerateLocalAudioFiles];
    
    dict = [list dictionaryWithValuesForKeys:list];
    
    return @{ @"cmd" : @"libraryAudio", @"attr" : dict };
}



@end
