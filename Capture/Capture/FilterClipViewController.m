//
//  FilterClipViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/1/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "FilterClipViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CutTimelineView.h"
#import "FilterClipViewController.h"
#import "HelpViewController.h"
#import "CutClipViewController.h"
#import "FilterClipConfirmViewController.h"
#import "ReTimeClipViewController.h"
#import <GPUImage/GPUImage.h>

@interface FilterClipViewController ()

@end

@implementation FilterClipViewController {
    __weak IBOutlet UIBarButtonItem *startOverButton;
    __weak IBOutlet UIToolbar *toolBar;
    __weak IBOutlet UIBarButtonItem *adjustButton;
    __weak IBOutlet UIBarButtonItem *filterButton;
    __weak IBOutlet CutScrubberBar *cutScrubberBar;
    __weak IBOutlet ThumbnailView *largeThumbView;
    __weak IBOutlet UIScrollView *scroller;
    __weak IBOutlet GradientAttributedButton *endFilterButton;
    __weak IBOutlet GradientAttributedButton *beginFilterButton;
    
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
    UIView *adjustView;
    UIScrollView *detailScroller;
    
    NSInteger currentFilter;
    NSMutableDictionary *currentFilterDict;
    NSInteger currentFilterAttrIndex;
    
}

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
    adjustButton = nil;
   filterButton = nil;
    cutScrubberBar = nil;
    largeThumbView = nil;
    scroller = nil;
    endFilterButton = nil;
    beginFilterButton = nil;
    
    timelineView = nil;
    
    cutList = nil;
    
    thumbTimes = nil;
    
    thumbIndexes = nil;
    
    generator = nil;
    largeGenerator = nil;
    smallAddList = nil;
    
 
    currentCutView = nil;
    
    segmentControl = nil;
    
    detailAnimator = nil;
    detailView = nil;
    adjustView = nil;
    detailScroller = nil;
    
    currentFilterDict = nil;
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
    } else if (segmentControl.selectedSegmentIndex == 2) {
        ReTimeClipViewController *vc = [[ReTimeClipViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"ReTimeClipViewController"] bundle:nil];
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
        [segmentControl setSelectedSegmentIndex:1];
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
    currentFilter = -1;
   // self.automaticallyAdjustsScrollViewInsets = YES;
    
    [GPUFilterTool bag].delegate = self;
    
    isiPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.navigationItem.title = @"Edit Clip";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedConfirmButton:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    
    beginCut = CMTimeMake(1,_clip.duration.timescale);
    
    beginFilterButton.enabled = NO;
    endFilterButton.enabled = NO;
    
    beginFilterButton.delegate = self;
    endFilterButton.delegate = self;
    
    beginFilterButton.tag = 1;
    endFilterButton.tag = 2;
    
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
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterGeneratedForThumbnailAtIndex:) name:@"filterGeneratedForThumbnailAtIndex" object:nil];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (adjustView) {
        [self cleanAdjustView];
        startOverButton.enabled = YES;
        [self updateToolbar];
    }
    
    if (detailView) {
        [self cleanDetailView];
        startOverButton.enabled = YES;
        [self updateToolbar];
    }

    endFilterButton.enabled = NO;
    [self updateView];
    
    [thumbTimes removeAllObjects];
    [thumbIndexes removeAllObjects];
    [generator cancelAllCGImageGeneration];
    [smallAddList removeAllObjects];
    [self generateTimeline];
    lastKnownTimerSecond = -1;
    [scroller setContentOffset:CGPointMake(0,0)];

}

-(void)userTappedHelpButton:(id)sender {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateView];
    [self updateButtons];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self performSelector:@selector(generateTimeline) withObject:nil afterDelay:0.1];
    
  
}

-(void)updateToolbar {
    startOverButton.enabled = hasBeginCut || ([cutList count] > 0);
    self.navigationItem.rightBarButtonItem.enabled = [cutList count] > 0;
    self.navigationItem.titleView = segmentControl;
    if (currentFilter > -1) {
        adjustButton.title = [NSString stringWithFormat:@"Adjust: %@", [[[GPUFilterTool bag] filterNames] objectAtIndex:currentFilter]];
        adjustButton.enabled = YES;
    } else {
        adjustButton.title = @"Adjust: None";
        adjustButton.enabled = NO;
    }
                           
}

