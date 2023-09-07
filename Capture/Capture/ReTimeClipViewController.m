//
//  ReTimeClipViewController.m
//  Capture
//
//  Created by Gary Barnett on 11/24/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ReTimeClipViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CutTimelineView.h"
#import "ReTimeConfirmViewController.h"
#import "HelpViewController.h"
#import "CutClipViewController.h"
#import "FilterClipViewController.h"

@interface ReTimeClipViewController ()

@end

@implementation ReTimeClipViewController {
    __weak IBOutlet UIBarButtonItem *startOverButton;
   
    
    __weak IBOutlet UIBarButtonItem *fpsButton;
    __weak IBOutlet CutScrubberBar *cutScrubberBar;
    __weak IBOutlet ThumbnailView *largeThumbView;
    __weak IBOutlet UIScrollView *scroller;
    __weak IBOutlet GradientAttributedButton *endReTimeButton;
    __weak IBOutlet GradientAttributedButton *beginReTimeButton;
    __weak IBOutlet UIBarButtonItem *freezeButton;
    
    CutTimelineView *timelineView;
    
    BOOL hasBeginCut;
    
    CMTime beginCut;
    
    CMTime duration;
    
    NSMutableArray *cutList;
    
    NSMutableArray *thumbTimes;
    
    NSMutableDictionary *thumbIndexes;
    

     AVAssetImageGenerator *generator;
     AVAssetImageGenerator *largeGenerator;
    
    CGSize thumbSize;
    
    BOOL isiPad;
    
    float centeringOffset;
    
    NSInteger seconds;
    
    NSInteger currentSecond;
    
    CMTime lastLargeThumb;
    CMTime reqLargeThumb;
    
    NSTimer *smallTimer;
    NSInteger lastKnownTimerSecond;
    NSMutableArray *smallAddList;
    
    UIView *currentCutView;
    
    UISegmentedControl *segmentControl;

    UIDynamicAnimator *detailAnimator;
    UIView *detailView;
    UILabel *detailfpsLabel;
    AVURLAsset *asset;
    NSInteger naturalFrameRate;
    NSInteger currentFrameRate;
    NSArray *speedRatio;
    NSArray *speedList;
    
}
@synthesize toolBar;

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
    _clip = nil;
    
    startOverButton = nil;
    toolBar = nil;
    fpsButton = nil;
    cutScrubberBar = nil;
    largeThumbView = nil;
    scroller = nil;
    endReTimeButton = nil;
    beginReTimeButton = nil;
    timelineView = nil;
    cutList = nil;
    thumbTimes = nil;
    thumbIndexes = nil;
    _clip = nil;
    generator = nil;
    largeGenerator = nil;
    smallTimer = nil;
    smallAddList = nil;
    currentCutView = nil;
    segmentControl = nil;
    detailAnimator = nil;
    detailView = nil;
    detailfpsLabel = nil;
    asset = nil;
}

