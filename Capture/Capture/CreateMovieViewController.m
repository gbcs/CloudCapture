//
//  CreateMovieViewController.m
//  Capture
//
//  Created by Gary Barnett on 9/10/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CreateMovieViewController.h"
#import "HelpViewController.h"
#import "FixedTimelineVideoView.h"
#import "FixedTimelineAudioView.h"

@interface CreateMovieViewController () {
    
    NSDictionary *filterNameDict;
    __weak IBOutlet UIBarButtonItem *addAudioButton;
    __weak IBOutlet UIBarButtonItem *addVideoButton;
    __weak IBOutlet UIBarButtonItem *transitionButton;
    __weak IBOutlet CutScrubberBar *timelineBar;
    __weak IBOutlet UIScrollView *videoScroller;
    __weak IBOutlet UIToolbar *toolBar;
    
    UIBarButtonItem *helpButton;
    UIBarButtonItem *confirmButton;
    UIBarButtonItem *backButton;
    
    UIToolbar *transitionToolbar;
    
    BOOL firstPresentation;
    
    CGSize thumbSize;
    float centeringOffset;
    
    NSMutableArray *clips;
    NSMutableDictionary *clipTransitionInstructions;
    NSMutableArray *clipDurations;
    
    NSMutableArray *audioTracks;
    
    NSMutableArray *addedClips;

    NSInteger clipCurrentlyPointedAt;
    UIDynamicAnimator *animator;
    UIView *detailView;
    
    BOOL currentTransitionSelectionIsBegin;
}

@end

@implementation CreateMovieViewController

-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
    //NSLog(@"%s", __func__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    
    transitionButton = nil;
    timelineBar = nil;
    videoScroller = nil;
    toolBar = nil;
    helpButton = nil;
    confirmButton = nil;
    clips = nil;
    clipTransitionInstructions = nil;
    backButton = nil;
    transitionToolbar = nil;
    clipDurations = nil;

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        thumbSize = CGSizeMake(60,34);
        NSMutableParagraphStyle* p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
        filterNameDict = @{
                           NSFontAttributeName : [UIFont systemFontOfSize:10.0f],
                           NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"],
                           NSParagraphStyleAttributeName: p
                           };
        
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [timelineBar setDelegate:nil];
    
    centeringOffset = (videoScroller.bounds.size.width / 2.0f);
}

-(void)addClips {
    for (AVAsset *asset in addedClips) {
        if ([clips count] >= 16) {
            break;
        }
        
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] > 0) {
            [clips addObject:asset];
            [clipDurations addObject:[NSValue valueWithCMTime:asset.duration]];
        }
    }
    
    addedClips = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:0.1f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateTimeline];
            CGRect r = videoScroller.bounds;
            [videoScroller scrollRectToVisible:CGRectMake(videoScroller.contentSize.width - r.size.width, 0, r.size.width, r.size.height) animated:NO];
        });
    });
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!firstPresentation) {
        firstPresentation = YES;
        [self performSelector:@selector(showAddClips) withObject:nil afterDelay:0.10];
    } else if (addedClips) {
        [self performSelector:@selector(addClips) withObject:nil afterDelay:0.25f];
    } else {
        [self updateTimeline];
    }
    
}


-(NSInteger)totalSeconds {
    CMTime duration = kCMTimeZero;
    for (NSValue *t in clipDurations) {
        duration = CMTimeAdd(duration, [t CMTimeValue]);
    }
    
    NSInteger seconds = CMTimeGetSeconds(duration);
    if (seconds < 1) {
        seconds = 0;
    } else {
        CMTime remainder = CMTimeSubtract(duration, CMTimeMake(seconds, 1));
        if (CMTimeCompare(remainder, CMTimeMake(seconds, 1)) == NSOrderedDescending) {
            seconds++;
        }
    }
    
    return seconds;
}

-(CGFloat)xForScrollerCell:(NSInteger)index {
    return centeringOffset + (index * ((thumbSize.width * 2) + 0));
}