-(void)updateButtons {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    
    NSAttributedString *sActive = [[NSAttributedString alloc] initWithString:@"Start Filter" attributes:@{
                                                                                                       NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                       NSShadowAttributeName : shadow,
                                                                                                       NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                       }];
    
    
    NSAttributedString *eActive = [[NSAttributedString alloc] initWithString:@"End Filter" attributes:@{
                                                                                                     NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }];
    
    if (beginFilterButton.enabled) {
        [beginFilterButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    } else {
        [beginFilterButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    if (endFilterButton.enabled) {
        [endFilterButton setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#3333FF" endGradientColor:@"#0000FF"];
    } else {
        [endFilterButton setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    [beginFilterButton update];
    [endFilterButton update];
}

-(void)updateCutScrubberFrame {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:2.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat yoffset = 44;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                yoffset = cutScrubberBar.frame.origin.y;
            }
            cutScrubberBar.frame = CGRectMake(0,yoffset,self.view.frame.size.width, 44);
        });
    });
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
    
    [self updateCutScrubberFrame];
    
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
    lastKnownTimerSecond  = 0;
    lastLargeThumb = CMTimeMake(1,_clip.duration.timescale);
    reqLargeThumb = lastLargeThumb;
    [self updateScroller];
    [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb] forceFilter:NO showFilterDictEdit:NO];

    //rebuild filter views
    if ([cutList count]>0) {
            //rebuild cuts
        for (NSInteger x=0;x<[cutList count];x++) {
            NSValue *cutB = (NSValue *)cutList[x][0];
            NSValue *cutE = (NSValue *)cutList[x][1];
            NSArray *filterInfo = cutList[x][2];
            CMTime start = [cutB CMTimeValue];
            CMTime end = [cutE CMTimeValue];
            
            CGFloat s = centeringOffset +  (float)start.value / (float)start.timescale * thumbSize.width;
            CGFloat e = centeringOffset +  (float)end.value / (float)end.timescale * thumbSize.width;
            
            UIView *cutView = [[UIView alloc] initWithFrame:CGRectMake(s, 0, e - s, scroller.frame.size.height)];
            cutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
            UILabel *l = [[UILabel alloc] initWithFrame:cutView.bounds];
            l.text = [[[GPUFilterTool bag] filterNames] objectAtIndex:[[filterInfo objectAtIndex:0] integerValue]];
            l.textAlignment = NSTextAlignmentCenter;
            l.textColor = [UIColor whiteColor];
            l.font = [UIFont systemFontOfSize:26];
            [cutView addSubview:l];
            cutView.tag = -200;
            [scroller addSubview:cutView];
        }
    } else if (1 == 2) {
        [self buildTestFilters];
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
    
    [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb] forceFilter:NO showFilterDictEdit:YES];
}

