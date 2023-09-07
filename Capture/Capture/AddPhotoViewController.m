//
//  AddPhotoViewController.m
//  Capture
//
//  Created by Gary Barnett on 2/4/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AddPhotoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AddPhotoViewController () {
    NSMutableArray *assetLibraryGroupList;
    IBOutlet UICollectionView *collectionViewPack;
    ALAssetsLibrary *assetLibrary;
    UIDynamicAnimator *animator;
    UIView *detailView;
    UIImageOrientation detailOrientation;
    ALAssetRepresentation *detailAssetRep;
    UIImageView *detailImageView;
}

@end

@implementation AddPhotoViewController


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
    self.navigationController.toolbarHidden = YES;
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
   if (tag == 0) {
        NSString *picName = [[UtilityBag bag] pathForNewResourceWithExtension:@"png"];
        
        NSString *picPath = @"";
        picPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"] stringByAppendingPathComponent:picName];
   
       CGImageRef image = [detailAssetRep fullResolutionImage];
       UIImage *i = [UIImage imageWithCGImage:image scale:1.0 orientation:detailOrientation];
        
        NSData *d = UIImageJPEGRepresentation(i, 1.0);
                                             

        [d writeToFile:picPath atomically:NO];
    
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
    detailImageView.image = [UIImage imageWithCGImage:image scale:1.0 orientation:detailOrientation];
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
    
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 185, -225, 370, 270)];
    detailView.backgroundColor = [UIColor whiteColor];
    
    detailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5,5,260,260)];
    detailImageView.backgroundColor = [UIColor clearColor];
    detailImageView.contentMode = UIViewContentModeScaleAspectFit;
    detailImageView.clipsToBounds = YES;
    
    NSDictionary *assetLibraryGroup = [[assetLibraryGroupList objectAtIndex:indexPath.section] objectAtIndex:1];
    
    ALAsset *alasset = [assetLibraryGroup objectForKey:[NSNumber numberWithInteger:indexPath.row]];
    detailAssetRep = [alasset defaultRepresentation];
    
        //NSLog(@"detailAssetRep.metadata:%@", detailAssetRep.metadata);
    
    detailOrientation = UIImageOrientationUp;
    
    if ([alasset valueForProperty:@"ALAssetPropertyOrientation"]) {
        if (detailAssetRep.metadata && [detailAssetRep.metadata objectForKey:@"Orientation"]) {
            NSInteger o = [[detailAssetRep.metadata objectForKey:@"Orientation"] integerValue];
            switch (o) {
                case 6:
                    detailOrientation = UIImageOrientationRight;
                    break;
            }
        }
    }
    
    [self updateDetailImage];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView]];
    CGFloat midY = (self.view.frame.size.height / 2.0f) + (detailView.frame.size.height / 2.0f) + 25;
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0, midY) toPoint:CGPointMake(self.view.bounds.size.width, midY)];
    
    [detailView addSubview:detailImageView];
    [self.view addSubview:detailView];
    
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(280, (270 * 0.25) - 22, 80, 44)];
    button.delegate = self;
    button.tag = 0;
    
    GradientAttributedButton *button3 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(280, (270 * 0.75) - 22, 80, 44)];
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