-(void)updateTimeline {
    NSLog(@"updating timeline");
    NSInteger seconds = [self totalSeconds];
    
    [timelineBar setDuration:seconds];
    videoScroller.delegate = self;
    
    NSArray *viewList = [videoScroller.subviews copy];
    for (UIView *v in viewList) {
        if (v.tag > -10000) { //remove photo/video blocks
            [v removeFromSuperview];
        } else if (v.tag == -10000) { //Position labels
            CGRect r = v.frame;
            v.frame = CGRectMake(centeringOffset - 200, r.origin.y, r.size.width, r.size.height);
            UILabel *l = (UILabel *)v;
            if ([l.text isEqualToString:@"Audio"]) {
                v.hidden = audioTracks && ([audioTracks count]>0) ? NO : YES;
            } else {
                v.hidden = NO;
            }
        }
    }
    
    for (NSInteger x=0;x<[clips count];x++) {
        AVAsset *clip = clips[x];
        
        FixedTimelineVideoView *v = [[FixedTimelineVideoView alloc] initWithFrame:CGRectMake([self xForScrollerCell:x], 0, thumbSize.width*2, thumbSize.height + 20)];
        v.index = x;
        [videoScroller addSubview:v];
        [v updateWithAsset:clip andPhotoDuration:CMTimeGetSeconds([[clipDurations objectAtIndex:x] CMTimeValue])];
    }
    
    for (NSInteger x=0;x<[audioTracks count];x++) {
        NSArray *clip = audioTracks[x];
        
        FixedTimelineAudioView *v = [[FixedTimelineAudioView alloc] initWithFrame:CGRectMake([self xForScrollerCell:x], thumbSize.height + 30, thumbSize.width*2, (thumbSize.height) + 110)];
        v.index = x;
        [videoScroller addSubview:v];
        [v updateWithArray:clip];
    }

    
    NSInteger trackCount = [clips count];
    if ([audioTracks count] > trackCount) {
        trackCount = [audioTracks count];
    }
    
    if ([clips count]>0) {
        [videoScroller setContentSize:CGSizeMake([self xForScrollerCell:trackCount] + centeringOffset, videoScroller.frame.size.height)];
    }
    
    [self placeTransitions];
    [self updateToolbar];
}


-(void)placeTransitions {
    CMTime duration = kCMTimeZero;
    NSInteger index = 0;
    for (AVAsset *clip in clips) {
        duration = CMTimeAdd(duration, clip.duration);
        CGRect r = CGRectMake([self xForScrollerCell:index+1] - 20, 15, 40, 26);
        NSNumber *storedTransition = [[clipTransitionInstructions objectForKey:[NSNumber numberWithInteger:index]] objectForKey:@"transition"];
        NSInteger newTransition = storedTransition ? [storedTransition integerValue] : 0;
        TransitionBlock *transitionBlock = [[TransitionBlock alloc] initWithFrame:r];
        transitionBlock.type = newTransition;
        [videoScroller addSubview:transitionBlock];
        transitionBlock.tag = (-200) - (index);
        index++;
    }
}