-(void)generateLargeThumbnailForTime:(NSValue *)time forceFilter:(BOOL)forceFilter showFilterDictEdit:(BOOL)showDict {
    [largeGenerator cancelAllCGImageGeneration];
    [largeGenerator generateCGImagesAsynchronouslyForTimes:@[ time ] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( (!error) && (result == AVAssetImageGeneratorSucceeded) && image) {
            BOOL found = NO;
            for (NSInteger x=0;x<[cutList count];x++) {
                NSValue *cutB = (NSValue *)cutList[x][0];
                NSValue *cutE = (NSValue *)cutList[x][1];
                NSArray *filterInfo = cutList[x][2];
                CMTime cutDuration = CMTimeSubtract([cutE CMTimeValue], [cutB CMTimeValue]);
                
                if (CMTimeRangeContainsTime(CMTimeRangeMake([cutB CMTimeValue], cutDuration), [time CMTimeValue])) {
                    UIImage *i = [[GPUFilterTool bag] generateImageForCGImage:image withFilterAtIndex:[[filterInfo objectAtIndex:0] integerValue] usingAttributes:[filterInfo objectAtIndex:1]];
                    CGImageRef cgi = i.CGImage;
                    [largeThumbView performSelectorOnMainThread:@selector(setImage:) withObject:(__bridge id)(cgi) waitUntilDone:YES];
                    found = YES;
                    break;
                }
            }

            if (found && showDict) {
                [largeThumbView performSelectorOnMainThread:@selector(setImage:) withObject:(__bridge id)image waitUntilDone:YES];
            } else  if ((hasBeginCut || forceFilter) && (currentFilter > -1)) {
                UIImage *i = [[GPUFilterTool bag] generateImageForCGImage:image withFilterAtIndex:currentFilter usingAttributes:currentFilterDict];
                CGImageRef cgi = i.CGImage;
                [largeThumbView performSelectorOnMainThread:@selector(setImage:) withObject:(__bridge id)(cgi) waitUntilDone:YES];
            } else {
                [largeThumbView performSelectorOnMainThread:@selector(setImage:) withObject:(__bridge id)image waitUntilDone:YES];
            }
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
        endFilterButton.enabled = NO;
        [self updateButtons];
        [currentCutView removeFromSuperview];
        currentCutView = nil;
    }
    
    if ( (CMTimeCompare(lastLargeThumb, secTime) == 0) && (CMTimeCompare(reqLargeThumb, secTime) !=0) ) {
            //do nothing
    } else if (CMTimeCompare(lastLargeThumb, secTime) != 0) {
        reqLargeThumb = secTime;
        NSValue *req = [NSValue valueWithCMTime:reqLargeThumb];
        [self generateLargeThumbnailForTime:req forceFilter:NO showFilterDictEdit:YES];
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
    
    __block NSMutableArray *addList = [[NSMutableArray alloc] initWithCapacity:50];
    
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
    [self performSelector:@selector(reEnableCutScrubberBar) withObject:nil afterDelay:0.25];
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

-(void)buildTestFilters {
    
    
    CMTime startTime = kCMTimeZero;
    
    
    for (int x=0;x<[[GPUFilterTool bag] filterCount];x++) {
        
        NSDictionary *attrs = [[GPUFilterTool bag] attributesForFilterAtIndex:x];
        
        NSMutableDictionary *attrDict = [[NSMutableDictionary alloc] initWithCapacity:3];
       
        for (NSString *s in [attrs allKeys]) {
            NSArray *val = [attrs objectForKey:s];
            [attrDict setObject:[val objectAtIndex:1] forKey:s];
        }

        NSArray *filterInfo = @[ @(x), attrDict];
        NSArray *filter = @[ [NSValue valueWithCMTime:startTime],
                             [NSValue valueWithCMTime:CMTimeAdd(startTime, CMTimeMakeWithSeconds(10, 24))],
                             filterInfo
                             ];
        
        
        [cutList addObject:filter];
        
        startTime = CMTimeAdd(startTime, CMTimeMakeWithSeconds(20, 24));
    }
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    switch (tag) {
        case 1000:
        case 1001:
        {
            NSDictionary *attrs = [[GPUFilterTool bag] attributesForFilterAtIndex:currentFilter];
            NSString *attrName = [[attrs allKeys] objectAtIndex:currentFilterAttrIndex];
            
            NSNumber *curVal = [currentFilterDict objectForKey:attrName];
      
            NSNumber *minAmt = [[attrs objectForKey:attrName] objectAtIndex:0];
            NSNumber *maxAmt = [[attrs objectForKey:attrName] objectAtIndex:2];
            NSNumber *incAmt = [[attrs objectForKey:attrName] objectAtIndex:3];
            
            if (tag == 1000) {
                CGFloat amt = [curVal floatValue] - [incAmt floatValue];
                if (amt < [minAmt floatValue]) {
                    amt = [minAmt floatValue];
                }
                curVal = [NSNumber numberWithFloat:amt];
            } else if (tag == 1001) {
                CGFloat amt = [curVal floatValue] + [incAmt floatValue];
                if (amt > [maxAmt floatValue]) {
                    amt = [maxAmt floatValue];
                }
                curVal = [NSNumber numberWithFloat:amt];
            }
            
            [currentFilterDict setObject:curVal forKey:attrName];
            
            [self updateFilterAttribView];

            [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb] forceFilter:YES showFilterDictEdit:NO];
         
            return;
        }
            break;
        case 1:
        {
           
            if (currentFilter <0) {
                return;
            }
            
            [currentCutView removeFromSuperview];
            currentCutView = nil;
            
            hasBeginCut = YES;
            
            endFilterButton.enabled = YES;
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            beginCut = CMTimeMake(_clip.duration.value * p, _clip.duration.timescale);
            
            float viewXPos = midPos-1 + centeringOffset;
            
            for (NSInteger x=0;x<[cutList count];x++) {
                NSValue *cutB = (NSValue *)cutList[x][0];
                NSValue *cutE = (NSValue *)cutList[x][1];
                NSArray *filterInfo = cutList[x][2];
                CMTime cutDuration = CMTimeSubtract([cutE CMTimeValue], [cutB CMTimeValue]);
                if (CMTimeRangeContainsTime(CMTimeRangeMake([cutB CMTimeValue], cutDuration), beginCut)) {
                    NSValue *cutEchopped = [NSValue valueWithCMTime:CMTimeMake(beginCut.value, beginCut.timescale)];
                    [cutList replaceObjectAtIndex:x withObject:@[ cutB, cutEchopped, filterInfo]];
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
            
            [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb] forceFilter:NO showFilterDictEdit:NO];
            
        }
            break;
        case 2://end
        {
            if (!hasBeginCut) {
                return;
            }
            
            hasBeginCut = NO;
            endFilterButton.enabled = NO;
            
            if (currentFilter <0) {
                return;
            }
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            NSArray *filterInfo = @[ @(currentFilter), currentFilterDict];
            
            [cutList addObject:@[ [NSValue valueWithCMTime:beginCut], [NSValue valueWithCMTime:CMTimeMake(_clip.duration.value * p, _clip.duration.timescale)], filterInfo ]];
                //NSLog(@"added:%@", [cutList lastObject]);
            currentCutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
          
            UILabel *l = [[UILabel alloc] initWithFrame:currentCutView.bounds];
            l.text = [[[GPUFilterTool bag] filterNames] objectAtIndex:currentFilter];
            l.textAlignment = NSTextAlignmentCenter;
            l.textColor = [UIColor whiteColor];
            l.font = [UIFont systemFontOfSize:26];
            [currentCutView addSubview:l];

            currentCutView = nil;
        }
            break;
    }
    
    [self updateView];
}

- (IBAction)userTappedConfirmButton:(id)sender {
    FilterClipConfirmViewController *vc = [[FilterClipConfirmViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"FilterClipConfirmViewController"] bundle:nil];
    vc.clip = _clip;
    vc.cutList = [self sortCutsByBeginTime];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)userTappedStartOverButton:(id)sender {
    hasBeginCut = NO;
    endFilterButton.enabled = NO;
    
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
    startOverButton.enabled = YES;
    [self updateToolbar];
}

-(void)closeAdjustView{
    if (!adjustView) {
        return;
    }
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ adjustView ] ];
    [detailAnimator removeAllBehaviors];
    [detailAnimator addBehavior:gravity];
    [self performSelector:@selector(cleanAdjustView) withObject:nil afterDelay:1.0f];
    startOverButton.enabled = YES;
    [self updateToolbar];
    
    [self updateCutScrubberFrame];
}


-(void)cleanAdjustView {
    
    [detailAnimator removeAllBehaviors];
    detailAnimator = nil;
    
    [adjustView removeFromSuperview];
    adjustView = nil;
 
    [detailView removeFromSuperview];
    detailView = nil;
    
    detailScroller = nil;
}


-(void)cleanDetailView {
    if (!detailView) {
        return;
    }
    [detailAnimator removeAllBehaviors];
    detailAnimator = nil;
    [detailView removeFromSuperview];
    detailView = nil;
    detailScroller = nil;
}


- (IBAction)userTappedSelectButton:(id)sender {
    if (adjustView) {
        filterButton.enabled = NO;
        return;
    }
    
    if (detailView) {
         [self closeDetailView];
    } else {
        
        currentFilterDict = nil;
        currentFilter = -1;
        
        detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        
        CGFloat width = self.view.frame.size.width;
        
        detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - (width / 2.0f), -240, width, 160)];
        detailView.backgroundColor = [UIColor blackColor];
        detailView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        detailView.layer.borderWidth = 2.0f;
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedDetailView:)];
        [detailView addGestureRecognizer:tapG];
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,width,30)];
        l.textAlignment = NSTextAlignmentCenter;
        l.text = @"Select Filter";
        l.textColor = [UIColor blackColor];
        l.backgroundColor = [UIColor whiteColor];
        [detailView addSubview:l];
    
        [self.view addSubview:detailView];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
       
        CGFloat y = detailView.frame.size.height + 36;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            y += 20;
        }
        
        UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ detailView] ];
        [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
        [detailAnimator addBehavior:collision];
        [detailAnimator addBehavior:gravity];
        CMTime *actualTime = nil;
        NSError *error = nil;
        CGImageRef image = [largeGenerator copyCGImageAtTime:lastLargeThumb actualTime:actualTime error:&error];
        if ( (!error) && image) {
            UIImage *i = [UIImage imageWithCGImage:image];
            [[GPUFilterTool bag] generateFilterThumbnailsForUIImage:i];
            CGImageRelease(image);
        } else {
            NSLog(@"large thumbnail generation error:%@", [error localizedDescription]);
        };
        [self updateCutScrubberFrame];

        detailScroller = [[UIScrollView alloc] initWithFrame:CGRectMake(0,(detailView.bounds.size.height / 2.0f) - 55.0f,detailView.bounds.size.width, 135)];
        detailScroller.tag = 42;
        [detailView addSubview:detailScroller];
        
        NSInteger filterCount = [[GPUFilterTool bag] filterCount];
        CGFloat leftEdge = 0.0f;
        for (NSInteger x = 0; x < filterCount;x++) {
            leftEdge = 10 + (x * 160);
            UIImageView *i = [[UIImageView alloc] initWithImage:nil];
            i.contentMode = UIViewContentModeScaleAspectFit;
            i.frame = CGRectMake(leftEdge, 15, 150, 84);
            
            UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedFilter:)];
            [i addGestureRecognizer:tapG];
            i.tag = x;
            i.userInteractionEnabled = YES;
            
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(leftEdge, 115, 150, 15)];
            l.text = [[[GPUFilterTool bag] filterNames] objectAtIndex:x];
            l.textAlignment = NSTextAlignmentCenter;
            l.textColor = [UIColor whiteColor];
            
            [detailScroller addSubview:i];
            [detailScroller addSubview:l];
        }
        
        [detailScroller setContentSize:CGSizeMake( leftEdge + 150, 110)];
    }
}

