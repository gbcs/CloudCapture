//
//  StillReviewViewController.m
//  Capture
//
//  Created by Gary  Barnett on 4/6/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "StillReviewViewController.h"

@interface StillReviewViewController ()
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIView *detailView;
@end

@implementation StillReviewViewController {
    NSInteger currentIndex;
    BOOL addMode;
    NSString *addStr;
}

-(void)addSwipeRecognizerForDirection:(UISwipeGestureRecognizerDirection )d {
    UISwipeGestureRecognizer *swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(userSwiped:)];
    swipeG.direction = d;
    if (swipeG.direction == UISwipeGestureRecognizerDirectionUp) {
        swipeG.numberOfTouchesRequired = 2;
    }
    [_imageView addGestureRecognizer:swipeG];
    _imageView.userInteractionEnabled = YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([_imageView.gestureRecognizers count] == 0) {
        [self addSwipeRecognizerForDirection:UISwipeGestureRecognizerDirectionDown];
        [self addSwipeRecognizerForDirection:UISwipeGestureRecognizerDirectionUp];
        [self addSwipeRecognizerForDirection:UISwipeGestureRecognizerDirectionLeft];
        [self addSwipeRecognizerForDirection:UISwipeGestureRecognizerDirectionRight];
        UILongPressGestureRecognizer *longP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userPressed:)];
        longP.minimumPressDuration = 0.75f;
        [_imageView addGestureRecognizer:longP];
        self.navigationController.toolbarHidden = YES;
        self.navigationItem.title = @"Review Stills";
        self.automaticallyAdjustsScrollViewInsets = YES;
        self.navigationItem.leftItemsSupplementBackButton = YES;
        self.navigationItem.leftBarButtonItems = @[
                                                     [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelp)]
                                                     ];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[[SettingsTool settings] stillDefaultAlbum] style:UIBarButtonItemStylePlain target:self action:@selector(userTappedAlbum)];
        
    }
}

-(void)removeHelpView {
    UIView *helpView = [self.view viewWithTag:77];
    [_animator removeAllBehaviors];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ helpView ]];
    [_animator addBehavior:gravity];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_animator removeAllBehaviors];
            _animator = nil;
            UIView *hv = [self.view viewWithTag:77];
            [hv removeFromSuperview];
        });
    });
}

-(void)userTappedHelpScreen:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self removeHelpView];
    }
}

-(void)userTappedHelp {
    UIView *helpView = [self.view viewWithTag:77];
    if (helpView) {
        return;
    }

    
    CGFloat midX = self.view.frame.size.width / 2.0f;
    CGFloat bottomY = 300;
    CGFloat height = 250;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        height = 500;
        bottomY = (self.view.frame.size.height / 2.0f) + (height / 2.0f);
    }

    helpView = [[UIView alloc] initWithFrame:CGRectMake(midX - 220, -(height), 440, height)];
    helpView.tag = 77;
    helpView.backgroundColor = [UIColor darkGrayColor];
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedHelpScreen:)];
    [helpView addGestureRecognizer:tapG];

    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,440,50)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Help - Review Stills";
    l.textColor = [UIColor whiteColor];
    [helpView addSubview:l];
    
    l = [[UILabel alloc] initWithFrame:CGRectMake(0,50,440,height - 50)];
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor whiteColor];
    l.textColor = [UIColor blackColor];
    l.numberOfLines = 0;
    l.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 10;
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableParagraphStyle *pLeft = [[NSMutableParagraphStyle alloc] init];
    pLeft.alignment = NSTextAlignmentLeft;
    
    NSMutableParagraphStyle *pRight = [[NSMutableParagraphStyle alloc] init];
    pRight.alignment = NSTextAlignmentRight;
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:@"Swipe Down - Save Photo To Album\nSwipe Up (2 fingers) - Delete Photo\nSwipe Left - Previous Photo\nSwipe Right - Next Photo\nPress and Hold - Edit Photo\nTop Right - Select Photo Album" attributes:@{ NSParagraphStyleAttributeName : paragraph }];

   
    
    
    l.attributedText = [attStr copy];
    [helpView addSubview:l];
    
    [self.view addSubview:helpView];
    
    if (_animator) {
        [_animator removeAllBehaviors];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ _detailView, helpView]];
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ helpView]];
        [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,bottomY) toPoint:CGPointMake(self.view.frame.size.width, bottomY)];
        [_animator addBehavior:gravity];
        [_animator addBehavior:collision];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:1.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_detailView removeFromSuperview];
                _detailView = nil;
            });
        });
    } else {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ helpView]];
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ helpView]];
        [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,bottomY) toPoint:CGPointMake(self.view.frame.size.width, bottomY)];
        [_animator addBehavior:collision];
        [_animator addBehavior:gravity];
    }
}