-(NSArray *)clipNominalFrameRates {
    NSMutableArray *durations = [[NSMutableArray alloc] initWithCapacity:3];
    
    for (AVAsset *clip in clips) {
        NSArray *trackArray = [clip tracksWithMediaType:AVMediaTypeVideo];
        if ([trackArray count]>0) {
            AVAssetTrack *track = [[clip tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [durations addObject:[NSNumber numberWithInteger:track.nominalFrameRate]];
        } else {
            [durations addObject:@(1)];
        }
    }
    
    return [durations copy];
}

-(void)userDidBeginScrubberPress {
    videoScroller.hidden = YES;
}

-(void)reEnableCutScrubberBar {
    timelineBar.userInteractionEnabled = YES;
}

-(void)userPressedScrubberAtSecond:(NSInteger)sec {
    timelineBar.userInteractionEnabled = NO;
    
    float p = (float)[self totalSeconds] / (float)sec;
    
    float origin = videoScroller.contentSize.width / p;
    
    origin -= videoScroller.frame.size.width / 2.0f;
    
    if (origin < 0) {
        origin = 0;
    }
    
    CGRect r = CGRectMake(origin, 0, videoScroller.frame.size.width, thumbSize.height + 14);
    
    [videoScroller scrollRectToVisible:r animated:NO];
    
    [self scrollViewDidScroll:videoScroller];
}

-(void)userDidEndScrubberPress {
    videoScroller.hidden = NO;
    [self reEnableCutScrubberBar];
}

-(void)updateToolbar {
    BOOL enabled = ([clips count]>0);
    
    transitionButton.enabled = enabled;
    confirmButton.enabled = enabled;
    backButton.enabled = YES;
    addVideoButton.enabled = YES;
    addAudioButton.enabled = YES;
    
}

-(void)userTappedAudioResourceAtIndex:(NSNotification *)n {
    if (detailView) {
        return;
    }
    
    NSNumber *idx = (NSNumber *)n.object;

    NSArray *array = [audioTracks objectAtIndex:[idx integerValue]];
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200, -270, 400, 220)];
    detailView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    detailView.tag = [idx integerValue];
    [self.view addSubview:detailView];
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    
    CGFloat y = self.view.frame.size.height - 50;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = 340;
    }
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView] ];
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0,15,400,25)];
    t.textColor = [UIColor whiteColor];
    t.backgroundColor = [UIColor clearColor];
    t.font = [UIFont boldSystemFontOfSize:17];
    t.textAlignment = NSTextAlignmentCenter;
    t.text = @"Video Clip Volume";
    t.tag = 10;
    [detailView addSubview:t];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0,40,400,50)];
    slider.minimumValue = 0.0f;
    slider.maximumValue = 1.0f;
    slider.tag = 11;
    slider.value = [[array objectAtIndex:1] floatValue];
    [slider addTarget:self action:@selector(userChangedAudioSourceSlider:) forControlEvents:UIControlEventValueChanged];
    [detailView  addSubview:slider];
    
    
    UILabel *t2 = [[UILabel alloc] initWithFrame:CGRectMake(0,100,400,25)];
    t2.textColor = [UIColor whiteColor];
    t2.backgroundColor = [UIColor clearColor];
    t2.font = [UIFont boldSystemFontOfSize:17];
    t2.textAlignment = NSTextAlignmentCenter;
    t2.text = @"Audio Clip Volume";
    t2.tag = 12;
    [detailView addSubview:t2];
    
    UISlider *slider2 = [[UISlider alloc] initWithFrame:CGRectMake(0,125,400,50)];
    slider2.minimumValue = 0.01f;
    slider2.maximumValue = 1.0f;
    slider2.tag = 13;
    slider2.value = [[array objectAtIndex:2] floatValue];
    [slider2 addTarget:self action:@selector(userChangedAudioClipSlider:) forControlEvents:UIControlEventValueChanged];
    [detailView  addSubview:slider2];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,170,400,50)];
    v.backgroundColor = [UIColor blackColor];
    [detailView addSubview:v];
    
    UIButton *button2 = [[UIButton alloc] initWithFrame:CGRectMake(5,170,70,40)];
    [button2 setTitle:@"Replace" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(userWantsAudioReplace) forControlEvents:UIControlEventTouchUpInside];
    button2.tag = 14;
    [detailView addSubview:button2];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(165,170,70,40)];
    [button setTitle:@"Done" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(userFinishedAdjustingAudio) forControlEvents:UIControlEventTouchUpInside];
    button.tag = 14;
    [detailView addSubview:button];
 
    UIButton *button3 = [[UIButton alloc] initWithFrame:CGRectMake(325,170,70,40)];
    [button3 setTitle:@"Mix" forState:UIControlStateNormal];
    [button3 addTarget:self action:@selector(userWantsAudioMix) forControlEvents:UIControlEventTouchUpInside];
    button3.tag = 14;
    [detailView addSubview:button3];
    
    addVideoButton.enabled = NO;
    addAudioButton.enabled = NO;
    transitionButton.enabled = NO;
    confirmButton.enabled = NO;
}

