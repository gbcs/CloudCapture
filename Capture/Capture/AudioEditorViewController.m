//
//  AudioEditorViewController.m
//  Capture
//
//  Created by Gary Barnett on 12/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "AudioEditorViewController.h"
#import "CutTimelineView.h"
#import "AudioEditorConfirmViewController.h"
#import "AudioMergeConfirmViewController.h"
#import "AudioVolumeConfirmViewController.h"
#import "AudioVolumeEditView.h"
#import "AudioMergeEditView.h"


@interface AudioEditorViewController () {
   
    __weak IBOutlet CutScrubberBar *cutScrubberBar;
    __weak IBOutlet UIScrollView *scroller;
    __weak IBOutlet GradientAttributedButton *endCutButton;
    __weak IBOutlet GradientAttributedButton *beginCutButton;
    
    UIBarButtonItem *startOverButton;
    UIBarButtonItem *playButton;
    
    AudioWaveformHandler *waveformHandler;
    CutTimelineView *timelineView;
    
    BOOL hasBeginCut;
    
    CMTime beginCut;
    
    CMTime duration;
    
    NSMutableArray *cutList;
    
    CGSize thumbSize;
    
    float centeringOffset;
    
    NSInteger seconds;
    
    NSInteger currentSecond;
    
    UIView *currentCutView;
 
    BOOL isReady;
    
    AVAudioPlayer *audioPlayer;
    NSTimer *playTimer;
    
    UILabel *insertClipLabel;
    UILabel *audioLevelLabel;
    UISlider *audioLevelSlider;

    UILabel *transitionLabel;
    
    UIBarButtonItem *durationButton;
    
    GradientAttributedButton *rampIn;
    GradientAttributedButton *cutIn;
    GradientAttributedButton *rampOut;
    GradientAttributedButton *cutOut;
    
    UIDynamicAnimator *animator;
    UIView *detailView;
    NSInteger lastMode;
    
    NSMutableArray *volumeList;
    NSMutableArray *mergeList;
    AVURLAsset *mergeURLAsset;
    BOOL pickingFile;
}

@end

@implementation AudioEditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       thumbSize = CGSizeMake(60,48);
    }
    return self;
}

-(void)userPickedAudioURL:(AVURLAsset *)urlAsset  withTitle:(NSString *)title {
    mergeURLAsset = urlAsset;
    insertClipLabel.text = title;
}

-(void)updateDurationButton {
    NSString *durationTitle = [NSString stringWithFormat:@"Ramp Duration: %02.1fs", [[[SettingsTool settings] audioEditRampDuration] floatValue]];
    [durationButton setTitle:durationTitle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.navigationItem.title = @"Audio Editor";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedConfirmButton:)];
    
    
    cutList = [@[] mutableCopy];
    volumeList = [@[] mutableCopy];
    mergeList = [@[] mutableCopy];
    
    self.navigationController.toolbarHidden = NO;
    
    startOverButton = [[UIBarButtonItem alloc] initWithTitle:@"Start Over" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedStartOver)];
    playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(userTappedPlay)];
    
    durationButton = [[UIBarButtonItem alloc] initWithTitle:@"Ramp Duration" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedDurationButton)];
    
    
    self.toolbarItems = @[ startOverButton,
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil],
                           playButton,
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil]
                           ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:@"cleanupAudioEditor" object:nil];
    
    beginCut = CMTimeMake(1,_asset.duration.timescale);
    
    beginCutButton.enabled = YES;
    endCutButton.enabled = NO;
    
    beginCutButton.delegate = self;
    endCutButton.delegate = self;
    
    beginCutButton.tag = 1;
    endCutButton.tag = 2;
    
    
    beginCutButton.enabled = NO;
    playButton.enabled = NO;
    [self updateButtons];
    
    
    UISegmentedControl *seg =[[UISegmentedControl alloc] initWithItems:@[ @"Cut" , @"Volume", @"Merge"] ];
    [seg addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventValueChanged];
    seg.selectedSegmentIndex = 0;
    self.navigationItem.titleView = seg;
}

