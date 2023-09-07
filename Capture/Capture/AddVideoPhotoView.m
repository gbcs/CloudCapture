//
//  AddVideoPhotoView.m
//  Capture
//
//  Created by Gary  Barnett on 2/25/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "AddVideoPhotoView.h"


@interface AddVideoPhotoView () {
    UIDynamicAnimator *animator;

    MakeVideoFromImage *videoFromPhoto;
    GPUMakeVideoFromImage *videoFromPhotoGPU;
    
    NSString *addedPhotoPath;
    NSInteger addedPhotoDuration;
    BOOL currentTransitionSelectionIsBegin;
}

@end

@implementation AddVideoPhotoView

-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
    //NSLog(@"%s", __func__);
    
    
}

-(void)makePhotoVideoProgress:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *progressVal = (NSNumber *)n.object;
        UIProgressView *progress =(UIProgressView *)[self viewWithTag:999];
        UILabel *timeLabel =(UILabel *)[self viewWithTag:88];
        progress.progress = [progressVal floatValue];
        timeLabel.text = [[UtilityBag bag] returnRemainingTimeForOperationWithProgress:progress.progress];
    });
}

-(void)startup:(NSString *)fName {
    addedPhotoPath = fName;
    addedPhotoDuration = [[SettingsTool settings] defaultMoviePhotoTime];
    
    self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.superview];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makePhotoVideoProgress:) name:@"makePhotoVideoProgress" object:nil];
    
    
    CGFloat y = self.superview.frame.size.height - 5;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        y = 340;
    }
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ self] ];
    [collision addBoundaryWithIdentifier:@"bottom" fromPoint:CGPointMake(0,y) toPoint:CGPointMake(self.superview.frame.size.width,y)];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ self] ];
    
    [animator addBehavior:collision];
    [animator addBehavior:gravity];
    
    
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithFrame:CGRectMake(240 - 80,2,160,40)];
    [segment insertSegmentWithTitle:@"Transition" atIndex:0 animated:NO];
    [segment insertSegmentWithTitle:@"Duration" atIndex:1 animated:NO];
    segment.tag = 15;
    [segment setSelectedSegmentIndex:0];
    [segment addTarget:self action:@selector(userTappedPhotoSegment:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:segment];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0,145,480,50)];
    slider.minimumValue = 1.0f;
    slider.maximumValue = 60.0f;
    slider.tag = 11;
    slider.value = [[SettingsTool settings] defaultMoviePhotoTime];
    [slider addTarget:self action:@selector(userChangedPhotoTimeSlider:) forControlEvents:UIControlEventValueChanged];
    [self  addSubview:slider];
    
    slider.hidden = ([segment selectedSegmentIndex] != 1);
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0,90,480,50)];
    l.textColor = [UIColor whiteColor];
    l.backgroundColor = [UIColor clearColor];
    l.font = [UIFont boldSystemFontOfSize:30];
    l.textAlignment = NSTextAlignmentCenter;
    l.tag = 12;
    l.text = [[UtilityBag bag] durationStr:addedPhotoDuration];
    [self addSubview:l];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(410,0,60,44)];
    [button setTitle:@"Save" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(makePhoto:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = 13;
    [self addSubview:button];
    
    button = [[UIButton alloc] initWithFrame:CGRectMake(10,0,60,44)];
    [button setTitle:@"Cancel" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(makePhoto:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = 14;
    [self addSubview:button];
    
    
    NSString *fPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"] stringByAppendingPathComponent:addedPhotoPath];
    UIImage *image = [UIImage imageWithContentsOfFile:fPath];
    
    CGRect imageViewFrame = CGRectZero;
    CGRect beginButtonFrame = CGRectZero;
    CGRect endButtonFrame = CGRectZero;
    
    if (image.size.width == image.size.height) {
        imageViewFrame = CGRectMake(240 - 110, 45, 220, 220);
        beginButtonFrame = CGRectMake(390,60,90,44);
        endButtonFrame = CGRectMake(390,103,90,44);
        
        CGFloat h = 220 / (16.0 / 9.0f);
        CGFloat width = 220.0f;
        
        [[SettingsTool settings] setDefaultMoviePhotoTransitionStartRect:CGRectMake(0,220 - h,width,h)];
        [[SettingsTool settings] setDefaultMoviePhotoTransitionEndRect:CGRectMake(0,0,width,h)];
        
    } else if (image.size.width > image.size.height) {
        CGFloat ratio = image.size.width / image.size.height;
        CGFloat height = 180;
        CGFloat width = height * ratio;
        if (width > 480) {
            width = 480;
            height = width / ratio;
        }
        
        imageViewFrame = CGRectMake(240 - (width / 2.0f), 45 + ((180 - height) / 2.0f), width, height);
        beginButtonFrame = CGRectMake((480.0 * 0.33) - 45,270 - 44,90,44);
        endButtonFrame = CGRectMake((480.0 * 0.67) - 45,270 - 44,90,44);
        
        if (ratio >= (16.0 / 9.0)) {
            [[SettingsTool settings] setDefaultMoviePhotoTransitionStartRect:CGRectMake(0,0,height * (16.0 / 9.0f), height)];
            [[SettingsTool settings] setDefaultMoviePhotoTransitionEndRect:CGRectMake(width - (height * (16.0 / 9.0f)),0,height * (16.0 / 9.0f), height)];
        } else {
            CGFloat h = width / (16.0 / 9.0f);
            
            [[SettingsTool settings] setDefaultMoviePhotoTransitionStartRect:CGRectMake(0,height - h,width, h)];
            [[SettingsTool settings] setDefaultMoviePhotoTransitionEndRect:CGRectMake(0,0,width, h)];
        }
    } else {
        CGFloat ratio = image.size.width / image.size.height;
        CGFloat height = 220;
        CGFloat width = height * ratio;
        
        CGFloat h = width / (16.0 / 9.0f);
        
        [[SettingsTool settings] setDefaultMoviePhotoTransitionStartRect:CGRectMake(0,height - h,width,h)];
        [[SettingsTool settings] setDefaultMoviePhotoTransitionEndRect:CGRectMake(0,0,width,h)];
        
        imageViewFrame = CGRectMake(240 - (width / 2.0f), 45 + ((220 - height) / 2.0f), width, height);
        beginButtonFrame = CGRectMake(390,60,90,44);
        endButtonFrame = CGRectMake(390,103,90,44);
    }
    
    UIImageView *iv = [[UIImageView alloc] initWithFrame:imageViewFrame];
    iv.backgroundColor = [UIColor blackColor];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.tag = 499;
    iv.image = image;
    [self addSubview:iv];
    iv.userInteractionEnabled = YES;
    
    SPUserResizableView *boundsRect = [[SPUserResizableView alloc] initWithFrame:[[SettingsTool settings] defaultMoviePhotoTransitionStartRect]];
    boundsRect.tag = 123;
    boundsRect.userInteractionEnabled = YES;
    boundsRect.enforce16x19AspectRatio = YES;
    boundsRect.delegate = self;
    [boundsRect showEditingHandles];
    boundsRect.layer.borderColor = [UIColor greenColor].CGColor;
    boundsRect.layer.borderWidth = 1.0f;
    UIView *v = [[UIView alloc] initWithFrame:boundsRect.bounds];
    v.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.2];
    
    v.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [boundsRect setContentView:v];
    [boundsRect setMinHeight:30];
    [boundsRect setMinWidth:30 * (16.0/9.0)];
    [iv addSubview:boundsRect];
    
    
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#000000"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    NSAttributedString *tNone = [[NSAttributedString alloc] initWithString:@"Begin" attributes:@{
                                                                                                 NSFontAttributeName : [[[UtilityBag bag] standardFontBold] fontWithSize:14],
                                                                                                 NSShadowAttributeName : shadow,
                                                                                                 NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#CCCCCC"]
                                                                                                 }];
    
    
    NSAttributedString *tZoomIn = [[NSAttributedString alloc] initWithString:@"End" attributes:@{
                                                                                                 NSFontAttributeName : [[[UtilityBag bag] standardFontBold] fontWithSize:14],
                                                                                                 NSShadowAttributeName : shadow,
                                                                                                 NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#CCCCCC"]
                                                                                                 }];
    
    
    NSString *bSelBegin = @"#009900";
    NSString *eSelBegin = @"#006600";
    
    NSString *bSelEnd = @"#000099";
    NSString *eSelEnd = @"#000066";
    
    NSString *bUns = @"#666666";
    NSString *eUns = @"#333333";
    
    currentTransitionSelectionIsBegin = YES;
    
    GradientAttributedButton *gButton = [[GradientAttributedButton alloc] initWithFrame:beginButtonFrame];
    gButton.delegate = self;
    gButton.tag = 5000;
    BOOL sel = currentTransitionSelectionIsBegin == YES;
    [gButton setTitle:tNone disabledTitle:tNone beginGradientColorString:sel? bSelBegin :bUns endGradientColor:sel? eSelBegin :eUns];
    gButton.enabled = YES;
    [self addSubview:gButton];
    [gButton update];
    
    gButton = [[GradientAttributedButton alloc] initWithFrame:endButtonFrame];
    gButton.delegate = self;
    gButton.tag = 5001;
    sel = currentTransitionSelectionIsBegin == NO;
    [gButton setTitle:tZoomIn disabledTitle:tZoomIn beginGradientColorString:sel? bSelEnd :bUns endGradientColor:sel? eSelEnd :eUns];
    gButton.enabled = YES;
    [self addSubview:gButton];
    [gButton update];
    
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
    
    UIImageView *iv = (UIImageView *)[self viewWithTag:499];
    
    SPUserResizableView *boundsRect = (SPUserResizableView *)[iv viewWithTag:123];
    CGRect r = boundsRect.frame;
    [boundsRect removeFromSuperview];
    
    
    
    for (NSInteger x = 0;x<4;x++) {
        GradientAttributedButton *button = (GradientAttributedButton *)[self viewWithTag:x + 5000];
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


-(void)userTappedPhotoSegment:(id)sender {
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    UIView *v = nil;
    
    BOOL tranSel = NO;
    if ([segment selectedSegmentIndex] == 0) {
        tranSel = YES;
    }
    
    v = [self viewWithTag:499];
    v.hidden = !tranSel;
    v = [self viewWithTag:5000];
    v.hidden = !tranSel;
    v = [self viewWithTag:5001];
    v.hidden = !tranSel;
    
    
    v = [self viewWithTag:11];
    v.hidden = tranSel;
    
    
}

-(void)makePhoto:(id)sender {
   
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    UIView *s = (UIView *)sender;
    if (s.tag == 14) {
        videoFromPhoto = nil;
        videoFromPhotoGPU = nil;
        addedPhotoPath = nil;
        
        [animator removeAllBehaviors];
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ self] ];
        [animator addBehavior:gravity];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [NSThread sleepForTimeInterval:1.1f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self closeView];
            });
        });
        return;
    }
    
    UIImageView *iv = (UIImageView *)[self viewWithTag:499];
    SPUserResizableView *boundsRect = (SPUserResizableView *)[iv viewWithTag:123];
    
    if (currentTransitionSelectionIsBegin) {
        [[SettingsTool settings] setDefaultMoviePhotoTransitionStartRect:boundsRect.frame];
    } else {
        [[SettingsTool settings] setDefaultMoviePhotoTransitionEndRect:boundsRect.frame];
    }
    
    UIView *v = [self viewWithTag:10];
    [v removeFromSuperview];
    v = [self viewWithTag:11];
    [v removeFromSuperview];
    v = [self viewWithTag:12];
    [v removeFromSuperview];
    v = [self viewWithTag:13];
    [v removeFromSuperview];
    v = [self viewWithTag:14];
    [v removeFromSuperview];
    v = [self viewWithTag:15];
    [v removeFromSuperview];
    v = [self viewWithTag:499];
    [v removeFromSuperview];
    v = [self viewWithTag:5000];
    [v removeFromSuperview];
    v = [self viewWithTag:5001];
    [v removeFromSuperview];
    
    
    
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0,50,480,40)];
    t.textColor = [UIColor whiteColor];
    t.backgroundColor = [UIColor clearColor];
    t.font = [UIFont boldSystemFontOfSize:17];
    t.textAlignment = NSTextAlignmentCenter;
    t.text = @"Making Video Clip From Photo";
    [self addSubview:t];
    
    [[UtilityBag bag] startTimingOperation];
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,200,480,40)];
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.font = [UIFont boldSystemFontOfSize:17];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.text = @"";
    timeLabel.tag = 88;
    [self addSubview:timeLabel];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:activity];
    activity.frame = CGRectMake(240 - 20,150,40,40);
    [activity startAnimating];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,(self.frame.size.height / 2.0f) - 2,480,4)];
    progressView.progress = 0.0f;
    progressView.progressTintColor = [UIColor blueColor];
    progressView.tag = 999;
    
    [self addSubview:progressView];
    
    if (1 == 1) {
        videoFromPhoto = [[MakeVideoFromImage alloc] init];
    } else {
       videoFromPhotoGPU = [[GPUMakeVideoFromImage alloc] init];
    }
    
    NSString *fPath = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"moviePhotos"] stringByAppendingPathComponent:addedPhotoPath];
    NSString *fPathMovie = [[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:addedPhotoPath] stringByAppendingPathExtension:@"mov"];
    
    addedPhotoPath = nil;
    
    
    CGRect startRect = [[SettingsTool settings] defaultMoviePhotoTransitionStartRect];
    CGRect endRect = [[SettingsTool settings] defaultMoviePhotoTransitionEndRect];
    
    UIImage *i = [UIImage imageWithContentsOfFile:fPath];
    
    CGFloat xScale = i.size.width / iv.frame.size.width;
    CGFloat yScale = i.size.height / iv.frame.size.height;
    
    startRect.origin = CGPointMake(startRect.origin.x * xScale, startRect.origin.y * yScale);
    startRect.size = CGSizeMake(startRect.size.width* xScale, startRect.size.height * yScale);
    endRect.origin = CGPointMake(endRect.origin.x * xScale, endRect.origin.y * yScale);
    endRect.size = CGSizeMake(endRect.size.width* xScale, endRect.size.height * yScale);
    
    if (1 == 1) {
        NSLog(@"image_size:%@ iv_size:%@ xScale:%@ yScale:%@\nstartRect:%@ transStartRect:%@\nendRect:%@ transEndRect:%@",
              [NSValue valueWithCGSize:i.size],
              [NSValue valueWithCGSize:iv.frame.size],
              [NSNumber numberWithFloat:xScale],
              [NSNumber numberWithFloat:yScale],
              [NSValue valueWithCGRect:[[SettingsTool settings] defaultMoviePhotoTransitionStartRect]],
              [NSValue valueWithCGRect:startRect],
              [NSValue valueWithCGRect:[[SettingsTool settings] defaultMoviePhotoTransitionEndRect]],
              [NSValue valueWithCGRect:endRect]
              );
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
         if (1 == 1) {
             [videoFromPhoto startVideoCaptureOfDuration:[[SettingsTool settings] defaultMoviePhotoTime]
                                              usingImage:[UIImage imageWithContentsOfFile:fPath]
                                               usingPath:fPathMovie
                                             andDelegate:self
                                               startRect:startRect
                                                 endRect:endRect
              ];
         } else {
             [videoFromPhotoGPU startVideoCaptureOfDuration:[[SettingsTool settings] defaultMoviePhotoTime]
                                              usingImage:[UIImage imageWithContentsOfFile:fPath]
                                               usingPath:fPathMovie
                                             andDelegate:self
                                               startRect:startRect
                                                 endRect:endRect
              ];
         }
    });
}


-(void)makeVideoComplete:(BOOL)success withPath:(NSString *)path {
   [UIApplication sharedApplication].idleTimerDisabled = NO;
    if (success) {
        NSString *fname = [path lastPathComponent];
        [[UtilityBag bag] makeThumbnail:fname];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedVideoFromPhoto" object:fname];
    }

    videoFromPhoto = nil;
    videoFromPhotoGPU = nil;
    [self closeView];
  }

-(void)closeView {
    
    [animator removeAllBehaviors];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ self] ];
    [animator addBehavior:gravity];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [animator removeAllBehaviors];
            animator = nil;
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cleanupImportImage" object:nil];
        });
    });
}


-(void)userChangedPhotoTimeSlider:(id)sender {
    UISlider *slider = (UISlider *)sender;
    
    NSInteger val = slider.value;
    [[SettingsTool settings] setDefaultMoviePhotoTime:val];
    UILabel *secLabel = (UILabel *)[self viewWithTag:12];
    secLabel.text = [[UtilityBag bag] durationStr:val];
    
    addedPhotoDuration = val;
}

@end
