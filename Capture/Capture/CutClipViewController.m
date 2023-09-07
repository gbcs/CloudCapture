//
//  CutClipViewController.m
//  Capture
//
//  Created by Gary Barnett on 9/4/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "CutClipViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CutTimelineView.h"
#import "CutConfirmViewController.h"
#import "HelpViewController.h"
#import "ReTimeClipViewController.h"
#import "FilterClipViewController.h"
#import "AppDelegate.h"

@interface CutClipViewController () {
    __weak IBOutlet UIBarButtonItem *startOverButton;
    __weak IBOutlet UIToolbar *toolBar;
  
    __weak IBOutlet UIBarButtonItem *extractAudioButton;
    __weak IBOutlet UIBarButtonItem *savePicButton;
    __weak IBOutlet CutScrubberBar *cutScrubberBar;
    __weak IBOutlet ThumbnailView *largeThumbView;
    __weak IBOutlet UIScrollView *scroller;
    __weak IBOutlet GradientAttributedButton *endCutButton;
    __weak IBOutlet GradientAttributedButton *beginCutButton;
    
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
    
    AVComposition *audioComposition;
    AVAssetExportSession *audioExporter;
    UIDynamicAnimator *animator;
    UIView *detailView;
}

@end

@implementation CutClipViewController

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
    
    savePicButton = nil;
    cutScrubberBar = nil;
    largeThumbView = nil;
    scroller = nil;
    endCutButton = nil;
    beginCutButton = nil;
    
    timelineView = nil;
    
    cutList = nil;
    
    thumbTimes = nil;
    
    thumbIndexes = nil;
    
    generator = nil;
    largeGenerator = nil;
    
    smallTimer = nil;
    
    smallAddList = nil;
    
    currentCutView = nil;
    
    segmentControl = nil;
    audioComposition = nil;
    audioExporter = nil;
    animator = nil;
    detailView = nil;
    
    
}

-(void)userChangedSegment {
    if (segmentControl.selectedSegmentIndex == 2) {
        ReTimeClipViewController *vc = [[ReTimeClipViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"ReTimeClipViewController"] bundle:nil];
        vc.clip = _clip;
        NSMutableArray *vcStack = [self.navigationController.viewControllers mutableCopy];
        [vcStack removeLastObject];
        [vcStack addObject:vc];
        [self.navigationController setViewControllers:[vcStack copy] animated:NO];
    } else if (segmentControl.selectedSegmentIndex == 1) {
        FilterClipViewController *vc = [[FilterClipViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName:@"FilterClipViewController"] bundle:nil];
        vc.clip = _clip;
        NSMutableArray *vcStack = [self.navigationController.viewControllers mutableCopy];
        [vcStack removeLastObject];
        [vcStack addObject:vc];
        [self.navigationController setViewControllers:[vcStack copy] animated:NO];
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
        [segmentControl setSelectedSegmentIndex:0];
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
    
    isiPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.navigationItem.title = @"Edit Clip";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedConfirmButton:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    

    beginCut = CMTimeMake(1,_clip.duration.timescale);

    beginCutButton.enabled = YES;
    endCutButton.enabled = NO;
    
    beginCutButton.delegate = self;
    endCutButton.delegate = self;
    
    beginCutButton.tag = 1;
    endCutButton.tag = 2;

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
- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)userTappedHelpButton:(id)sender {
    HelpViewController *configureVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    configureVC.backOnly = YES;
    [self.navigationController pushViewController:configureVC animated:YES];
}

- (IBAction)userTappedSavePictureButton:(id)sender {
    savePicButton.enabled = NO;
    AVAssetTrack *track = [[_clip tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    [largeGenerator setMaximumSize:[track naturalSize]];
    
    [largeGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:lastLargeThumb] ] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        [[UtilityBag bag] saveCGImageAsPicture:image];
       
        dispatch_async(dispatch_get_main_queue(), ^{
             [largeGenerator setMaximumSize:largeThumbView.bounds.size];
            savePicButton.enabled = YES;
        });
    }];
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
    
    
    if ([[SettingsTool settings] isOldDevice]) {
 // if ([[SettingsTool settings] isiPhone4S] || [[SettingsTool settings] isOldDevice]) {
        self.navigationItem.title = @"Cut Clip";
     } else {
        self.navigationItem.titleView = segmentControl;
     }
}