-(void)userChangedSegment {
    if (segmentControl.selectedSegmentIndex == 0) {
        CutClipViewController *vc = [[CutClipViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"CutClipViewController"] bundle:nil];
        vc.clip = _clip;
        NSMutableArray *vcStack = [self.navigationController.viewControllers mutableCopy];
        [vcStack removeLastObject];
        [vcStack addObject:vc];
        [self.navigationController setViewControllers:[vcStack copy] animated:NO];
        [self cleanup:nil];
    } else if (segmentControl.selectedSegmentIndex == 1) {
        FilterClipViewController *vc = [[FilterClipViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"FilterClipViewController"] bundle:nil];
        vc.clip = _clip;
        NSMutableArray *vcStack = [self.navigationController.viewControllers mutableCopy];
        [vcStack removeLastObject];
        [vcStack addObject:vc];
        [self.navigationController setViewControllers:[vcStack copy] animated:NO];
        [self cleanup:nil];
    }

}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
            // Custom initialization
        cutList = [[NSMutableArray alloc] initWithCapacity:1];
        thumbTimes = [[NSMutableArray alloc] initWithCapacity:100];
        thumbIndexes = [[NSMutableDictionary alloc] initWithCapacity:100];
        smallAddList = [[NSMutableArray alloc] initWithCapacity:100];
        smallTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(smallTimerEvent) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:smallTimer forMode:NSRunLoopCommonModes];
        
        segmentControl = [[UISegmentedControl alloc] initWithItems:@[ @"Cut", @"Filter", @"Re-Time"] ];
        [segmentControl setSelectedSegmentIndex:2];
        [segmentControl addTarget:self action:@selector(userChangedSegment) forControlEvents:UIControlEventValueChanged];

    }
    return self;
}
-(void)userTappedCancel {
    
    [self performSelector:@selector(cleanup:) withObject:nil afterDelay:0.4];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        // Do any additional setup after loading the view from its nib.
    
    speedRatio = @[@(1.0 / 120.0f), @(1.0 / 60.0f), @(1.0 / 48.0f), @(1.0 / 24.0f), @(1.0 / 12.0f), @(1.0 / 10.0f), @(1.0 / 8.0f), @(1.0 / 6.0f), @(0.25f), @(0.5f), @(0.75f), @(1.0f), @(1.25f), @(1.5f), @(1.75f), @(2.f), @(3.f), @(4.f), @(6.f), @(8.f), @(10.f), @(12.f), @(24.f), @(48.f), @(60.f), @(120.f)];
    
    
    speedList = @[@"1/120x", @"1/60x", @"1/48x", @"1/24x", @"1/12x", @"1/10x", @"1/8x", @"1/6x", @"0.25x", @"0.5x", @"0.75x", @"1x", @"1.25x", @"1.5x", @"1.75x", @"2x", @"3x", @"4x", @"6x", @"8x", @"10x", @"12x", @"24x", @"48x", @"60x", @"120x"];
    
    AVAssetTrack *clipVideoTrack = [[_clip tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    naturalFrameRate = [clipVideoTrack nominalFrameRate];
    currentFrameRate = naturalFrameRate;
    
    isiPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
   // self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationController.toolbarHidden = YES;
    self.navigationItem.title = @"Edit Clip";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedConfirmButton:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    
    beginCut = CMTimeMake(1,_clip.duration.timescale);
    
    beginReTimeButton.enabled = YES;
    endReTimeButton.enabled = NO;
    
    beginReTimeButton.delegate = self;
    endReTimeButton.delegate = self;
    
    beginReTimeButton.tag = 1;
    endReTimeButton.tag = 2;
    
    thumbSize = CGSizeMake(60,34);
    if (isiPad) {
        thumbSize = CGSizeMake(120,68);
    }
    
    largeThumbView.backgroundColor = [UIColor blackColor];
    UISwipeGestureRecognizer *swipeR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(userSwipedLargeThumb:)];
    swipeR.direction = UISwipeGestureRecognizerDirectionRight;
    
    UISwipeGestureRecognizer *swipeL = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(userSwipedLargeThumb:)];
    swipeL.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [largeThumbView addGestureRecognizer:swipeR];
    [largeThumbView addGestureRecognizer:swipeL];
    

    generator = [[AVAssetImageGenerator alloc] initWithAsset:_clip];
    generator.appliesPreferredTrackTransform = YES;
    
    largeGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_clip];
    largeGenerator.appliesPreferredTrackTransform = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanup" object:nil];
    
}

-(void)userTappedHelpButton:(id)sender {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateView];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self performSelector:@selector(generateTimeline) withObject:nil afterDelay:0.1];
}

-(void)updateToolbar {
    startOverButton.enabled = hasBeginCut || ([cutList count] > 0);
    self.navigationItem.rightBarButtonItem.enabled = [cutList count] > 0;
    self.navigationItem.titleView = segmentControl;
    [fpsButton setTitle:[NSString stringWithFormat:@"%ld FPS", (long)currentFrameRate]];
}