-(void)removeDetailView {
    [_animator removeAllBehaviors];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ _detailView]];
    [_animator addBehavior:gravity];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_animator removeAllBehaviors];
            _animator = nil;
            [_detailView removeFromSuperview];
            _detailView = nil;
        });
    });
}


-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    if (tag == 65) {
        addMode = NO;
        [self removeDetailView];
        return;
    } else if (tag == 66) {
        if (addMode) {
            //Save
            if (addStr && ([addStr length]>0)) {
                [[PhotoManager manager] addPhotoAlbumWithName:addStr];
                addMode = NO;
                [self removeDetailView];
                [self performSelector:@selector(userTappedAlbum) withObject:nil afterDelay:2.05];
            } else {
                return;
            }

            return;
        }
        
        addMode = YES;
        
        GradientAttributedButton *button = (GradientAttributedButton *)[_detailView viewWithTag:66];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[[UtilityBag bag] standardFontBold] fontWithSize:15], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSAttributedString *buttonTitle =[[NSAttributedString alloc] initWithString:@"Save" attributes:strAttr];
        [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        
        
        UITableView *tv = (UITableView *)[_detailView viewWithTag:55];
        [tv reloadData];

    }
}

-(void)userTappedAlbum {
    if (_animator) {
        if (_detailView) {
            return;
        }
    }
    
    self.navigationItem.rightBarButtonItem.title = [[SettingsTool settings] stillDefaultAlbum];
    
    CGFloat midX = self.view.frame.size.width / 2.0f;
    CGFloat bottomY = 300;
    CGFloat height = 250;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        height = 500;
        bottomY = (self.view.frame.size.height / 2.0f) + (height / 2.0f);
    }
    _detailView = [[UIView alloc] initWithFrame:CGRectMake(midX - 220, -(height), 440, height)];
    _detailView.backgroundColor = [UIColor darkGrayColor];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,440,50)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Select Destination Photo Album";
    l.textColor = [UIColor whiteColor];
    [_detailView addSubview:l];
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(360, 3, 80, 44)];
    button.delegate = self;
    button.tag = 66;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[[UtilityBag bag] standardFontBold] fontWithSize:15], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSString *bColor = @"#666666";
    NSString *eColor = @"#333333";
    
    NSAttributedString *buttonTitle =[[NSAttributedString alloc] initWithString:@"Add" attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = YES;
    [button update];
    [_detailView addSubview:button];
    
    GradientAttributedButton *button2 = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(10, 3, 80, 44)];
    button2.delegate = self;
    button2.tag = 65;
    
    
    NSAttributedString *buttonTitle2 =[[NSAttributedString alloc] initWithString:@"Cancel" attributes:strAttr];
    [button2 setTitle:buttonTitle2 disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
    button2.enabled = YES;
    [button2 update];
    [_detailView addSubview:button2];

    
    
    
    UITableView *tv = [[UITableView alloc] initWithFrame:CGRectMake(0,50,440,height - 55) style:UITableViewStylePlain];
    tv.tag = 55;
    tv.delegate = self;
    tv.dataSource = self;
    tv.tintColor = [UIColor blackColor];
    [_detailView addSubview:tv];
    
    if (_animator) {
        [_animator removeAllBehaviors];
    } else {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }
    
    [self.view addSubview:_detailView];
    
    NSArray *gravityList = @[ _detailView ];
    UIView *helpView = [self.view viewWithTag:77];
    if (helpView) {
        gravityList = [gravityList arrayByAddingObject:helpView];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:1.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView *hv = [self.view viewWithTag:77];
                [hv removeFromSuperview];
            });
        });
    }
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:gravityList];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ _detailView]];
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,bottomY) toPoint:CGPointMake(self.view.frame.size.width, bottomY)];
    [_animator addBehavior:collision];
    [_animator addBehavior:gravity];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated {
    [[PhotoManager manager] update];
    [super viewWillDisappear:animated];
}