-(void)updateButtons {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    
    NSAttributedString *sActive = [[NSAttributedString alloc] initWithString:@"Start Cut" attributes:@{
                                                                                                   NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                                   NSShadowAttributeName : shadow,
                                                                                                   NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                   }];
    
    
    NSAttributedString *eActive = [[NSAttributedString alloc] initWithString:@"End Cut" attributes:@{
                                                                                                 NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                 NSShadowAttributeName : shadow,
                                                                                                 NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                 }];
    
    if (beginCutButton.enabled) {
        [beginCutButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#009900" endGradientColor:@"#006600"];
    } else {
        [beginCutButton setTitle:sActive disabledTitle:sActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    if (endCutButton.enabled) {
        [endCutButton setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#3333FF" endGradientColor:@"#0000FF"];
    } else {
        [endCutButton setTitle:eActive disabledTitle:eActive beginGradientColorString:@"#CCCCCC" endGradientColor:@"#999999"];
    }
    
    [beginCutButton update];
    [endCutButton update];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    endCutButton.enabled = NO;
    [self updateView];
    
    [thumbTimes removeAllObjects];
    [thumbIndexes removeAllObjects];
    [generator cancelAllCGImageGeneration];
    [smallAddList removeAllObjects];
    [self generateTimeline];
    lastKnownTimerSecond = -1;
    [scroller setContentOffset:CGPointMake(0,0)];

}

-(void)generateTimeline {
    seconds = CMTimeGetSeconds(_clip.duration);
  
    NSArray *sv = scroller.subviews;
    for (UIView *v in sv) {
        [v removeFromSuperview];
    }
    
    cutScrubberBar.frame = CGRectMake(0,cutScrubberBar.frame.origin.y,self.view.frame.size.width, 44);
    
    scroller.frame = CGRectMake(0,scroller.frame.origin.y,self.view.frame.size.width, thumbSize.height + 14);
    
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
    
    if ([cutList count]>0) {
        //rebuild cuts
        for (NSInteger x=0;x<[cutList count];x++) {
            NSValue *cutB = (NSValue *)cutList[x][0];
            NSValue *cutE = (NSValue *)cutList[x][1];
          
            CMTime start = [cutB CMTimeValue];
            CMTime end = [cutE CMTimeValue];
            
            CGFloat s = centeringOffset +  (float)start.value / (float)start.timescale * thumbSize.width;
            CGFloat e = centeringOffset +  (float)end.value / (float)end.timescale * thumbSize.width;
            
            UIView *cutView = [[UIView alloc] initWithFrame:CGRectMake(s, 0, e - s, scroller.frame.size.height)];
            cutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
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
                //NSLog(@"DeliveredLarge:%@", [NSValue valueWithCMTime:requestedTime]);
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
        endCutButton.enabled = NO;
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
                            //NSLog(@"generatedsmall:%d:%@", v.tag, [NSValue valueWithCGRect:v.frame]);
                        [scroller insertSubview:v belowSubview:timelineView];
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
    switch (tag) {
        case 1:
        {
            [currentCutView removeFromSuperview];
            currentCutView = nil;
            
            hasBeginCut = YES;
            
            endCutButton.enabled = YES;
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            beginCut = CMTimeMake(_clip.duration.value * p, _clip.duration.timescale);
           
            float viewXPos = midPos-1 + centeringOffset;
            
            for (NSInteger x=0;x<[cutList count];x++) {
                NSValue *cutB = (NSValue *)cutList[x][0];
                NSValue *cutE = (NSValue *)cutList[x][1];
                CMTime cutDuration = CMTimeSubtract([cutE CMTimeValue], [cutB CMTimeValue]);
                
                if (CMTimeRangeContainsTime(CMTimeRangeMake([cutB CMTimeValue], cutDuration), beginCut)) {
                    NSValue *cutEchopped = [NSValue valueWithCMTime:CMTimeMake(beginCut.value, beginCut.timescale)];
                    [cutList replaceObjectAtIndex:x withObject:@[ cutB, cutEchopped]];
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
            endCutButton.enabled = NO;
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            [cutList addObject:@[ [NSValue valueWithCMTime:beginCut], [NSValue valueWithCMTime:CMTimeMake(_clip.duration.value * p, _clip.duration.timescale)]]];
            NSLog(@"added:%@", [cutList lastObject]);
            currentCutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
            currentCutView = nil;
            
            
        }
            break;
    }
    
    [self updateView];
}

- (IBAction)userTappedConfirmButton:(id)sender {
    CutConfirmViewController *vc = [[CutConfirmViewController alloc] initWithNibName:[[UtilityBag bag] deviceTypeSpecificNibName: @"CutConfirmViewController"] bundle:nil];
    vc.clip = _clip;
    vc.cutList = [cutList copy];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)userTappedStartOverButton:(id)sender {
    hasBeginCut = NO;
    endCutButton.enabled = NO;
    
    for (UIView *v in scroller.subviews) {
        if (v.tag == -200) {
            [v removeFromSuperview];
        }
    }
    
    currentCutView = nil;
    
    [cutList removeAllObjects];

    [self updateView];
}

- (IBAction)userTappedExtractAudioButton:(id)sender {
    //create an m4a from the audio in track 0
   
    if ([[_clip tracksWithMediaType:AVMediaTypeAudio] count]>0) {
        [self extractAudio:_clip];
    } else {
        extractAudioButton.enabled = NO;
    }
}

-(void)extractAudio:(AVURLAsset *)asset {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    AppDelegate *appD = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appD.allowRotation = NO;
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    NSError *editError;
    CMTime begin = CMTimeMake(1,asset.duration.timescale);
    
    AVMutableCompositionTrack *audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    BOOL error = NO;
    
    [audioTrack insertTimeRange:CMTimeRangeMake(begin, asset.duration) ofTrack:clipAudioTrack atTime:begin error:&editError];
    
    if (editError) {
        error = YES;
    }
    
    if(error) {
        NSLog(@"adderr:%@", [editError localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clip Error" message:@"Unable to access existing clip." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    audioComposition  = [mutableComposition copy];
    
    NSString *audioFname = [[UtilityBag bag] pathForNewResourceWithExtension:@"m4a"];
    NSString *audioPath = [[[UtilityBag bag] docsPath] stringByAppendingPathComponent:audioFname];
    NSURL *movieURL = [NSURL fileURLWithPath:audioPath];
    
    audioExporter = [[AVAssetExportSession alloc] initWithAsset:audioComposition presetName:AVAssetExportPresetAppleM4A];
    audioExporter.outputFileType=AVFileTypeAppleM4A;
    audioExporter.outputURL=movieURL;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *originalTimeStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *originalLoc = @"";
    NSString *originalTitle = @"";
    
    NSArray *originalMetadata = [asset metadataForFormat:@"com.apple.quicktime.mdta"];
    for (AVMutableMetadataItem *a in originalMetadata) {
        if ([a.commonKey isEqualToString:@"creationDate"]) {
            originalTimeStr = (NSString *)a.value;
        } else if ([a.commonKey isEqualToString:@"location"]) {
            originalLoc = (NSString *)a.value;
        } else if ([a.commonKey isEqualToString:@"title"]) {
            originalTitle = (NSString *)a.value;
        }
    }
    
    NSMutableArray *metadata = [[NSMutableArray alloc] initWithCapacity:3];
    
    AVMutableMetadataItem *item = nil;
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.key = AVMetadataCommonKeyCreationDate;
    item.value = originalTimeStr;
    [metadata addObject:item];
    
    if ([[SettingsTool settings] useGPS] && originalLoc && ([originalLoc length] >0) ) {
        item = [[AVMutableMetadataItem alloc] init];
        item.keySpace = AVMetadataKeySpaceCommon;
        item.key = AVMetadataCommonKeyLocation;
        item.value = originalLoc;
        [metadata addObject:item];
    }
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceQuickTimeUserData;
    item.key = AVMetadataQuickTimeUserDataKeyTrack;
    item.value = [NSNumber numberWithInt:1];
    [metadata addObject:item];
    
    item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.locale = [NSLocale currentLocale];
    item.key = AVMetadataCommonKeyTitle;
    item.value = [NSString stringWithFormat:@"%@[audio]", originalTitle];
    [metadata addObject:item];
    
    
    AVMutableMetadataItem *descUID = [[UtilityBag bag] uniqueMetadataEntry];
    [metadata addObject:descUID];
    
    audioExporter.metadata = [metadata copy];
    
    audioExporter.timeRange=CMTimeRangeFromTimeToTime(CMTimeMake(1,audioComposition.duration.timescale), audioComposition.duration);
    
    detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 200, -270, 400, 220)];
    detailView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
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
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activity.frame = CGRectMake(180,160,40,40);
    [detailView addSubview:activity];
    [activity startAnimating];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,60,400,40)];
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont boldSystemFontOfSize:20];
    l.textColor = [UIColor whiteColor];
    l.text = @"Processing";
    l.tag = 100;
    [detailView addSubview:l];
    
    [audioExporter exportAsynchronouslyWithCompletionHandler:^{
        UILabel *processingLabel = (UILabel *)[detailView viewWithTag:100];
        switch ([audioExporter status]) {
            case AVAssetExportSessionStatusFailed:
            {
                NSLog(@"Export failed: %@ %@", [[audioExporter error] localizedDescription],[[audioExporter error]debugDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    processingLabel.text = @"Failed";
                    [self performSelectorOnMainThread:@selector(closeExportProgress:) withObject:@(NO) waitUntilDone:NO];
                });
            }
                break;
            case AVAssetExportSessionStatusCancelled:{
                NSLog(@"Export canceled");
                dispatch_async(dispatch_get_main_queue(), ^{
                    processingLabel.text = @"Cancelled";
                });
                [self performSelectorOnMainThread:@selector(closeExportProgress:) withObject:@(NO) waitUntilDone:NO];
                break;
            }
            case AVAssetExportSessionStatusCompleted:
            {
                [self performSelectorOnMainThread:@selector(closeExportProgress:) withObject:@(YES) waitUntilDone:NO];
            }
        }
    }];
}

-(void)closeExportProgress:(NSNumber *)status {
    UILabel *l = (UILabel *)[detailView viewWithTag:100];
    if ([status boolValue] == YES) {
        l.text = @"Finished";
    } else {
        l.text = @"Failed";
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
            [animator removeAllBehaviors];
            [animator addBehavior:gravity];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [NSThread sleepForTimeInterval:1.5];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [animator removeAllBehaviors];
                    animator = nil;
                    [detailView removeFromSuperview];
                    detailView = nil;
                });
            });
            
        });
    });
}


@end