-(void)updateButtons {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    
    NSAttributedString *sActive = [[NSAttributedString alloc] initWithString:@"Begin Selection" attributes:@{
                                                                                                       NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                       NSShadowAttributeName : shadow,
                                                                                                       NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                       }];
    
    
    NSAttributedString *eActive = [[NSAttributedString alloc] initWithString:@"End Selection" attributes:@{
                                                                                                     NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }];
    
    if (beginReTimeButton.enabled) {
        [beginReTimeButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    } else {
        [beginReTimeButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    if (endReTimeButton.enabled) {
        [endReTimeButton setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#3333FF" endGradientColor:@"#0000FF"];
    } else {
        [endReTimeButton setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    [beginReTimeButton update];
    [endReTimeButton update];
}


-(void)generateTimeline {
    seconds = CMTimeGetSeconds(_clip.duration);
    
    NSArray *sv = scroller.subviews;
    for (UIView *v in sv) {
        [v removeFromSuperview];
    }
    
    CGFloat yoffset = 88;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        yoffset = scroller.frame.origin.y;
    }
    
    cutScrubberBar.frame = CGRectMake(0,yoffset - 44,self.view.frame.size.width, 44);
    scroller.frame = CGRectMake(0,yoffset,self.view.frame.size.width, thumbSize.height + 14);
    
    centeringOffset = (scroller.bounds.size.width / 2.0f);
    
    if (timelineView) {
        [timelineView removeFromSuperview];
        timelineView = nil;
    }
    
    timelineView = [[CutTimelineView alloc] initWithFrame:CGRectMake(centeringOffset,0,thumbSize.width * seconds, 14)];
    timelineView.seconds = seconds;
    timelineView.thumbSize = thumbSize;
    timelineView.tag = -100;
    
    [cutScrubberBar setDuration:seconds];
    [cutScrubberBar setDelegate:self];
    
    [scroller addSubview:timelineView];
    [scroller setContentSize:CGSizeMake( (centeringOffset * 2.0f) + timelineView.frame.size.width, scroller.frame.size.height)];
    
    for (NSInteger x=0;x<=seconds;x++) {
        CMTime t = CMTimeMakeWithSeconds(x, _clip.duration.timescale);
        NSValue *v =[NSValue valueWithCMTime:t];
        [thumbTimes addObject:v];
        [thumbIndexes setObject:[NSNumber numberWithInteger:x] forKey:v];
    }
    
    [generator setMaximumSize:thumbSize];
    [largeGenerator setMaximumSize:largeThumbView.frame.size];
    
    
    [largeGenerator setRequestedTimeToleranceBefore:CMTimeMake(_clip.duration.timescale * 0.05, _clip.duration.timescale)];
    [largeGenerator setRequestedTimeToleranceAfter:CMTimeMake(_clip.duration.timescale * 0.05, _clip.duration.timescale)];
    
    currentSecond = 0;
    lastLargeThumb = CMTimeMake(1,_clip.duration.timescale);
    reqLargeThumb = lastLargeThumb;
    [self updateScroller];
    [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb]];
    
    
    //rebuild retime views
    if ([cutList count]>0) {
        for (NSInteger x=0;x<[cutList count];x++) {
            NSValue *cutB = (NSValue *)cutList[x][0];
            NSValue *cutE = (NSValue *)cutList[x][1];
            NSNumber *cutFPS = (NSNumber *)cutList[x][2];
            
            CMTime start = [cutB CMTimeValue];
            CMTime end = [cutE CMTimeValue];
            
            CGFloat s = centeringOffset +  (float)start.value / (float)start.timescale * thumbSize.width;
            CGFloat e = centeringOffset +  (float)end.value / (float)end.timescale * thumbSize.width;
            
            UIView *cutView = [[UIView alloc] initWithFrame:CGRectMake(s, 0, e - s, scroller.frame.size.height)];
            cutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
            UILabel *l = [[UILabel alloc] initWithFrame:cutView.bounds];
            l.tag = currentFrameRate;
            l.text = [NSString stringWithFormat:@"%ld", (long)[cutFPS integerValue]];
            l.textAlignment = NSTextAlignmentCenter;
            l.textColor = [UIColor whiteColor];
            l.font = [UIFont systemFontOfSize:32];
            [cutView addSubview:l];
            cutView.tag = -200;
            [scroller addSubview:cutView];
        }
    }

}

-(void)smallTimerEvent {
    if (lastKnownTimerSecond != currentSecond) {
        lastKnownTimerSecond = currentSecond;
        [self updateScroller];
    }
}

-(void)userSwipedLargeThumb:(UISwipeGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        if (g.direction == UISwipeGestureRecognizerDirectionRight) {
            lastLargeThumb = CMTimeMake(lastLargeThumb.value + (lastLargeThumb.timescale * 0.03), lastLargeThumb.timescale);
        } else {
            lastLargeThumb = CMTimeMake(lastLargeThumb.value - (lastLargeThumb.timescale * 0.1), lastLargeThumb.timescale);
        }
        
        if (CMTimeCompare(lastLargeThumb, CMTimeMake(1,_clip.duration.timescale)) -1) {
            lastLargeThumb = CMTimeMake(1,_clip.duration.timescale);
        } else if (CMTimeCompare(lastLargeThumb, _clip.duration) == 1) {
            lastLargeThumb = _clip.duration;
        }
    }
    
    [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb]];
}

-(void)generateLargeThumbnailForTime:(NSValue *)time {
    [largeGenerator cancelAllCGImageGeneration];
    [largeGenerator generateCGImagesAsynchronouslyForTimes:@[ time ] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( (!error) && (result == AVAssetImageGeneratorSucceeded) && image) {
            [largeThumbView performSelectorOnMainThread:@selector(setImage:) withObject:(__bridge id)image waitUntilDone:YES];
                //  NSLog(@"DeliveredLarge:%@", [NSValue valueWithCMTime:requestedTime]);
        } else if (result == AVAssetImageGeneratorCancelled) {
                //say nothing
        } else {
            NSLog(@"large thumbnail generation error:%@:%ld", [error localizedDescription], (long)result);
        }
    }];
}

-(float)scrollerMidPos {
    return scroller.contentOffset.x - centeringOffset + (scroller.frame.size.width / 2.0f);
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

    if (detailView) {
        [self cleanDetailView];
        startOverButton.enabled = YES;
        [self updateToolbar];
    }
    
    endReTimeButton.enabled = NO;
    [self updateView];
    
    [thumbTimes removeAllObjects];
    [thumbIndexes removeAllObjects];
    [generator cancelAllCGImageGeneration];
    [smallAddList removeAllObjects];
    [self generateTimeline];
    lastKnownTimerSecond = -1;
    [scroller setContentOffset:CGPointMake(0,0)];
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    float midPos = [self scrollerMidPos];
    
    float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
    
    currentSecond = seconds * p;
    [cutScrubberBar updatePosition:currentSecond];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float midPos =  [self scrollerMidPos];
    float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
    
    currentCutView.frame = CGRectMake(currentCutView.frame.origin.x, 0, midPos + centeringOffset - currentCutView.frame.origin.x, currentCutView.frame.size.height);
    
    currentSecond = seconds * p;
    
    CMTime secTime = CMTimeMake((_clip.duration.value * p) + 1 , _clip.duration.timescale);
    
    if (hasBeginCut && (CMTimeCompare(secTime, beginCut) == -1) ) {
        hasBeginCut = NO;
        beginCut = kCMTimeZero;
        endReTimeButton.enabled = NO;
        [self updateButtons];
        [currentCutView removeFromSuperview];
        currentCutView = nil;
    }
    
    if ( (CMTimeCompare(lastLargeThumb, secTime) == 0) && (CMTimeCompare(reqLargeThumb, secTime) !=0) ) {
            //do nothing
    } else if (CMTimeCompare(lastLargeThumb, secTime) != 0) {
        reqLargeThumb = secTime;
        NSValue *req = [NSValue valueWithCMTime:reqLargeThumb];
        [self generateLargeThumbnailForTime:req];
    }
    
    [cutScrubberBar updatePosition:currentSecond];
}


-(void)updateScroller {
    if ([smallAddList count]>0) {
        return;
    }

    NSArray *sv = [scroller.subviews copy];
    
    for (UIView *v in sv) {
        if (v.tag == -100 ) {
                //skip timeline
        } else if (v.tag == -200 ) {
                //skip currentCutView
        } else if (v.tag < currentSecond - 10) {
            [v removeFromSuperview];
        } else if (v.tag > currentSecond + 10) {
            [v removeFromSuperview];
        }
    }
    
    NSInteger start = currentSecond - 10;
    NSInteger end = currentSecond + 10;
    
    if (start <0) {
        start = 0;
    }
    
    if (end >= seconds) {
        end = seconds;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:50];
    
    for (UIView *v in scroller.subviews) {
        [dict setObject:v forKey:[NSNumber numberWithInteger:v.tag]];
    }
    
    NSMutableArray *addList = [[NSMutableArray alloc] initWithCapacity:50];
    
    for (NSInteger x=0;x<=seconds;x++) {
        if ( (x < start) || (x > end) ) {
            [smallAddList removeObject:[thumbTimes objectAtIndex:x]];
        }
    }
    
    
    for (NSInteger x=start;x<end;x++) {
        NSNumber *nX = [NSNumber numberWithInteger:x];
        UIView *v = [dict objectForKey:nX];
        if ( (!v) && ([smallAddList indexOfObject:[thumbTimes objectAtIndex:x]] == NSNotFound) ) {
            [addList addObject:[thumbTimes objectAtIndex:x]];
        }
    }
    
    [smallAddList addObjectsFromArray:[addList copy]];
    
    [generator generateCGImagesAsynchronouslyForTimes:[addList copy] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( (!error) && (result == AVAssetImageGeneratorSucceeded) && image) {
            lastLargeThumb = reqLargeThumb;
            if ([smallAddList indexOfObject:[NSValue valueWithCMTime:requestedTime]] != NSNotFound) {
                [smallAddList removeObject:[NSValue valueWithCMTime:requestedTime]];
                NSNumber *index = [thumbIndexes objectForKey:[NSValue valueWithCMTime:requestedTime]];
                if (index) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(centeringOffset + (([index intValue]) * thumbSize.width),14,thumbSize.width, thumbSize.height)];
                        v.layer.contents = (__bridge id)(image);
                        v.tag = [index intValue];
                        [scroller insertSubview:v belowSubview:timelineView];
                        if (currentCutView) {
                            [scroller bringSubviewToFront:currentCutView];
                        }
                    });
                }
            }
        } else if (result == AVAssetImageGeneratorCancelled) {
                //Say nothing
        } else {
            NSLog(@"small thumbnail generation error:%@:%ld", [error localizedDescription], (long)result);
        }
    }];
}