-(void)addAdjustView {
    adjustView = [[UIView alloc] initWithFrame:CGRectMake(0, -190, self.view.frame.size.width, 190)];
    adjustView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:adjustView];
    
    CGRect tvR = CGRectZero;
    
    if (self.view.frame.size.width <= 480.0f) {
        tvR = CGRectMake(10, 30, 100, 160);
    } else {
        tvR = CGRectMake(10, 30, 150, 160);
    }
    
    UITableView *tv = [[UITableView alloc] initWithFrame:tvR style:UITableViewStylePlain];
    tv.dataSource = self;
    tv.delegate = self;
    [adjustView addSubview:tv];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - (tvR.size.width + 10), tvR.origin.y, tvR.size.width, tvR.size.height)];
    v.backgroundColor = [UIColor whiteColor];
    v.tag = 1000;
    [adjustView addSubview:v];
    
    UILabel *l = nil;
    
    l = [[UILabel alloc] initWithFrame:CGRectMake(0, (v.bounds.size.height / 2.0f) - 10, v.bounds.size.width, 20)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"<-- Tap Attribute";
    l.textColor = [UIColor blackColor];
    l.backgroundColor = [UIColor whiteColor];
    l.tag = 999;
    [v addSubview:l];
    
    
    l = [[UILabel alloc] initWithFrame:CGRectMake(tvR.origin.x, tvR.origin.y - 25, tvR.size.width, 20)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Select Attribute";
    l.textColor = [UIColor blackColor];
    l.backgroundColor = [UIColor whiteColor];
    [adjustView addSubview:l];
    l.layer.cornerRadius = 5;
    l.layer.masksToBounds = YES;
    
    l = [[UILabel alloc] initWithFrame:CGRectMake(v.frame.origin.x, v.frame.origin.y - 25, v.frame.size.width, 20)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = @"Adjust Attribute";
    l.textColor = [UIColor blackColor];
    l.backgroundColor = [UIColor whiteColor];
    [adjustView addSubview:l];
    l.layer.cornerRadius = 5;
    l.layer.masksToBounds = YES;
    
    CGFloat y = v.frame.origin.y - 25;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        y = 80;
    }
    
    l = [[UILabel alloc] initWithFrame:CGRectMake((adjustView.bounds.size.width /2.0f) - 75, y, 150, 40)];
    l.textAlignment = NSTextAlignmentCenter;
    l.text = [[[GPUFilterTool bag] filterNames] objectAtIndex:currentFilter];
    l.textColor = [UIColor blackColor];
    l.backgroundColor = [UIColor whiteColor];
    l.font = [l.font fontWithSize:18];
    [adjustView addSubview:l];
    l.layer.cornerRadius = 5;
    l.layer.masksToBounds = YES;
    
    currentFilterDict = [[NSMutableDictionary alloc] initWithCapacity:3];
    currentFilterAttrIndex = 0;
    
    NSDictionary *attrs = [[GPUFilterTool bag] attributesForFilterAtIndex:currentFilter];
    
    for (NSString *s in [attrs allKeys]) {
        NSArray *val = [attrs objectForKey:s];
        [currentFilterDict setObject:[val objectAtIndex:1] forKey:s];
    }
    
    adjustButton.title = @"Stop Adjusting";
}


-(CGFloat)collisionYOffset {
    CGFloat collisionYOffset = 50;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            collisionYOffset = 60;
        } else {
            collisionYOffset = 160;
        }
    }
    
    return collisionYOffset;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)userTappedAdjustButton:(id)sender {
    if (adjustView) {
        [self closeAdjustView];
        filterButton.enabled = YES;
        return;
    }
    
    filterButton.enabled = NO;
    
    [self addAdjustView];
    
    if (!detailAnimator) {
        detailAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }
    
    NSArray *items = @[ adjustView ];
    if (detailView) {
        items = [items arrayByAddingObject:detailView];
    }
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:items ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ adjustView] ];
    
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,self.view.frame.size.height - [self collisionYOffset]) toPoint:CGPointMake(self.view.frame.size.width,self.view.frame.size.height - [self collisionYOffset])];
    [detailAnimator addBehavior:collision];
    [detailAnimator addBehavior:gravity];

    
    startOverButton.enabled = NO;
    filterButton.enabled = NO;
    
    [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb] forceFilter:YES showFilterDictEdit:NO];
}