-(void)updateTransitionButtons {
    
    [cutIn removeFromSuperview];
    cutIn = nil;
    
    [cutOut removeFromSuperview];
    cutOut = nil;
    
    [rampIn removeFromSuperview];
    rampIn = nil;
    
    [rampOut removeFromSuperview];
    rampOut = nil;

    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    CGFloat l = beginCutButton.frame.origin.x + beginCutButton.frame.size.width;
    CGFloat y = beginCutButton.frame.origin.y;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y += 50;
    }

    
    
    NSAttributedString *cutInStr = [[NSAttributedString alloc] initWithString:@"Cut In" attributes:@{
                                                                                                     NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]-1],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }];
    
    NSAttributedString *rampInStr = [[NSAttributedString alloc] initWithString:@"Ramp In" attributes:@{
                                                                                                       NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]-1],
                                                                                                       NSShadowAttributeName : shadow,
                                                                                                       NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                       }];
    
    NSAttributedString *cutOutStr = [[NSAttributedString alloc] initWithString:@"Cut Out" attributes:@{
                                                                                                       NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]-1],
                                                                                                       NSShadowAttributeName : shadow,
                                                                                                       NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                       }];
    
    NSAttributedString *rampOutStr = [[NSAttributedString alloc] initWithString:@"Ramp Out" attributes:@{
                                                                                                         NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]-1],
                                                                                                         NSShadowAttributeName : shadow,
                                                                                                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                         }];
    
    cutIn = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(l - 100, y + 69, 85, 40)];
    rampIn = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(l - 20, y + 69, 85, 40)];
    
    cutOut = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(endCutButton.frame.origin.x + endCutButton.frame.size.width - 85, y + 69, 85, 40)];
    rampOut = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(endCutButton.frame.origin.x + endCutButton.frame.size.width - 165, y + 69, 85, 40)];
    
    cutIn.enabled = YES;
    cutIn.delegate = self;
    cutIn.tag = 1000;
    
    NSString *bgColorSel = @"#009900";
    NSString *bgColor = @"#444444";
    
    NSString *endColorSel = @"#006600";
    NSString *endColor = @"#111111";
    
    NSInteger transIn = [[[SettingsTool settings] audioEditTransitionIn] integerValue];
    NSInteger transOut = [[[SettingsTool settings] audioEditTransitionOut] integerValue];
    
    
    [cutIn setTitle:cutInStr disabledTitle:cutInStr beginGradientColorString:transIn == 0 ? bgColorSel : bgColor endGradientColor:transIn == 0 ? endColorSel : endColor ];
    [beginCutButton update];
    
    cutOut.enabled = YES;
    cutOut.delegate = self;
    cutOut.tag = 1002;[cutOut setTitle:cutOutStr disabledTitle:cutOutStr beginGradientColorString:transOut == 0 ? bgColorSel : bgColor endGradientColor:transOut == 0 ? endColorSel : endColor];
    [cutOut update];
    
    rampIn.enabled = YES;
    rampIn.delegate = self;
    rampIn.tag = 1001;[rampIn setTitle:rampInStr disabledTitle:rampInStr beginGradientColorString:transIn == 1 ? bgColorSel : bgColor endGradientColor:transIn == 1 ? endColorSel : endColor];
    [rampIn update];
    
    rampOut.enabled = YES;
    rampOut.delegate = self;
    rampOut.tag = 1003;[rampOut setTitle:rampOutStr disabledTitle:rampOutStr beginGradientColorString:transOut == 1 ? bgColorSel : bgColor endGradientColor:transOut == 1 ? endColorSel : endColor];
    [rampOut update];
    
    [self.view addSubview:cutIn];
    [self.view addSubview:cutOut];
    [self.view addSubview:rampIn];
    [self.view addSubview:rampOut];

}