-(void)userFinishedAdjustingAudio {
    [animator removeAllBehaviors];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [animator addBehavior:gravity];
    [self performSelector:@selector(updateTimeline) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(removePhotoTimeEditor) withObject:nil afterDelay:1.0];
}

-(void)userWantsAudioReplace {
    
    UISlider *s = (UISlider *)[detailView viewWithTag:11];
    UISlider *r = (UISlider *)[detailView viewWithTag:13];
    
    NSMutableArray *array = [[audioTracks objectAtIndex:detailView.tag] mutableCopy];
    [array replaceObjectAtIndex:1 withObject:@(0.0f)];
    [array replaceObjectAtIndex:1 withObject:@(1.0f)];
    
    [audioTracks replaceObjectAtIndex:detailView.tag withObject:[array copy]];
 
    s.value = 0.0f;
    r.value = 1.0f;
}

-(void)userWantsAudioMix {
    
    UISlider *s = (UISlider *)[detailView viewWithTag:11];
    UISlider *r = (UISlider *)[detailView viewWithTag:13];
    
    NSMutableArray *array = [[audioTracks objectAtIndex:detailView.tag] mutableCopy];
    [array replaceObjectAtIndex:1 withObject:@(1.0f)];
    [array replaceObjectAtIndex:1 withObject:@(1.0f)];
    
    [audioTracks replaceObjectAtIndex:detailView.tag withObject:[array copy]];
    
    s.value = 1.0f;
    r.value = 1.0f;
}

-(void)userChangedAudioSourceSlider:(id)sender {
    
    UISlider *s = (UISlider *)sender;
    
    NSMutableArray *array = [[audioTracks objectAtIndex:detailView.tag] mutableCopy];
    [array replaceObjectAtIndex:1 withObject:@(s.value)];
    
    [audioTracks replaceObjectAtIndex:detailView.tag withObject:[array copy]];

}

-(void)userChangedAudioClipSlider:(id)sender {
    UISlider *s = (UISlider *)sender;
    
    NSMutableArray *array = [[audioTracks objectAtIndex:detailView.tag] mutableCopy];
    [array replaceObjectAtIndex:2 withObject:@(s.value)];
    
    [audioTracks replaceObjectAtIndex:detailView.tag withObject:[array copy]];

}


-(void)userSelectedAudiolist:(NSArray *)list {
    for (AVAsset *asset in list) {
        NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        if ([tracks count] > 0) {
            if ([audioTracks count] >= 16) {
                break;
            }
            [audioTracks addObject:@[ asset, @(0.0f), @(1.0f)] ];
        }
    }
    
    addedClips = nil;
    
    [self performSelector:@selector(updateTimeline) withObject:nil afterDelay:0.2];
}