-(void)userTappedDetailView:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self closeDetailView];
        filterButton.enabled = YES;
    }
}

-(void)filterGeneratedForThumbnailAtIndex:(NSNotification *)n {
    NSNumber *idx = (NSNumber *)n.object;
    NSInteger idxVal = [idx integerValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIScrollView *s = (UIScrollView *)[detailView viewWithTag:42];
        UIImage *image = [[GPUFilterTool bag] thumbnailForFilterAtIndex:idxVal];
        UIImageView *i = (UIImageView *)[s viewWithTag:idxVal];
        i.image = image;
    });
}

-(void)hasGeneratedFilterThumbnailsForImage:(UIImage *)thumbnail {
   /*
    UIScrollView *s = (UIScrollView *)[detailView viewWithTag:42];
    NSInteger filterCount = [[GPUFilterTool bag] filterCount];
    CGFloat leftEdge = 0.0f;
    for (NSInteger x = 0; x < filterCount;x++) {
        UIImage *image = [[GPUFilterTool bag] thumbnailForFilterAtIndex:x];
        UIImageView *i = (UIImageView *)[s viewWithTag:x];
        i.image = image;
    }
    */
    
}

-(void)userTappedFilter:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger tag = g.view.tag;
            
            beginFilterButton.enabled = YES;
            [self updateButtons];
            currentFilter = tag;
            [self updateToolbar];
            
            
            [self addAdjustView];
            [detailAnimator removeAllBehaviors];
            
            UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView, adjustView ] ];
            [detailAnimator addBehavior:gravity];
            
            UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ adjustView] ];
            
            CGFloat y = self.view.frame.size.height - [self collisionYOffset];
            
            [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.view.frame.size.width,y)];
            [detailAnimator addBehavior:collision];
            [self generateLargeThumbnailForTime:[NSValue valueWithCMTime:lastLargeThumb] forceFilter:YES showFilterDictEdit:NO];
            
        });
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
    UIView *attrView = [adjustView viewWithTag:1000];
    
    while ([attrView.subviews count]>0) {
        UIView *v = [attrView.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
  
    currentFilterAttrIndex = indexPath.row;
    
    
    NSString *optionColorBegin = @"#666666";
    NSString *optionColorEnd = @"#333333";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [UIFont systemFontOfSize:12], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    GradientAttributedButton *button = nil;
    
    button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake((attrView.bounds.size.width / 2.0f) - 40, 10, 80, 50)];
   
     NSAttributedString *buttonTitle =[[NSAttributedString alloc] initWithString:@"+" attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:optionColorBegin endGradientColor:optionColorEnd];
    button.enabled = YES;
    [button update];
    [attrView addSubview:button];
    button.delegate = self;
    button.tag = 1001;

    button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake((attrView.bounds.size.width / 2.0f) - 40, 100, 80, 50)];
    
    buttonTitle =[[NSAttributedString alloc] initWithString:@"-" attributes:strAttr];
    [button setTitle:buttonTitle disabledTitle:buttonTitle beginGradientColorString:optionColorBegin endGradientColor:optionColorEnd];
    button.enabled = YES;
    [button update];
    [attrView addSubview:button];
    button.delegate = self;
    button.tag = 1000;
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, attrView.bounds.size.width, 20)];
    l.textAlignment = NSTextAlignmentCenter;
    l.textColor = [UIColor blackColor];
    l.tag = 998;
    [attrView addSubview:l];
    
    [self updateFilterAttribView];
}