-(void)updateModeUI:(UISegmentedControl *)seg {
    [insertClipLabel removeFromSuperview];
    [audioLevelLabel removeFromSuperview];
    [audioLevelSlider removeFromSuperview];
    [transitionLabel removeFromSuperview];
    
    insertClipLabel = nil;
    audioLevelLabel = nil;
    audioLevelSlider = nil;
    transitionLabel = nil;
    
    [cutIn removeFromSuperview];
    cutIn = nil;
    
    [cutOut removeFromSuperview];
    cutOut = nil;
    
    [rampIn removeFromSuperview];
    rampIn = nil;
    
    [rampOut removeFromSuperview];
    rampOut = nil;
    
    CGFloat l = beginCutButton.frame.origin.x + beginCutButton.frame.size.width;
    CGFloat w = endCutButton.frame.origin.x - l;
    CGFloat y = beginCutButton.frame.origin.y;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y += 50;
    }
    
    self.toolbarItems = @[ startOverButton,
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil],
                           playButton,
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil]
                           ];
    
    if (seg.selectedSegmentIndex == 1) {
        transitionLabel = [[UILabel alloc] initWithFrame:CGRectMake(l, y + 75, w, 25)];
        transitionLabel.backgroundColor = [UIColor clearColor];
        transitionLabel.textColor = [UIColor whiteColor];
        transitionLabel.textAlignment = NSTextAlignmentCenter;
        transitionLabel.text = @"Transition";
        [self.view addSubview:transitionLabel];
        [self updateTransitionButtons];
    }
    
    if (seg.selectedSegmentIndex == 0) {
        beginCutButton.enabled = YES;
        endCutButton.enabled = NO;
    } else {
        beginCutButton.enabled = YES;
        endCutButton.enabled = YES;
       
        if (seg.selectedSegmentIndex == 2) {
            CGFloat labelY = y + (beginCutButton.frame.size.height / 2.0f) - 50;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                labelY -= 50;
            }
            insertClipLabel = [[UILabel alloc] initWithFrame:CGRectMake(l, labelY, w, 40)];
            insertClipLabel.backgroundColor = [UIColor clearColor];
            insertClipLabel.textColor = [UIColor whiteColor];
            insertClipLabel.textAlignment = NSTextAlignmentCenter;
            insertClipLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            insertClipLabel.text = @"<select file>";
            [self.view addSubview:insertClipLabel];
        } else {
            audioLevelLabel = [[UILabel alloc] initWithFrame:CGRectMake(l, y + 45, w, 25)];
            audioLevelLabel.backgroundColor = [UIColor clearColor];
            audioLevelLabel.textColor = [UIColor whiteColor];
            audioLevelLabel.textAlignment = NSTextAlignmentCenter;
            [self updateAudioLevelLabel];
            [self.view addSubview:audioLevelLabel];
            audioLevelSlider = [[UISlider alloc] initWithFrame:CGRectMake(l, y + 14, w, 40)];
            audioLevelSlider.minimumValue = 0.0f;
            audioLevelSlider.maximumValue = 1.0f;
            audioLevelSlider.value = [[[SettingsTool settings] audioEditVolume] floatValue];
            [audioLevelSlider addTarget:self action:@selector(audioLevelSliderChanged:) forControlEvents:UIControlEventValueChanged];
            [self.view addSubview:audioLevelSlider];
            self.toolbarItems = [self.toolbarItems arrayByAddingObject:durationButton];
            [self updateDurationButton];

        }
    }
    [self updateButtons];
}

-(void)changeMode:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    
    if (lastMode != seg.selectedSegmentIndex) {
        NSArray *vList = scroller.subviews;
        for (UIView *v in vList) {
            if (v.tag == -200) {
                [v removeFromSuperview];
            }
        }
        
        currentCutView = nil;
        hasBeginCut = NO;
        
        [cutList removeAllObjects];
        [volumeList removeAllObjects];
        [mergeList removeAllObjects];
    }
    
    [self updateModeUI:seg];
    lastMode = seg.selectedSegmentIndex;
}

-(void)audioLevelSliderChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [[SettingsTool settings] setAudioEditVolume:@(slider.value)];
    [self updateAudioLevelLabel];
}

-(void)updateAudioLevelLabel {
    audioLevelLabel.text = [NSString stringWithFormat:@"%.0f%%", [[[SettingsTool settings] audioEditVolume] floatValue] * 100.0f];
}

-(void)dealloc {
    [self cleanup:nil];
}

-(void)cleanup:(NSNotification *)n {
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }

    cutScrubberBar = nil;
    scroller = nil;
    endCutButton = nil;
    beginCutButton = nil;
    startOverButton = nil;
    playButton = nil;
    waveformHandler = nil;
    timelineView = nil;
    cutList = nil;
    volumeList = nil;
    mergeList = nil;
    currentCutView = nil;
    audioPlayer = nil;
    playTimer = nil;
    _asset = nil;
    
    insertClipLabel = nil;
    audioLevelLabel = nil;
    audioLevelSlider = nil;
    
}