-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#000000"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    NSInteger idx = tag - 5000;
    BOOL oldTransitionIsBegin = currentTransitionSelectionIsBegin;
    currentTransitionSelectionIsBegin = (idx == 0);
    
    NSString *bSel = @"";
    NSString *eSel = @"";
    
    NSString *bUns = @"#666666";
    NSString *eUns = @"#333333";
   
    UIImageView *iv = (UIImageView *)[detailView viewWithTag:499];
    
    SPUserResizableView *boundsRect = (SPUserResizableView *)[iv viewWithTag:123];
    CGRect r = boundsRect.frame;
    [boundsRect removeFromSuperview];
    
    

    for (NSInteger x = 0;x<4;x++) {
        GradientAttributedButton *button = (GradientAttributedButton *)[detailView viewWithTag:x + 5000];
        NSString *caption = @"";
        switch (x) {
            case 0:
            {
                caption = @"Begin";
                bSel = @"#009900";
                eSel = @"#006600";
            }
                break;
            case 1:
            {
                caption = @"End";
                bSel = @"#000099";
                eSel = @"#000066";
            }
                break;
        }
        
        NSAttributedString *t = [[NSAttributedString alloc] initWithString:caption attributes:@{
                                                                                                NSFontAttributeName : [[[UtilityBag bag] standardFontBold] fontWithSize:14],
                                                                                                NSShadowAttributeName : shadow,
                                                                                                NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#CCCCCC"]
                                                                                                }];
        
        [button setTitle:t disabledTitle:t beginGradientColorString:(idx == x) ? bSel : bUns endGradientColor:(idx == x) ? eSel : eUns];
        [button update];
    }
    
    
    if (!oldTransitionIsBegin) {
        [[SettingsTool settings] setDefaultMoviePhotoTransitionEndRect:r];
       
    } else {
        [[SettingsTool settings] setDefaultMoviePhotoTransitionStartRect:r];
    }
    
    if (currentTransitionSelectionIsBegin) {
        boundsRect = [[SPUserResizableView alloc] initWithFrame:[[SettingsTool settings] defaultMoviePhotoTransitionStartRect]];
    } else {
        boundsRect = [[SPUserResizableView alloc] initWithFrame:[[SettingsTool settings] defaultMoviePhotoTransitionEndRect]];
    }
    [boundsRect setMinHeight:48];
    [boundsRect setMinWidth:48 * (16.0/9.0)];
    boundsRect.tag = 123;
    boundsRect.userInteractionEnabled = YES;
    boundsRect.delegate = self;
    [boundsRect showEditingHandles];
    boundsRect.enforce16x19AspectRatio = YES;
    boundsRect.layer.borderColor = currentTransitionSelectionIsBegin ? [UIColor greenColor].CGColor : [UIColor blueColor].CGColor;
    boundsRect.layer.borderWidth = 1.0f;
    
    UIView *v = [[UIView alloc] initWithFrame:boundsRect.bounds];
    v.backgroundColor = [UIColor colorWithRed:0.0 green:currentTransitionSelectionIsBegin ? 1.0 : 0.0 blue:currentTransitionSelectionIsBegin ? 0.0 : 1.0 alpha:0.4];
    v.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [boundsRect setContentView:v];
    
    [iv addSubview:boundsRect];
    
}

-(void)userSelectedCliplist:(NSArray *)list {
    addedClips = [list mutableCopy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    clips = [[NSMutableArray alloc] initWithCapacity:3];
    audioTracks = [[NSMutableArray alloc] initWithCapacity:3];
    clipDurations = [[NSMutableArray alloc] initWithCapacity:3];
    clipTransitionInstructions = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    self.navigationItem.title = @"Create Movie";
   
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makePhotoVideoProgress:) name:@"makePhotoVideoProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSelectedPhoto:) name:@"moviePhotoAdded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedAudioResourceAtIndex:) name:@"userTappedAudioResourceAtIndex" object:nil];
    
    backButton =[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedBackButton:)];
    
    confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedSaveButton:)];
    helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedHelpButton:)];
    self.navigationItem.rightBarButtonItem = confirmButton;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.leftBarButtonItems = @[ backButton, helpButton];
    timelineBar.backgroundColor = [UIColor clearColor];
    [self.view sendSubviewToBack:timelineBar];
    videoScroller.clipsToBounds = NO;
    
    UILabel *clip = [[UILabel alloc] initWithFrame:CGRectMake(-30,20,190,20)];
    clip.backgroundColor = [UIColor clearColor];
    clip.textColor = [UIColor whiteColor];
    clip.text = @"Photos and Video";
    clip.tag = - 10000;
    clip.textAlignment = NSTextAlignmentRight;
    clip.hidden = YES;
    [videoScroller addSubview:clip];
    

    
    UILabel *clip2 = [[UILabel alloc] initWithFrame:CGRectMake(-30,75,190,20)];
    clip2.backgroundColor = [UIColor clearColor];
    clip2.textColor = [UIColor whiteColor];
    clip2.text = @"Audio";
    clip2.tag = - 10000;
    clip2.textAlignment = NSTextAlignmentRight;
    clip2.hidden = audioTracks && ([audioTracks count]>0) ? NO : YES;
    [videoScroller addSubview:clip2];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
   
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (transitionToolbar) {
        [self userTappedTransitionButton:nil];
    }
    
    float oldOffset = centeringOffset;
    
    centeringOffset = (videoScroller.bounds.size.width / 2.0f);
    
    NSLog(@"old:%f new:%f", oldOffset, centeringOffset);
    
    float f = oldOffset - centeringOffset;
    
    for (UIView *v in videoScroller.subviews) {
        CGRect r = v.frame;
        v.frame = CGRectMake(r.origin.x - f, r.origin.y, r.size.width, r.size.height);
    }
}

