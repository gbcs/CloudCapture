//
//  ImportImageViewController.m
//  Capture
//
//  Created by Gary Barnett on 10/16/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ImportImageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ImportImageViewController () {
    NSMutableArray *assetLibraryGroupList;
    IBOutlet UICollectionView *collectionViewPack;
    ALAssetsLibrary *assetLibrary;
    UIDynamicAnimator *animator;
    UIView *detailView;
    ALAssetOrientation detailOrientation;
    ALAssetRepresentation *detailAssetRep;
    UIImageView *detailImageView;
}

@end

@implementation ImportImageViewController

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    while ([self.view.subviews count]>0) {
        UIView *v = [self.view.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }

    assetLibraryGroupList = nil;
    collectionViewPack = nil;
    assetLibrary = nil;
    animator = nil;
    detailView = nil;

    detailAssetRep = nil;
    detailImageView = nil;
}

static NSString * const kCellReuseIdentifier = @"importImageCollectionViewCell";


-(void)reloadCollection {
    assetLibraryGroupList = [[NSMutableArray alloc] initWithCapacity:10];
    assetLibrary = [[ALAssetsLibrary alloc] init];
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!group) {
            [collectionViewPack performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        } else {
            NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
            NSMutableDictionary *groupDict = [[NSMutableDictionary alloc] initWithCapacity:10];
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if(result && [[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                    NSInteger index = [groupDict count];
                    [groupDict setObject:result forKey:[NSNumber numberWithInteger:index]];
                } else if (!result) {
                    [assetLibraryGroupList addObject:@[ groupName, [groupDict copy] ] ];
                }
            }];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"failure reading asset groups:%@", error);
    }];
}



- (void)viewDidLoad
{
    self.navigationItem.title = @"Import Image";
    self.preferredContentSize= CGSizeMake(568,320);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanupImportImage" object:nil];
    
    [collectionViewPack registerNib:[UINib nibWithNibName:  @"ImportImageCollectionViewItem" bundle:nil] forCellWithReuseIdentifier:kCellReuseIdentifier];
    collectionViewPack.backgroundColor = [UIColor blackColor];
    
    [collectionViewPack registerNib:[UINib nibWithNibName:@"GridCollectionHeaderViewItem" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
    
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(100, 60)];

    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [collectionViewPack setCollectionViewLayout:flowLayout];
    [collectionViewPack setAllowsSelection:YES];
    collectionViewPack.delegate=self;
    
    collectionViewPack.allowsMultipleSelection = NO;
}



-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadCollection];
    
    
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height / 2.0f) - 50, self.view.frame.size.width, 100)];
        l.backgroundColor = [UIColor clearColor];
        l.textColor = [UIColor whiteColor];
        l.textAlignment = NSTextAlignmentCenter;
        l.lineBreakMode = NSLineBreakByWordWrapping;
        l.numberOfLines = 0;
        NSString *prod = @"CC Free";
#ifdef CCPRO
        prod = @"CloudCapt";
#endif
        l.text = [NSString stringWithFormat:@"Photo Album Access Denied\r\n\r\nCheck the Settings App, Privacy, Photos, %@", prod];
        [self.view addSubview:l];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *assetLibraryGroup = [[assetLibraryGroupList objectAtIndex:section] objectAtIndex:1];
    
    return [assetLibraryGroup count];

}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [assetLibraryGroupList count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    CGSize s = CGSizeMake(collectionView.bounds.size.width,20);
    
    return s;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    titleLabel.text = [[assetLibraryGroupList objectAtIndex:indexPath.section] objectAtIndex:0];
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
  
    NSDictionary *assetLibraryGroup = [[assetLibraryGroupList objectAtIndex:indexPath.section] objectAtIndex:1];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:101];
    
    ALAsset *alasset = [assetLibraryGroup objectForKey:[NSNumber numberWithInteger:indexPath.row]];
    imageView.image = [UIImage imageWithCGImage:[alasset aspectRatioThumbnail] scale:1.0 orientation:UIImageOrientationUp];

    return cell;
}

#pragma mark - delegate methods

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
  
}