-(void)userTappedCancel {
    [[AssetManager manager] cleanupMoviePhotosTemp];
    [self.navigationController popViewControllerAnimated:YES];
    [self cleanup:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!isReady) {
        [self updateView];
    }
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!isReady) {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.frame = CGRectMake((self.view.frame.size.width / 2.0f) - 50, scroller.frame.origin.y + 5.0, 40, 40);
        activity.tag = -50000;
        [self.view addSubview:activity];
        [activity startAnimating];
        [self performSelector:@selector(generateTimeline) withObject:nil afterDelay:0.1];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)showSampleAtIndex:(NSInteger)idx offset:(NSInteger)offset {
    NSString *filename = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld_%ld.sampleView", (long)idx, (long)offset]];
    
    UIImage *i = [UIImage imageWithContentsOfFile:filename];
    
    if ( (!i) || (i.size.width == 0.0f) ){
        return;
    }
    
    UIImageView *v = [[UIImageView alloc] initWithImage:i];
    v.frame = CGRectMake(centeringOffset + (offset * 5000),14,v.image.size.width, v.image.size.height);
    v.tag = offset + 5000;
    //v.layer.borderColor = [UIColor whiteColor].CGColor;
    //v.layer.borderWidth = 2;
    [scroller addSubview:v];
        //NSLog(@"showSampleAtIndex:%@:w:%@:h:%@", @(offset), @(v.frame.size.width), @(v.frame.size.height));
}

-(void)sampleIsReady:(NSNumber *)idx {
    [waveformHandler cleanup];
    waveformHandler = nil;
    
    isReady = YES;
    UIActivityIndicatorView *v = (UIActivityIndicatorView *)[self.view viewWithTag:-50000];
    [v stopAnimating];
    [v removeFromSuperview];
    
    [self showSampleAtIndex:[idx integerValue] offset:0];
    
    scroller.hidden = NO;
    cutScrubberBar.hidden = NO;
    beginCutButton.enabled = YES;
    playButton.enabled = YES;
    [self updateButtons];
}

-(void)updateToolbar {
    startOverButton.enabled = hasBeginCut || ([cutList count] > 0) || ([volumeList count] >0) || ([mergeList count]>0);
    self.navigationItem.rightBarButtonItem.enabled =  ([cutList count] > 0) || ([volumeList count] >0) || ([mergeList count]>0);
}

-(void)viewDidDisappear:(BOOL)animated {
    if (!pickingFile) {
        [self removeTimeline];
    } else {
        pickingFile = NO;
    }
    [super viewDidDisappear:animated];
}

-(void)updateButtons {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    NSAttributedString *sActive = nil;
    
    
    NSAttributedString *eActive = nil;
    
    UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.titleView;
    
    switch (seg.selectedSegmentIndex) {
        case 0:
        {
            sActive = [[NSAttributedString alloc] initWithString:@"Start Cut" attributes:@{
                                                                                           NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                           NSShadowAttributeName : shadow,
                                                                                           NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                           }];
            
            eActive = [[NSAttributedString alloc] initWithString:@"End Cut" attributes:@{
                                                                                         NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                         NSShadowAttributeName : shadow,
                                                                                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                         }];
            

        }
            break;
        case 1:
        {
            sActive = [[NSAttributedString alloc] initWithString:@"Start Volume" attributes:@{
                                                                                           NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                           NSShadowAttributeName : shadow,
                                                                                           NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                           }];
            
            eActive = [[NSAttributedString alloc] initWithString:@"End Volume" attributes:@{
                                                                                         NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                         NSShadowAttributeName : shadow,
                                                                                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                         }];
            

        }
            break;
        case 2:
        {
            sActive = [[NSAttributedString alloc] initWithString:@"Merge Clip" attributes:@{
                                                                                           NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]],
                                                                                           NSShadowAttributeName : shadow,
                                                                                           NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                           }];
            
            eActive = [[NSAttributedString alloc] initWithString:@"Select Clip" attributes:@{
                                                                                         NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                         NSShadowAttributeName : shadow,
                                                                                         NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                         }];
            

        }
            break;
    }
    
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
    float oldOffset = centeringOffset;
    
    centeringOffset = (scroller.bounds.size.width / 2.0f);
    
    float f = oldOffset - centeringOffset;
    
    for (UIView *v in scroller.subviews) {
        CGRect r = v.frame;
        v.frame = CGRectMake(r.origin.x - f, r.origin.y, r.size.width, r.size.height);
    }
    
    [self updateButtons];
    [self updateModeUI:(UISegmentedControl *)self.navigationItem.titleView];
    
}