-(void)userTappedHelpButton:(id)sender {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}



-(void)showAddClips {
    AddClipsViewController *addVC = [[AddClipsViewController alloc] initWithNibName:@"AddClipsViewController" bundle:nil];
    addVC.delegate = self;
    [self.navigationController pushViewController:addVC animated:YES];
}

-(float)scrollerMidPos {
    return videoScroller.contentOffset.x - centeringOffset + (videoScroller.frame.size.width / 2.0f);
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
     [self updatePosition];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updatePosition];
}

-(void)updatePosition {
    CGFloat x = videoScroller.contentOffset.x;
    clipCurrentlyPointedAt = x / (thumbSize.width *2);
    
    NSInteger clipCount = [clips count];
    NSInteger audioCount = [audioTracks count];
    NSInteger maxCount = clipCount;
    if (audioCount > maxCount) {
        maxCount = audioCount;
    }
    
    if (clipCurrentlyPointedAt > maxCount -1) {
        clipCurrentlyPointedAt =  maxCount -1;
    }
    
    if (transitionToolbar) {
        if (clipCurrentlyPointedAt > clipCount -1) { //in audio track only land
            NSInteger buttonIndex = 0;
            for (NSInteger x=0;x<2;x++) {
                if (x == 0) {
                    buttonIndex = 1;
                } else {
                    buttonIndex = 3;
                }
                UIBarButtonItem *button = (UIBarButtonItem *)[transitionToolbar.items objectAtIndex:buttonIndex];
                button.enabled = NO;
            }

        } else {
            NSNumber *storedTransition = [[clipTransitionInstructions objectForKey:@(clipCurrentlyPointedAt)] objectForKey:@"transition"];
            
            NSInteger newTransition = storedTransition ? [storedTransition integerValue] : 0;
            
            NSInteger buttonIndex = 0;
            for (NSInteger x=0;x<2;x++) {
                if (x == 0) {
                    buttonIndex = 1;
                } else {
                    buttonIndex = 3;
                }
                UIBarButtonItem *button = (UIBarButtonItem *)[transitionToolbar.items objectAtIndex:buttonIndex];
                button.enabled = (newTransition != x);
            }
        }
    }
}

- (IBAction)userTappedSaveButton:(id)sender {
    
    NSArray *a = [videoScroller.subviews copy];
    for (UIView *v in a) {
        if (v.tag > -10000) {
            [v removeFromSuperview];
        } else if (v.tag < -10000) {
            [v removeFromSuperview];
        }
    }
    
    CreateMoviePreviewViewController *vc = [[CreateMoviePreviewViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"CreateMoviePreviewViewController"] bundle:nil];
    vc.clips = clips;
    vc.clipTransitionInstructions = clipTransitionInstructions;
    vc.clipNominalFrameRates = [self clipNominalFrameRates];
    vc.clipDurations = clipDurations;
    vc.audioTracks = audioTracks;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)userTappedTransitionButton:(id)sender {
    if (transitionToolbar) {
        [UIView beginAnimations:@"closeToolbar" context:nil];
        [UIView setAnimationDuration:0.25];
        CGRect r = transitionToolbar.frame;
        transitionToolbar.frame = CGRectMake(+(r.size.width), r.origin.y, r.size.width, r.size.height);
        [UIView commitAnimations];
        [self performSelector:@selector(finishClosingTransitionToolbar) withObject:nil afterDelay:0.25];
    } else {
        transitionButton.enabled = YES;
        confirmButton.enabled = NO;
        backButton.enabled = NO;
        confirmButton.enabled = NO;
        addAudioButton.enabled = NO;
        addVideoButton.enabled = NO;
        
        CGRect r = CGRectMake(+(self.view.frame.size.width), self.view.frame.size.height - 100, self.view.frame.size.width, 44);
        CGRect r2 = CGRectMake(0, r.origin.y, r.size.width, r.size.height);
        
        
        transitionToolbar = [[UIToolbar alloc] initWithFrame:r];
        [transitionToolbar setBarStyle:UIBarStyleBlack];
        [transitionToolbar setTranslucent:YES];
        
        [transitionToolbar setItems:@[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       [[UIBarButtonItem alloc] initWithTitle:@"Cut" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedTransitionToolBarButton:)],
                                       [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       [[UIBarButtonItem alloc] initWithTitle:@"Fade" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedTransitionToolBarButton:)],
                                       // [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       // [[UIBarButtonItem alloc] initWithTitle:@"X-Fade" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedTransitionToolBarButton:)],
                                ]];
        
        NSNumber *storedTransition = [[clipTransitionInstructions objectForKey:@(clipCurrentlyPointedAt)] objectForKey:@"transition"];
        
        NSInteger newTransition = storedTransition ? [storedTransition integerValue] : 0;
        
        NSInteger buttonIndex = 0;
        for (NSInteger x=0;x<2;x++) {
            if (x == 0) {
                buttonIndex = 1;
            } else {
                buttonIndex = 3;
            }
            UIBarButtonItem *button = (UIBarButtonItem *)[transitionToolbar.items objectAtIndex:buttonIndex];
            button.enabled = (newTransition != x);
        }
        
        [self.view addSubview:transitionToolbar];
        
        [UIView beginAnimations:@"closeToolbar" context:nil];
        [UIView setAnimationDuration:0.25];
        transitionToolbar.frame = r2;
        [UIView commitAnimations];
    }

}

