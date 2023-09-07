//
//  AddClipsViewController.m
//  Capture
//
//  Created by Gary Barnett on 9/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AddClipsViewController.h"

@implementation AddClipsViewController  {
    NSArray *videoList;
    NSArray *assetLibraryGroupList;
    
    NSMutableArray *selectedEntries;

    NSInteger lastTapRow;
    IBOutlet UICollectionView *collectionViewPack;
    
    UIBarButtonItem *helpButton;
     UIBarButtonItem *closeButton;
    
}

static NSString * const kCellReuseIdentifier = @"collectionViewCell";

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
        //NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    videoList = nil;
    assetLibraryGroupList = nil;
    selectedEntries = nil;
    collectionViewPack = nil;
    helpButton = nil;
    closeButton = nil;
    
}

-(void)reloadCollection {
    assetLibraryGroupList = [[AssetManager manager] groups];
    
    NSError * error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UtilityBag bag] docsPath] error:&error];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ( (!error) && directoryContents) {
        NSMutableDictionary *vMap = [[NSMutableDictionary alloc] initWithCapacity:[directoryContents count]];
        NSMutableDictionary *vSort = [[NSMutableDictionary alloc] initWithCapacity:[directoryContents count]];
        
        for (NSString *entry in directoryContents) {
            if ([[[entry pathExtension] lowercaseString] isEqualToString:@"mov"] || [[[entry pathExtension] lowercaseString] isEqualToString:@"mp4"]) {
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
        
        
        NSMutableArray *vList = [[NSMutableArray alloc] initWithCapacity:[sortedKeys count]];
        
        for (NSString *key in sortedKeys) {
            [vList addObject: @[key, [vMap objectForKey:key]] ];
        }
        videoList = [vList copy];
    } else {
        videoList = [NSArray array];
    }
    
    if (collectionViewPack) {
        [collectionViewPack reloadData];
    }
}


- (void)viewDidLoad
{
    
    self.navigationItem.title = @"Select Clips";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAddressNotification:) name:@"locationFound" object:nil];
    
    selectedEntries = [[NSMutableArray alloc] initWithCapacity:5];
    
    BOOL isiPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    [collectionViewPack registerNib:[UINib nibWithNibName: isiPad ? @"CollectionViewItemiPad" : @"CollectionViewItem" bundle:nil] forCellWithReuseIdentifier:kCellReuseIdentifier];
    collectionViewPack.backgroundColor = [UIColor blackColor];
    
    [collectionViewPack registerNib:[UINib nibWithNibName:@"GridCollectionHeaderViewItem" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [flowLayout setItemSize:CGSizeMake(160, 160)];
    } else {
        [flowLayout setItemSize:CGSizeMake(100, 100)];
    }
    
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [collectionViewPack setCollectionViewLayout:flowLayout];
    [collectionViewPack setAllowsSelection:YES];
    collectionViewPack.delegate=self;
    
    lastTapRow = -1;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishShowing:) name:@"finishPlaying" object:nil];
    
    collectionViewPack.allowsMultipleSelection = YES;
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose:)];
    
    self.navigationItem.rightBarButtonItems = @[ closeButton];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];
    
}
-(BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)userTappedCancel {
    [self performSelector:@selector(cleanup:) withObject:nil afterDelay:0.4];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[SyncManager manager] progressContainer].frame = CGRectMake(0,2,140,30);
    
    [self reloadCollection];

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numFound = 0;
    
    if (section == 0) {
        if (videoList) {
            numFound = [videoList count];
        }
    } else if (section <= [assetLibraryGroupList count]) {
        numFound = [[AssetManager manager] groupEntryCount:section];
    }
    
    return numFound;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1 + [assetLibraryGroupList count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    CGSize s = CGSizeMake(self.view.frame.size.width,20);
    
    return s;
}

-(NSArray *)metadataForItemWithName:(NSString *)fname {
    NSString *path = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:fname];
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    return [self metadataForAsset:asset];
}