-(void)generateTimeline {
    seconds = CMTimeGetSeconds(_asset.duration);
    
    centeringOffset = (scroller.bounds.size.width / 2.0f);
    
    cutScrubberBar.frame = CGRectMake(0,44,self.view.frame.size.width, 44);
    
    scroller.frame = CGRectMake(0,88,self.view.frame.size.width, thumbSize.height + 14);
    
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
    
    currentSecond = 0;
    
    [self updateScroller];
    
    waveformHandler = [[AudioWaveformHandler alloc] init];
    [waveformHandler processSamplesForAudioTrack:_asset samplesPerSecond:thumbSize.width forIndex:1 withDelegate:self];

    
}

-(void)removeTimeline {
    [timelineView removeFromSuperview];
    timelineView = nil;
    
    [currentCutView removeFromSuperview];
    currentCutView = nil;
    
    while ([scroller.subviews count]>0) {
        UIView *v = [scroller.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    [waveformHandler cleanup];
    waveformHandler = nil;
    [cutList removeAllObjects];

    [mergeList removeAllObjects];
    [volumeList removeAllObjects];
    
    isReady = NO;
}

-(float)scrollerMidPos {
    return scroller.contentOffset.x - centeringOffset + (scroller.frame.size.width / 2.0f);
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    float midPos = [self scrollerMidPos];
    
    float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
    
    currentSecond = seconds * p;
    [cutScrubberBar updatePosition:currentSecond];
    [self updateScroller];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.titleView;
    
    
    float midPos =  [self scrollerMidPos];
    float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
    
    currentCutView.frame = CGRectMake(currentCutView.frame.origin.x, 0, midPos + centeringOffset - currentCutView.frame.origin.x, currentCutView.frame.size.height);
    
    currentSecond = seconds * p;
    
    CMTime secTime = CMTimeMake((_asset.duration.value * p) + 1 , _asset.duration.timescale);
    
    if (hasBeginCut && (CMTimeCompare(secTime, beginCut) == -1) ) {
        hasBeginCut = NO;
        beginCut = kCMTimeZero;
        endCutButton.enabled = (seg.selectedSegmentIndex == 2) ? YES : NO;
        [self updateButtons];
        [currentCutView removeFromSuperview];
        currentCutView = nil;
    }
    
    [cutScrubberBar updatePosition:currentSecond];
    [self updateScroller];
}


-(void)updateScroller {
    NSInteger currentPage = (currentSecond * 60) / 5000;
        //NSLog(@"current=%ld", (long)currentPage);
    currentPage += 5000;
    
    NSArray *a = scroller.subviews;
    
    BOOL foundCurrent = NO;
    BOOL foundPrev = NO;
    BOOL foundNext = NO;
    
    for (UIView *v in a) {
        if (v.tag == currentPage) {
            foundCurrent = YES;
        } else if (v.tag == currentPage - 1) {
            foundPrev = YES;
        } else if (v.tag == currentPage + 1) {
            foundNext = YES;
        } else if (v.tag >= 5000) {
            [v removeFromSuperview];
        }
    }
    
    if (!foundCurrent) {
        [self showSampleAtIndex:1 offset:currentPage- 5000];
    }
    
    if ((currentPage > 5000) && (!foundPrev)) {
        [self showSampleAtIndex:1 offset:currentPage - 5000 - 1];
    }

    if (!foundNext) {
        [self showSampleAtIndex:1 offset:currentPage - 5000  + 1];
    }

}

-(void)updateView {
    [self updateButtons];
    [self updateToolbar];
}

-(void)userDidBeginScrubberPress {
    scroller.hidden = YES;
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
     UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.titleView;
    
     switch (tag) {
        case 1:
        {
            if (seg.selectedSegmentIndex == 2) {
                if (!mergeURLAsset) {
                    return;
                }
            }
            
            [currentCutView removeFromSuperview];
            currentCutView = nil;
            
            hasBeginCut = YES;
            
            endCutButton.enabled = YES;
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            beginCut = CMTimeMake(_asset.duration.value * p, _asset.duration.timescale);
            
            float viewXPos = midPos-1 + centeringOffset;
            
            switch (seg.selectedSegmentIndex) {
                case 0:
                {
                    for (NSInteger x=0;x<[cutList count];x++) {
                        NSValue *cutB = (NSValue *)cutList[x][0];
                        NSValue *cutE = (NSValue *)cutList[x][1];
                        
                        if (CMTimeRangeContainsTime(CMTimeRangeMake([cutB CMTimeValue], [cutE CMTimeValue]), beginCut)) {
                            NSValue *cutEchopped = [NSValue valueWithCMTime:CMTimeMake(beginCut.value, beginCut.timescale)];
                            [cutList replaceObjectAtIndex:x withObject:@[ cutB, cutEchopped]];
                            for (UIView *v in scroller.subviews) {
                                if (v.tag != -200) {
                                    continue;
                                }
                                if ( (v.frame.origin.x < viewXPos) && (v.frame.origin.x + v.frame.size.width >= viewXPos) ){
                                    v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, viewXPos - v.frame.origin.x, v.frame.size.height);
                                }
                            }
                        }
                    }
                }
                    break;
                case 1:
                {
                    for (NSInteger x=0;x<[volumeList count];x++) {
                        NSValue *cutB = (NSValue *)volumeList[x][0];
                        NSValue *cutE = (NSValue *)volumeList[x][1];
           
                        if (CMTimeRangeContainsTime(CMTimeRangeFromTimeToTime([cutB CMTimeValue], [cutE CMTimeValue]), beginCut)) {
                            cutE = [NSValue valueWithCMTime:CMTimeSubtract(beginCut, CMTimeMake(1, beginCut.timescale))];
                            [volumeList replaceObjectAtIndex:x withObject:@[ cutB, cutE, volumeList[x][2], volumeList[x][3], volumeList[x][4], volumeList[x][5] ]];
                        } else if (CMTimeCompare(beginCut, [cutE CMTimeValue]) == NSOrderedAscending) {
                            [volumeList removeObjectAtIndex:x];
                            x--;
                            if ([volumeList count] < x+1) {
                                break;
                            }
                            continue;
                        }
                    }
                    for (UIView *v in scroller.subviews) {
                        if (v.tag != -200) {
                            continue;
                        }
                        
                        if ( (v.frame.origin.x > viewXPos) ){
                            [v removeFromSuperview];
                        } else if ( (v.frame.origin.x < viewXPos) && (v.frame.origin.x + v.frame.size.width >= viewXPos) ){
                            v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, viewXPos - v.frame.origin.x, v.frame.size.height);
                            AudioVolumeEditView *v2 = (AudioVolumeEditView *)v;
                            [v2 update];
                        } else {
                            AudioVolumeEditView *v2 = (AudioVolumeEditView *)v;
                            [v2 update];
                        }
              
                        
                    }
                }
                    break;
                case 2:
                {
                    currentCutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
                    hasBeginCut = NO;
                    endCutButton.enabled = (seg.selectedSegmentIndex == 2) ? YES : NO;
                    
                }
                    break;
            }
            
            
            switch (seg.selectedSegmentIndex) {
                case 0:
                {
                     currentCutView = [[UIView alloc] initWithFrame:CGRectMake(midPos-1 + centeringOffset, 0,2, scroller.frame.size.height)];
                     currentCutView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
                }
                    break;
                case 1:
                {
                     currentCutView = [[AudioVolumeEditView alloc] initWithFrame:CGRectMake(midPos-1 + centeringOffset, 0,2, scroller.frame.size.height)];
                     currentCutView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
                }
                    break;
                case 2:
                {
                    CGFloat width = CMTimeGetSeconds(mergeURLAsset.duration) * 60;
                    
                    currentCutView = [[AudioMergeEditView alloc] initWithFrame:CGRectMake(midPos-1 + centeringOffset, 0,width, scroller.frame.size.height)];

                    AudioMergeEditView *v = (AudioMergeEditView *)currentCutView;
                    v.volume = [[[SettingsTool settings] audioEditVolume] floatValue];
                    v.rampIn = [[[SettingsTool settings] audioEditTransitionIn] boolValue];
                    v.rampOut = [[[SettingsTool settings] audioEditTransitionOut] boolValue];
                    v.rampLength = [[[SettingsTool settings] audioEditRampDuration] floatValue];
                    v.filename = insertClipLabel.text;
                    v.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.0 alpha:0.7];
                    [v update];
                    [mergeList addObject:@[ [NSValue valueWithCMTime:beginCut],
                                            [NSValue valueWithCMTime:mergeURLAsset.duration],
                                            [[SettingsTool settings] audioEditVolume],
                                            [[SettingsTool settings] audioEditTransitionIn],
                                            [[SettingsTool settings] audioEditTransitionOut],
                                            [[SettingsTool settings] audioEditRampDuration],
                                            mergeURLAsset
                                            ]];
                }
                    break;
            }
            
           
           
            currentCutView.tag = -200;
            [scroller addSubview:currentCutView];
            
            if (seg.selectedSegmentIndex == 2) {
                currentCutView = nil;
            }
        }
            break;
        case 2://end
        {
            
            if (seg.selectedSegmentIndex == 2) {
                pickingFile = YES;
                AudioMergeSelectViewController *vc = [[AudioMergeSelectViewController alloc] initWithNibName:@"AudioMergeSelectViewController" bundle:nil];
                vc.delegate = self;
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self presentViewController:nav animated:YES completion:nil];
                return;
            }

            
            if (!hasBeginCut) {
                return;
            }
            
            
            currentCutView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
            
            hasBeginCut = NO;
            endCutButton.enabled = (seg.selectedSegmentIndex == 2) ? YES : NO;
            
            float midPos = [self scrollerMidPos];
            
            float p = midPos / (scroller.contentSize.width - (centeringOffset * 2.0f));
            
            switch (seg.selectedSegmentIndex) {
                case 0:
                {
                    [cutList addObject:@[ [NSValue valueWithCMTime:beginCut], [NSValue valueWithCMTime:CMTimeMake(_asset.duration.value * p, _asset.duration.timescale)]]];
                }
                    break;
                case 1:
                {
                    AudioVolumeEditView *v = (AudioVolumeEditView *)currentCutView;
                    v.volume = [[[SettingsTool settings] audioEditVolume] floatValue];
                    v.rampIn = [[[SettingsTool settings] audioEditTransitionIn] boolValue];
                    v.rampOut = [[[SettingsTool settings] audioEditTransitionOut] boolValue];
                    v.rampLength = [[[SettingsTool settings] audioEditRampDuration] floatValue];
                   
                    [v update];
                        //NSLog(@"Added volume to volumeList:%@,%@",  [NSValue valueWithCMTime:beginCut], [NSValue valueWithCMTime:CMTimeMake(_asset.duration.value * p, _asset.duration.timescale)]);
                    [volumeList addObject:@[ [NSValue valueWithCMTime:beginCut],
                                             [NSValue valueWithCMTime:CMTimeMake(_asset.duration.value * p, _asset.duration.timescale)],
                                             [[SettingsTool settings] audioEditVolume],
                                             [[SettingsTool settings] audioEditTransitionIn],
                                             [[SettingsTool settings] audioEditTransitionOut],
                                             [[SettingsTool settings] audioEditRampDuration]
                                             ]];
                }
                    break;
            }
            currentCutView = nil;
        }
            break;
        case 1000: {
            [[SettingsTool settings] setAudioEditTransitionIn:@(0)];
            [self updateTransitionButtons];
        }
            break;
        case 1001: {
             [[SettingsTool settings] setAudioEditTransitionIn:@(1)];
            [self updateTransitionButtons];
        }
            break;
        case 1002: {
             [[SettingsTool settings] setAudioEditTransitionOut:@(0)];
            [self updateTransitionButtons];
        }
            break;
        case 1003: {
             [[SettingsTool settings] setAudioEditTransitionOut:@(1)];
            [self updateTransitionButtons];
        }
            break;
    }
    
    [self updateView];
}

