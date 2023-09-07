//
//  CreateMoviePreviewViewController.h
//  Capture
//
//  Created by Gary Barnett on 9/20/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateMoviePreviewViewController : UIViewController <AVVideoCompositionValidationHandling, GradientAttributedButtonDelegate>
@property (nonatomic, copy) NSMutableArray *clips;
@property (nonatomic, copy) NSMutableArray *clipGenerators;
@property (nonatomic, copy) NSArray *clipNominalFrameRates;
@property (nonatomic, copy) NSArray *clipDurations;
@property (nonatomic, copy) NSMutableDictionary *clipTransitionInstructions;
@property (nonatomic, copy) NSMutableArray *audioTracks;

@end