-(void)userSwiped:(UISwipeGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        switch (g.direction) {
            case UISwipeGestureRecognizerDirectionRight:
            {
                //Prev
                if (currentIndex > 0) {
                    currentIndex--;
                    [self displayImageAnimated:YES fromLeft:YES];
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
                break;
            case UISwipeGestureRecognizerDirectionLeft:
            {
                //Next
                if (currentIndex +1 < [[PhotoManager manager] unreviewedStillGroupEntryCount:_reviewGroupIndex]) {
                    currentIndex++;
                    [self displayImageAnimated:YES fromLeft:NO];
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
                break;
            case UISwipeGestureRecognizerDirectionUp:
            {
                //Delete
                NSString *fpath = [[self basePath] stringByAppendingPathComponent:[self nameForIndex:currentIndex]];
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:fpath error:&error];
                BOOL shouldPop = YES;
                if (currentIndex +1 < [[PhotoManager manager] unreviewedStillGroupEntryCount:_reviewGroupIndex]) {
                    currentIndex++;
                    [self displayImageAnimated:YES fromLeft:NO];
                    shouldPop = NO;
                }
                
                [self addStatusMessage:[NSString stringWithFormat:@"Deleted"]];
            
                if (shouldPop) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
                break;
            case UISwipeGestureRecognizerDirectionDown:
            {
                //Save
                NSString *fpath = [[self basePath] stringByAppendingPathComponent:[self nameForIndex:currentIndex]];
                
                NSInteger destAlbum = 0;
                NSArray *masterList = [[PhotoManager manager] masterGroupAssetList];
                for (NSInteger idx=0;idx<[masterList count];idx++) {
                    ALAssetsGroup *group = [masterList objectAtIndex:idx];
                    NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
                    if ([name isEqualToString:[[SettingsTool settings] stillDefaultAlbum]]) {
                        destAlbum = idx;
                        break;
                    }
                }
          
                [[PhotoManager manager] moveDataAtPathToCameraRoll:fpath andMasterGroupIndex:destAlbum];
               
                BOOL shouldPop = YES;
                if (currentIndex +1 < [[PhotoManager manager] unreviewedStillGroupEntryCount:_reviewGroupIndex]) {
                    currentIndex++;
                    [self displayImageAnimated:YES fromLeft:NO];
                    shouldPop = NO;
                }
                
                [self addStatusMessage:[NSString stringWithFormat:@"Saved"]];
                
                if (shouldPop) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [NSThread sleepForTimeInterval:1.0f];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                    });
                }
            }
                break;
        }
    }
}

-(void)addStatusMessage:(NSString *)msg {
    UILabel *v = [[UILabel alloc] initWithFrame:CGRectMake(0,0,200,60)];
    v.numberOfLines = 0;
    v.textAlignment = NSTextAlignmentCenter;
    v.lineBreakMode = NSLineBreakByWordWrapping;
    v.text = msg;
    v.backgroundColor = [UIColor whiteColor];
    v.layer.cornerRadius = 4;
    v.layer.masksToBounds = YES;
    [self.view addSubview:v];
    v.center = CGPointMake(self.view.center.x, self.view.center.y - 80);
    
    [v performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5f];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}