-(void)updateView {
    [self updateButtons];
    [self updateToolbar];
}

-(void)userDidBeginScrubberPress {
    scroller.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

-(void)reEnableCutScrubberBar {
    cutScrubberBar.userInteractionEnabled = YES;
}

-(void)userPressedScrubberAtSecond:(NSInteger)sec {
    cutScrubberBar.userInteractionEnabled = NO;
    float p = (float)seconds / (float)sec;
    
    float origin = scroller.contentSize.width / p;
    
    origin -= scroller.frame.size.width / 2.0f;
    
    if (origin < 0) {
        origin = 0;
    }
    
    CGRect r = CGRectMake(origin, 0, scroller.frame.size.width, thumbSize.height + 14);
    
    [scroller scrollRectToVisible:r animated:NO];
    
    [self scrollViewDidScroll:scroller];
}


-(void)userDidEndScrubberPress {
    scroller.hidden = NO;
    [self reEnableCutScrubberBar];
}


-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    
    if (tag >=1000) {
        NSInteger index = tag - 1000;
        currentFrameRate = naturalFrameRate * [[speedRatio objectAtIndex:index] floatValue];
        UISlider *slider = (UISlider *)[detailView viewWithTag:42];
        slider.value = currentFrameRate;
        detailfpsLabel.text = [NSString stringWithFormat:@"%ld FPS", (long)currentFrameRate];
        fpsButton.title = [NSString stringWithFormat:@"%ld FPS", (long)currentFrameRate];
        [self updateSpeedButtons];
        return;
    }
    
    switch (tag) {
        case -99:
        {
            [self closeDetailView];
        }
            break;
        case -98:
        {
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            currentCutView = [[UIView alloc] initWithFrame:CGRectMake(midPos-1 + centeringOffset, 0,2, scroller.frame.size.height)];
            currentCutView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
            currentCutView.tag = -200;
            [scroller addSubview:currentCutView];
            beginCut = CMTimeMake(_clip.duration.value * p, _clip.duration.timescale);
            
            [cutList addObject:@[ [NSValue valueWithCMTime:beginCut], [NSValue valueWithCMTime:CMTimeMake(_clip.duration.value * p, _clip.duration.timescale)], @(0.0), @([[SettingsTool settings] defaultRetimeFreezeDuration])]];
             NSLog(@"added:%@", [cutList lastObject]);
            currentCutView.backgroundColor = [UIColor blueColor];
            UILabel *l = [[UILabel alloc] initWithFrame:currentCutView.bounds];
            l.tag = currentFrameRate;
            l.text = [NSString stringWithFormat:@"F%@", @([[SettingsTool settings] defaultRetimeFreezeDuration])];
            l.textAlignment = NSTextAlignmentCenter;
            l.textColor = [UIColor whiteColor];
            l.font = [UIFont systemFontOfSize:32];
            [currentCutView addSubview:l];
            
            currentCutView = nil;
            [self closeDetailView];
        }
            break;
        case 1:
        {
            [currentCutView removeFromSuperview];
            currentCutView = nil;
            
            hasBeginCut = YES;
            
            endReTimeButton.enabled = YES;
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            beginCut = CMTimeMake(_clip.duration.value * p, _clip.duration.timescale);
            
            float viewXPos = midPos-1 + centeringOffset;
            
            for (NSInteger x=0;x<[cutList count];x++) {
                NSValue *cutB = (NSValue *)cutList[x][0];
                NSValue *cutE = (NSValue *)cutList[x][1];
                NSNumber *cutFPS = (NSNumber *)cutList[x][2];
                CMTime cutDuration = CMTimeSubtract([cutE CMTimeValue], [cutB CMTimeValue]);
                
                if (CMTimeRangeContainsTime(CMTimeRangeMake([cutB CMTimeValue], cutDuration), beginCut)) {
                    NSValue *cutEchopped = [NSValue valueWithCMTime:CMTimeMake(beginCut.value, beginCut.timescale)];
                    [cutList replaceObjectAtIndex:x withObject:@[ cutB, cutEchopped, cutFPS]];
                    for (UIView *v in scroller.subviews) {
                        if (v.tag != -200) {
                            continue;
                        }
                            //NSLog(@"updating %@", v);
                        if ( (v.frame.origin.x < viewXPos) && (v.frame.origin.x + v.frame.size.width >= viewXPos) ){
                            v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, viewXPos - v.frame.origin.x, v.frame.size.height);
                        }
                    }
                }
            }
            
            currentCutView = [[UIView alloc] initWithFrame:CGRectMake(midPos-1 + centeringOffset, 0,2, scroller.frame.size.height)];
            currentCutView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
            currentCutView.tag = -200;
            [scroller addSubview:currentCutView];
        }
            break;
        case 2://end
        {
            if (!hasBeginCut) {
                return;
            }
            hasBeginCut = NO;
            endReTimeButton.enabled = NO;
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            [cutList addObject:@[ [NSValue valueWithCMTime:beginCut], [NSValue valueWithCMTime:CMTimeMake(_clip.duration.value * p, _clip.duration.timescale)], @(currentFrameRate)]];
                // NSLog(@"added:%@", [cutList lastObject]);
            currentCutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
            UILabel *l = [[UILabel alloc] initWithFrame:currentCutView.bounds];
            l.tag = currentFrameRate;
            l.text = [NSString stringWithFormat:@"%ld FPS", (long)currentFrameRate];
            l.textAlignment = NSTextAlignmentCenter;
            l.textColor = [UIColor whiteColor];
            l.font = [UIFont systemFontOfSize:32];
            [currentCutView addSubview:l];

            currentCutView = nil;
        }
            break;
    }
    
    [self updateView];
}