-(void)finishClosingTransitionToolbar {
    [transitionToolbar removeFromSuperview];
    transitionToolbar = nil;
    [self updateToolbar];
}

-(void)userTappedTransitionToolBarButton:(id)sender {
    NSInteger nominalTransition = 0;
    
    NSInteger buttonCount = [transitionToolbar.items count];
    for (NSInteger x=0;x<buttonCount;x++) {
        if ([sender isEqual:[transitionToolbar.items objectAtIndex:x]]) {
            
            NSNumber *storedTransition = [[clipTransitionInstructions objectForKey:@(clipCurrentlyPointedAt)] objectForKey:@"transition"];
            
            NSInteger newTransition = storedTransition ? [storedTransition integerValue] : nominalTransition;
            
            switch (x) {
                case 1:
                    newTransition = 0 ;
                    break;
                case 3:
                    newTransition = 1;
                    break;
                case 5:
                    newTransition = 2;
                    break;
            }
            
            if (newTransition == nominalTransition) {
                [clipTransitionInstructions removeObjectForKey:@(clipCurrentlyPointedAt)];
            } else {
                [clipTransitionInstructions setObject:@{ @"transition" : [NSNumber numberWithInteger:newTransition] } forKey:@(clipCurrentlyPointedAt)];
            }
            
            TransitionBlock *block = (TransitionBlock *)[videoScroller viewWithTag: (-200) - clipCurrentlyPointedAt];
            block.type = newTransition;
            [block setNeedsDisplay];
            
            NSInteger buttonIndex = 0;
            for (NSInteger x=0;x<2;x++) {
                if (x == 0) {
                    buttonIndex = 1;
                } else {
                    buttonIndex = 3;
                }
                UIBarButtonItem *button = (UIBarButtonItem *)[transitionToolbar.items objectAtIndex:buttonIndex];
                button.enabled = (newTransition != x);
            }
        }
    }
}


- (IBAction)userTappedBackButton:(id)sender {
    
    [[AssetManager manager] cleanupMoviePhotosTemp];

    [self performSelector:@selector(dealloc2) withObject:nil afterDelay:0.4];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)userTappedAddAudio:(id)sender {
    AddAudioViewController *addVC = [[AddAudioViewController alloc] initWithNibName:@"AddAudioViewController" bundle:nil];
    addVC.delegate = self;
    [self.navigationController pushViewController:addVC animated:YES];
}

- (IBAction)userTappedAddVideo:(id)sender {
    [self showAddClips];
}

@end