-(void)updateFilterAttribView {
    UIView *attrView = [adjustView viewWithTag:1000];
    UILabel *attrVal = (UILabel *)[attrView viewWithTag:998];
   
    NSDictionary *attrs = [[GPUFilterTool bag] attributesForFilterAtIndex:currentFilter];
    NSString *attrName = [[attrs allKeys] objectAtIndex:currentFilterAttrIndex];
    
    attrVal.text = [NSString stringWithFormat:@"%@", [currentFilterDict objectForKey:attrName]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
   
    NSDictionary *attrs = [[GPUFilterTool bag] attributesForFilterAtIndex:currentFilter];
    
    
    count = [[attrs allKeys] count];
    
	return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    NSDictionary *attrs = [[GPUFilterTool bag] attributesForFilterAtIndex:currentFilter];
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.text = [[attrs allKeys] objectAtIndex:indexPath.row];
    
    return cell;
}

-(NSArray *)sortCutsByBeginTime {
    
    if ([cutList count]<1) {
        return [NSArray array];
    }
    
    
    [cutList sortUsingComparator:^ NSComparisonResult(NSArray *d1, NSArray *d2) {
        CMTime begin1 = [[d1 objectAtIndex:0] CMTimeValue];
        CMTime begin2 = [[d2 objectAtIndex:0] CMTimeValue];
        
        return CMTimeCompare(begin1, begin2);
    }];
    
    return [cutList copy];
}


@end