- (IBAction)userTappedConfirmButton:(id)sender {
    ReTimeConfirmViewController *vc = [[ReTimeConfirmViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"ReTimeConfirmViewController"] bundle:nil];
    vc.clip = _clip;
    vc.cutList = [cutList copy];
    vc.naturalFrameRate = naturalFrameRate;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)userTappedStartOverButton:(id)sender {
    hasBeginCut = NO;
    endReTimeButton.enabled = NO;
    
    for (UIView *v in scroller.subviews) {
        if (v.tag == -200) {
            [v removeFromSuperview];
        }
    }
    
    currentCutView = nil;
    
    [cutList removeAllObjects];
    
    [self updateView];
}

-(void)closeDetailView {
    if (!detailView) {
        return;
    }
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [detailAnimator removeAllBehaviors];
    [detailAnimator addBehavior:gravity];
    [self performSelector:@selector(cleanDetailView) withObject:nil afterDelay:1.0f];
}

-(void)cleanDetailView {
    if (!detailView) {
        return;
    }
    [detailAnimator removeAllBehaviors];
    detailAnimator = nil;
    [detailView removeFromSuperview];
    detailView = nil;
    detailfpsLabel = nil;
}

-(void)userTappedDetailView:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self closeDetailView];
    }
}

-(void)userChangedSlider:(id)sender {
    UISlider *slider = (UISlider *)sender;
    currentFrameRate = slider.value;
    detailfpsLabel.text = [NSString stringWithFormat:@"%ld FPS", (long)currentFrameRate];
    fpsButton.title = [NSString stringWithFormat:@"%ld FPS", (long)currentFrameRate];
    [self updateToolbar];
    [self updateSpeedButtons];
}