-(void)closeDetailView {
    if (!detailView) {
        return;
    }
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ detailView] ];
    [animator removeAllBehaviors];
    [animator addBehavior:gravity];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [animator removeAllBehaviors];
            animator = nil;
            [detailView removeFromSuperview];
            detailView = nil;
        });
    });
}

-(void)userTappedDurationButton {
    if (detailView) {
        [self closeDetailView];
    } else {
        detailView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2.0f) - 175, -200, 350, 200)];
        detailView.backgroundColor = [UIColor darkGrayColor];
        [self.view addSubview:detailView];
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,0,350,50)];
        l.text = @"Audio Ramp Duration";
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = [UIColor blackColor];
        l.backgroundColor = [UIColor whiteColor];
        [detailView addSubview:l];
        
        UILabel *l2 = [[UILabel alloc] initWithFrame:CGRectMake(0,70,350,50)];
        l2.text = [NSString stringWithFormat:@"%.1f second(s)", [[[SettingsTool settings] audioEditRampDuration] floatValue]];
        l2.textAlignment = NSTextAlignmentCenter;
        l2.textColor = [UIColor whiteColor];
        l2.font = [UIFont boldSystemFontOfSize:20];
        l2.backgroundColor = [UIColor clearColor];
        l2.tag = 100;
        [detailView addSubview:l2];
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0,130,350,40)];
        slider.minimumValue = 0.1f;
        slider.maximumValue = 10.0f;
        slider.value = [[[SettingsTool settings] audioEditRampDuration] floatValue];
        [slider addTarget:self action:@selector(audioEditRampDurationSlider:) forControlEvents:UIControlEventValueChanged];
        [detailView addSubview:slider];
        
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
        
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedDetailView:)];
        [detailView addGestureRecognizer:tapG];
        
    }
}