-(void)closeDetailView {
    detailImageView = nil;
    detailAssetRep = nil;
    [detailView removeFromSuperview];
    detailView = nil;
    [animator removeAllBehaviors];
    animator = nil;
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (tag == 1) {
        detailOrientation++;
        if (detailOrientation > 3) {
            detailOrientation = 0;
        }
        [self updateDetailImage];
    } else if (tag == 0) {
        NSString *picName = [[UtilityBag bag] pathForNewResourceWithExtension:@"png"];
        
        NSString *picPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] stringByAppendingPathComponent:picName];
     
        if (self.saveForMovie) {
           picPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"] stringByAppendingPathComponent:picName]; 
        }

        
        //Make a 1920x1080 version of this image.
        
        //first crop to 16x9
        
        CGSize targetSize = CGSizeMake(1920,1080);
        
        UIImage *image = [[UtilityBag bag] imageByScalingAndCroppingForSize:targetSize usingImage:detailImageView.image rotated:NO mirror:NO];
        
        if (image.size.width != targetSize.width) {
            NSLog(@"Image failed to conform to x: %f != %f", image.size.width , targetSize.width);
        } else if (image.size.height != targetSize.height) {
             NSLog(@"Image failed to conform to y: %f != %f", image.size.height , targetSize.height);
        } else {
            NSData *d = UIImagePNGRepresentation(image);
            [d writeToFile:picPath atomically:NO];
        }
        
        if (self.popToRootWhenDone) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        NSString *notify = _notifyStr ? _notifyStr : @"updateEngineDetailList";
        
        [[NSNotificationCenter defaultCenter] postNotificationName:notify object:picName];
    } else if (tag == 2) {
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView ] ];
        [animator removeAllBehaviors];
        [animator addBehavior:gravity];
        [self performSelector:@selector(finishDetailAnimation) withObject:nil afterDelay:1.5];
    }
}

-(void)finishDetailAnimation {
    [animator removeAllBehaviors];
    detailImageView = nil;
    detailAssetRep = nil;
    [detailView removeFromSuperview];
    detailView = nil;
}

-(void)updateDetailImage {
    CGImageRef image = [detailAssetRep fullResolutionImage];
    detailImageView.image = [UIImage imageWithCGImage:image scale:1.0 orientation:(UIImageOrientation)detailOrientation];

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (animator) {
        [animator removeAllBehaviors];
    } else {
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }
    
    if (detailView) {
        [detailView removeFromSuperview];
        detailView = nil;
    }

    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 220, -225, 440, 225)];
    detailView.backgroundColor = [UIColor whiteColor];
    
    detailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5,12.5,350,200)];
    detailImageView.backgroundColor = [UIColor blackColor];
    detailImageView.contentMode = UIViewContentModeScaleAspectFill;
    detailImageView.clipsToBounds = YES;
    
    NSDictionary *assetLibraryGroup = [[assetLibraryGroupList objectAtIndex:indexPath.section] objectAtIndex:1];
    
    ALAsset *alasset = [assetLibraryGroup objectForKey:[NSNumber numberWithInteger:indexPath.row]];
    detailAssetRep = [alasset defaultRepresentation];
    detailOrientation = detailAssetRep.orientation;
    [self updateDetailImage];
  
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView]];
    CGFloat midY = (self.view.frame.size.height / 2.0f) + (detailView.frame.size.height / 2.0f  );
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, midY) toPoint:CGPointMake(self.view.bounds.size.width, midY)];
    
    [detailView addSubview:detailImageView];
    [self.view addSubview:detailView];
    
  
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(355, (225 * 0.25) - 22, 80, 44)];
    button.delegate = self;
    button.tag = 0;
    
    GradientAttributedButton *button3 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(355, (225 * 0.75) - 22, 80, 44)];
    button3.delegate = self;
    button3.tag = 2;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[[UtilityBag bag] standardFontBold] fontWithSize:15], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSString *bColor = @"#666666";
    NSString *eColor = @"#333333";
    
    
    NSAttributedString *buttonTitle =[[NSAttributedString alloc] initWithString:@"Accept" attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = YES;
    [button update];
    
    NSAttributedString *buttonTitle3 =[[NSAttributedString alloc] initWithString:@"Reject" attributes:strAttr];
    [button3 setTitle:buttonTitle3 disabledTitle:buttonTitle3 beginGradientColorString:bColor endGradientColor:eColor];
    button3.enabled = YES;
    [button3 update];

    
    [detailView addSubview:button];
    [detailView addSubview:button3];
    
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end