-(void)userChangedFreezeSlider:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [[SettingsTool settings] setDefaultRetimeFreezeDuration:slider.value];
    detailfpsLabel.text = [self freezeDurationLabel];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(IBAction)userTappedFPSButton:(id)sender {
    if (detailAnimator) {
        [self closeDetailView];
        return;
    }
    
    detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 235, -240, 470, 240)];
    detailView.backgroundColor = [UIColor whiteColor];
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedDetailView:)];
    [detailView addGestureRecognizer:tapG];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10,0,180,30)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Starting Frame Rate";
    l.textColor = [UIColor blackColor];
    [detailView addSubview:l];
    
    UILabel *sourceLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,30,180,40)];
    sourceLabel.textAlignment = NSTextAlignmentCenter;
    sourceLabel.text = [NSString stringWithFormat:@"%ld FPS", (long)naturalFrameRate];
    sourceLabel.textColor = [UIColor blackColor];
    sourceLabel.font = [l.font fontWithSize:32];
    [detailView addSubview:sourceLabel];
    
    UILabel *l2 = [[UILabel alloc] initWithFrame:CGRectMake(270,00,180,30)];
    l2.textAlignment = NSTextAlignmentCenter;
    l2.text = @"New Frame Rate";
    l2.textColor = [UIColor blackColor];
    [detailView addSubview:l2];

    detailfpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(270,30,180,40)];
    detailfpsLabel.textAlignment = NSTextAlignmentCenter;
    detailfpsLabel.text = [NSString stringWithFormat:@"%ld FPS", (long)currentFrameRate];
    detailfpsLabel.textColor = [UIColor blackColor];
    detailfpsLabel.font = [l.font fontWithSize:32];
    [detailView addSubview:detailfpsLabel];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10,80,440,44)];
    slider.minimumValue = 1;
    slider.maximumValue = 120;
    slider.tag = 42;
    slider.value = currentFrameRate;
    [slider addTarget:self action:@selector(userChangedSlider:) forControlEvents:UIControlEventValueChanged];
    [detailView addSubview:slider];
    
    UILabel *l3 = [[UILabel alloc] initWithFrame:CGRectMake(0,125,detailView.frame.size.width,30)];
    l3.textAlignment = NSTextAlignmentCenter;
    l3.text = @"Frame Rate Adjustment Ratios";
    l3.textColor = [UIColor blackColor];
    [detailView addSubview:l3];

    
    [self updateSpeedButtons];
    
    [self.view addSubview:detailView];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView] ];
    
    CGFloat y = self.view.frame.size.height - 50;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = (self.view.frame.size.height / 2.0f) + 210;
    }
    
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
    [detailAnimator addBehavior:collision];
    [detailAnimator addBehavior:gravity];
}