-(void)audioEditRampDurationSlider:(id)sender {
    UISlider *slider = (UISlider *)sender;
    UILabel *l2 = (UILabel *)[detailView viewWithTag:100];
    [[SettingsTool settings] setAudioEditRampDuration:@(slider.value)];
    l2.text = [NSString stringWithFormat:@"%.1f second(s)", [[[SettingsTool settings] audioEditRampDuration] floatValue]];
    [self updateDurationButton];
}

-(void)userTappedDetailView:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self closeDetailView];
        detailView.userInteractionEnabled = NO;
    }
}

- (IBAction)userTappedConfirmButton:(id)sender {
    
    UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.titleView;
    
    switch (seg.selectedSegmentIndex) {
        case 0:
        {
            NSString *nibName = @"AudioEditorConfirmViewController";
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                nibName = [nibName stringByAppendingString:@"iPad"];
            }
            
            AudioEditorConfirmViewController *vc = [[AudioEditorConfirmViewController alloc] initWithNibName:nibName bundle:nil];
            vc.clip = _asset;
            vc.cutList = [cutList copy];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1:
        {
            NSString *nibName = @"AudioVolumeConfirmViewController";
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                nibName = [nibName stringByAppendingString:@"iPad"];
            }
            
            AudioVolumeConfirmViewController *vc = [[AudioVolumeConfirmViewController alloc] initWithNibName:nibName bundle:nil];
            vc.clip = _asset;
            vc.volList = [volumeList copy];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
            NSString *nibName = @"AudioMergeConfirmViewController";
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                nibName = [nibName stringByAppendingString:@"iPad"];
            }
            
            AudioMergeConfirmViewController *vc = [[AudioMergeConfirmViewController alloc] initWithNibName:nibName bundle:nil];
            vc.clip = _asset;
            vc.mergeList = [mergeList copy];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
    }
}