-(NSArray *)metadataForAsset:(AVAsset *)asset {
    
    NSString *c = @"";
    NSString *l = @"";
    
    NSInteger duration = asset.duration.value / asset.duration.timescale;
    
    NSInteger hours = duration / (60 * 60);
    
    NSInteger remain = duration - (hours * 60 * 60);
    
    NSInteger minutes = remain / 60;
    
    NSInteger seconds = remain - (minutes * 60);
    
    NSString *d = @"";
    
    if (hours == 1) {
        d = @"1 hour";
    } else if (hours > 1) {
        d = [NSString stringWithFormat:@"%ld hours", (long)hours];
    }
    
    if ( (minutes > 0) && ([d length] >0)) {
        d = [d stringByAppendingString:@", "];
    }
    
    BOOL addSpace = NO;
    
    if (minutes == 1) {
        addSpace = YES;
        d = [d stringByAppendingString:@"1 minute"];
    } else if (minutes > 1) {
        addSpace = YES;
        d = [NSString stringWithFormat:@"%@%ld minutes", d, (long)minutes];
    }
    
    if (addSpace) {
        d = [d stringByAppendingString:@", "];
    }
    
    if (seconds == 1) {
        d = [d stringByAppendingString:@"1 second"];
    } else if (seconds > 1) {
        d = [NSString stringWithFormat:@"%@%ld seconds", d, (long)seconds];
    }
    
    for (NSString *format in [asset availableMetadataFormats]) {
        for (AVMutableMetadataItem *item in [asset metadataForFormat:format]) {
            if ([item.commonKey isEqualToString:@"creationDate"]) {
                c = (NSString *) item.value;
            } else if ([item.commonKey isEqualToString:@"location"]) {
                l = (NSString *) item.value;
            }
        }
    }
    
    if ([c length]>0) {
        c =  [[LocationHandler tool] timeAgoFromDateStr:c];
    }
    
    return @[ c, l, d ];
}