-(void)updateSpeedButtons {
    NSMutableArray *vList = [detailView.subviews mutableCopy];
    
    for (UIView *v in vList) {
        if (v.tag >=1000) {
            [v removeFromSuperview];
        }
    }
    
    NSInteger offset = 0;
    for (NSInteger x=0;x<[speedRatio count];x++) {
        NSNumber *ratio = [speedRatio objectAtIndex:x];
        NSInteger rate = naturalFrameRate * [ratio floatValue];
        
        if (rate > 120) {
            continue;
        } else if (rate < 1) {
            continue;
        }
        
        NSInteger row = (offset / 10);
        NSInteger col = offset - (row * 10);
        
        BOOL selected = ((float)naturalFrameRate * [ratio floatValue] == (float)currentFrameRate);
        
        GradientAttributedButton *button = [self makeButtonForSpeed:x enabled:YES
                                                          withFrame:CGRectMake( (col * 47), 150 + (row * 45  ), 47, 45)
                                                           selected:selected];
        [detailView addSubview:button];
        offset++;
    }
}

-(GradientAttributedButton *)makeButtonForSpeed:(NSInteger )index enabled:(BOOL)enabled withFrame:(CGRect )frame selected:(BOOL)selected {
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:frame];
    button.delegate = self;
    button.tag = 1000 + index;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[[UtilityBag bag] standardFont] fontWithSize:10], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSString *bColor = @"#666666";
    NSString *eColor = @"#333333";
    
    if (!enabled) {
        bColor = @"#AAAAAA";
        eColor = @"#999999";
    } else if (selected) {
        bColor = @"#009900";
        eColor = @"#006600";
    }
    
    NSAttributedString *buttonTitle =[[NSAttributedString alloc] initWithString:[speedList objectAtIndex:index] attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = enabled;
    [button update];

    [detailView addSubview:button];

    return button;
}