- (IBAction)userTappedStartOver {
    UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.titleView;
    
    hasBeginCut = NO;
    endCutButton.enabled = (seg.selectedSegmentIndex == 2) ? YES : NO;
    
    for (UIView *v in scroller.subviews) {
        if (v.tag == -200) {
            [v removeFromSuperview];
        }
    }
    
    currentCutView = nil;

    [cutList removeAllObjects];
    [volumeList removeAllObjects];
    [mergeList removeAllObjects];
    
    [self updateView];
}

-(void)userTappedPlay {
    
    if (audioPlayer) {
        [playTimer invalidate];
        playTimer = nil;
        playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(userTappedPlay)];
        [audioPlayer stop];
        CGRect r = CGRectMake(audioPlayer.currentTime * 60, 0, scroller.frame.size.width, scroller.frame.size.height);
        [scroller scrollRectToVisible:r animated:NO];
        audioPlayer = nil;
        return;
    }
    
    playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(userTappedPlay)];
    [self updateModeUI:(UISegmentedControl *)self.navigationItem.titleView];
    
    
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[_asset URL] error:&error];
    if (error) {
        NSLog(@"audio file error:%@", [error localizedDescription]);
    }
    
    audioPlayer.numberOfLoops = 0;
    [audioPlayer setCurrentTime:currentSecond];
    [audioPlayer setMeteringEnabled:NO];
    [audioPlayer play];
    
    playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(playTimerEvent) userInfo:nil repeats:YES];
    [self playTimerEvent];
}

-(void)playTimerEvent {
    CGRect r = CGRectMake((audioPlayer.currentTime+1) * 60, 0, scroller.frame.size.width, scroller.frame.size.height);
    if (r.origin.x != scroller.contentOffset.x) {
        [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
            [scroller scrollRectToVisible:r animated:NO];
        } completion:nil];
    }
}

@end