-(void)userPressed:(UILongPressGestureRecognizer *)g {
    NSLog(@"Edit");
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self displayImageAnimated:NO fromLeft:NO];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self userTappedHelp];
}

-(NSString *)basePath {
     return [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"unreviewedStills"];
}

-(NSString *)nameForIndex:(NSInteger )index {
    return [[PhotoManager manager] nameForUnreviewedStillGroupAtIndex:_reviewGroupIndex atEntryIndex:index];
}


-(void)displayImageAnimated:(BOOL)animated fromLeft:(BOOL)fromLeft {
    UIImage *i = [UIImage imageWithContentsOfFile:[[self basePath] stringByAppendingPathComponent:[self nameForIndex:currentIndex]]];
    UIImage *image = [UIImage imageWithCGImage:i.CGImage scale:1.0 orientation:UIImageOrientationUp];
    if (!image) {
        if (fromLeft) {
            currentIndex--;
            if (currentIndex <0) {
                [self.navigationController popViewControllerAnimated:YES];
                return;
            }
        } else {
            currentIndex++;
            if (currentIndex >= [[PhotoManager manager] unreviewedStillGroupEntryCount:_reviewGroupIndex]) {
                [self.navigationController popViewControllerAnimated:YES];
                return;
            }
        }
        
        [self displayImageAnimated:animated fromLeft:fromLeft];
        return;
    }
    
    if (animated) {
        CGFloat animDuration = 0.3f;
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(fromLeft ? -_imageView.frame.size.width : _imageView.frame.size.width,
                                                                        _imageView.frame.origin.y,
                                                                        _imageView.frame.size.width,
                                                                        _imageView.frame.size.height)];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.image = image;
        [self.view addSubview:iv];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:animDuration animations:^{
                iv.frame = _imageView.frame;
                _imageView.frame = CGRectMake(fromLeft ? _imageView.frame.size.width : -_imageView.frame.size.width,
                                              _imageView.frame.origin.y,
                                              _imageView.frame.size.width,
                                              _imageView.frame.size.height);
            }];
        });
       
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:animDuration];
            dispatch_async(dispatch_get_main_queue(), ^{
                _imageView.image = image;
                [iv removeFromSuperview];
                _imageView.frame = CGRectMake(0, _imageView.frame.origin.y, _imageView.frame.size.width, _imageView.frame.size.height);
            });
        });
    } else {
        _imageView.image = image;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (addMode) {
        return 60.0f;
    }
    return 0.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[PhotoManager manager] masterGroupAssetList] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    ALAssetsGroup *group = [[[PhotoManager manager] masterGroupAssetList] objectAtIndex:indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    
    cell.textLabel.enabled = [group isEditable] || [cell.textLabel.text isEqualToString:@"Camera Roll"];
    
    if ([cell.textLabel.text isEqualToString:[[SettingsTool settings] stillDefaultAlbum]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
                                             
                                             
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ALAssetsGroup *group = [[[PhotoManager manager] masterGroupAssetList] objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [[SettingsTool settings] setStillDefaultAlbum:[group valueForProperty:ALAssetsGroupPropertyName]];
    [tableView reloadData];
    self.navigationItem.rightBarButtonItem.title = [[SettingsTool settings] stillDefaultAlbum];
    
    [self removeDetailView];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    addStr = [textField.text stringByReplacingCharactersInRange:range withString:string];

    return YES;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, 60)];
    v.backgroundColor = [UIColor blackColor];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, 20)];
    l.text = @"Enter name for new photo album:";
    l.textColor = [UIColor whiteColor];
    l.backgroundColor = [UIColor blackColor];
    [v addSubview:l];
    
    UITextField *t = [[UITextField alloc] initWithFrame:CGRectMake(0,20,self.view.frame.size.width - 100, 40)];
    t.delegate = self;
    t.backgroundColor = [UIColor whiteColor];
    t.textColor = [UIColor blackColor];
    [v addSubview:t];
    
    [t performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
   
    return v;
}

@end