-(NSString *)freezeDurationLabel {
    return [NSString stringWithFormat:@"%@ second%@", @([[SettingsTool settings] defaultRetimeFreezeDuration]), [[SettingsTool settings] defaultRetimeFreezeDuration] > 1 ? @"s" : @""];
}

-(IBAction)userTappedFreezeButton:(id)sender {
    detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 235, -240, 470, 220)];
    detailView.backgroundColor = [UIColor whiteColor];
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedDetailView:)];
    [detailView addGestureRecognizer:tapG];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,470,30)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Freeze-Frame Duration";
    l.textColor = [UIColor blackColor];
    [detailView addSubview:l];
    
    detailfpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,30,470,40)];
    detailfpsLabel.textAlignment = NSTextAlignmentCenter;
    detailfpsLabel.text = [self freezeDurationLabel];
    detailfpsLabel.textColor = [UIColor blackColor];
    detailfpsLabel.font = [l.font fontWithSize:32];
    [detailView addSubview:detailfpsLabel];
    detailfpsLabel.tag = 100;
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10,80,440,44)];
    slider.minimumValue = 1;
    slider.maximumValue = 30;
    slider.tag = 42;
    slider.value = currentFrameRate;
    [slider addTarget:self action:@selector(userChangedFreezeSlider:) forControlEvents:UIControlEventValueChanged];
    [detailView addSubview:slider];

    [self.view addSubview:detailView];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView] ];
    
    CGFloat y = self.view.frame.size.height - 50;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = (self.view.frame.size.height / 2.0f) + 210;
    }
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(156-60, 150, 100, 50)];
    button.delegate = self;
    button.tag = -99;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [[[UtilityBag bag] standardFont] fontWithSize:10], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSString *bColor = @"#666666";
    NSString *eColor = @"#333333";
    
    NSAttributedString *buttonTitle = [[NSAttributedString alloc] initWithString:@"Cancel" attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = YES;
    [button update];
    
    [detailView addSubview:button];
    
    button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(312-60,150, 100, 50)];
    button.delegate = self;
    button.tag = -98;

    
    buttonTitle = [[NSAttributedString alloc] initWithString:@"Add" attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:bColor endGradientColor:eColor];
    button.enabled = YES;
    [button update];
    
    [detailView addSubview:button];

    
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
    [detailAnimator addBehavior:collision];
    [detailAnimator addBehavior:gravity];

}

@end