-(void)updateAddressNotification:(NSNotification *)n {
    NSArray *notifyArray = (NSArray *)n.object;
    
    UICollectionViewCell *cell = [notifyArray objectAtIndex:0];
    NSArray *metadata  = [notifyArray objectAtIndex:1];
    NSString *address = [notifyArray objectAtIndex:2];
    
    if ([metadata count] == 3) {
        NSString *timeStr =[metadata objectAtIndex:0];
        NSString *durationStr = [metadata objectAtIndex:2];
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
        NSString *newLabelText = [NSString stringWithFormat:@"%@\n%@\n%@", timeStr ? timeStr : @"", address ? address : @"", durationStr ? durationStr : @""];
        titleLabel.text = newLabelText;
        [titleLabel setNeedsDisplay];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    if (indexPath.section == 0) {
        titleLabel.text = @"App Library";
    } else {
        titleLabel.text = [assetLibraryGroupList objectAtIndex:indexPath.section -1];
    }
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:101];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    NSArray *metadata = nil;
    
    BOOL badClip = NO;
    
    AVAsset *avAsset = nil;
    UIImage *thumbnail = nil;
    
    if (indexPath.section > 0) {
        ALAsset *alasset = [[AssetManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
        
        if (!alasset) {
            titleLabel.text = @"bad clip";
            badClip = YES;
        } else {
            ALAssetRepresentation *representation = [alasset defaultRepresentation];
            NSURL *url = [representation url];
            
            NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            avAsset = [[AVURLAsset alloc] initWithURL:url options:asset_options];
            metadata = [self metadataForAsset:avAsset];
            thumbnail = [UIImage imageWithCGImage:[alasset aspectRatioThumbnail] scale:1.0 orientation:UIImageOrientationUp];
        }
    } else {
        metadata = [self metadataForItemWithName:[[videoList objectAtIndex:indexPath.row] objectAtIndex:0]];
    }
    
    if ((!badClip) && [metadata count] == 3) {
        NSString *location = [metadata objectAtIndex:1];
        NSString *timeStr =[metadata objectAtIndex:0];
        NSString *durationStr = [metadata objectAtIndex:2];
        
        NSString *titleStr =[NSString stringWithFormat:@"%@\n%@\n%@", timeStr, location, durationStr];
        titleLabel.text = titleStr;
        
        [[LocationHandler tool] reverseGeocodeAddressWithNotification:location notification:@[ cell, metadata]];
    } else {
        NSLog(@"metadata problem: %@", metadata);
        titleLabel.text = @"bad metadata";
        badClip = YES;
    }
    
    if (!badClip) {
        if (indexPath.section == 0) {
            NSString *clipFname = [[videoList objectAtIndex:indexPath.row] objectAtIndex:0];
            
            [cell setSelected:([selectedEntries indexOfObject:indexPath] != NSNotFound)];
            
            NSString *thumbStr = [[clipFname stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
            
            NSString *thumbPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"meta"] stringByAppendingPathComponent:thumbStr];
            
            thumbnail = [UIImage imageWithContentsOfFile:thumbPath];
            
        }
        
        imageView.image = thumbnail;
        
        imageView.layer.shadowColor = [UIColor blackColor].CGColor;
        [imageView.layer setShadowOpacity:0.8];
        [imageView.layer setShadowRadius:1.0];
        [imageView.layer setShadowOffset:CGSizeMake(1.0, 1.0)];
        
        UIImageView *bgImage = [[UIImageView alloc] initWithImage:nil];
        bgImage.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#a57342" withAlpha:1.0];
        cell.selectedBackgroundView = bgImage;
    }
    
    cell.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#e5b382" withAlpha:1.0];
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:cell.bounds];
    cell.layer.masksToBounds = NO;
    cell.layer.shadowColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
    cell.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    cell.layer.shadowOpacity = 0.3f;
    cell.layer.shadowRadius = 2.0f;
    cell.layer.shadowPath = shadowPath.CGPath;
    
    return cell;
}

#pragma mark - delegate methods

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    lastTapRow = -1;
    
    if ([selectedEntries indexOfObject:indexPath] != NSNotFound) {
        [selectedEntries removeObject:indexPath];
    }
    

}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger curRow = indexPath.row;
    
    lastTapRow = curRow;
    
    if ([selectedEntries indexOfObject:indexPath] == NSNotFound) {
        [selectedEntries addObject:indexPath];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)userTappedClose:(id)sender {
    if ([selectedEntries count] > 0) {
        NSMutableArray *assetList = [[NSMutableArray alloc] initWithCapacity:3];
        AVAsset *asset = nil;
        for (NSIndexPath *indexPath in selectedEntries) {
            if (indexPath.section == 0) {
                NSURL *assetURL = [NSURL fileURLWithPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:[[videoList objectAtIndex:indexPath.row] objectAtIndex:0]]];
                asset = [AVAsset assetWithURL:assetURL];
              
            } else {
                ALAsset *alasset = [[AssetManager manager] entryForGroupAtIndex:indexPath.section-1 atEntryIndex:indexPath.row];
                ALAssetRepresentation *representation = [alasset defaultRepresentation];
                NSURL *url = [representation url];
                AVAsset *avasset  = [AVURLAsset assetWithURL:url];
                if (![avasset isPlayable])  {
                    NSLog(@"Clip !playable %@", alasset);
                    continue;
                } else if (![avasset isComposable])  {
                    NSLog(@"Clip !composable %@", alasset);
                    continue;
                }
                NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
                asset = [[AVURLAsset alloc] initWithURL:url options:asset_options];
            }
            
            if (asset) {
                  [assetList addObject:asset];
            } else {
                NSLog(@"invalid asset for %@", indexPath);
            }
            
        }
        
        [self.delegate performSelectorOnMainThread:@selector(userSelectedCliplist:) withObject:[assetList copy] waitUntilDone:YES];
    }

    [self.navigationController popViewControllerAnimated:YES];
    [self performSelector:@selector(cleanup:) withObject:nil afterDelay:0.6];
}

@end