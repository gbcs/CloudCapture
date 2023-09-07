//
//  AudioMergeSelectViewController.h
//  Capture
//
//  Created by Gary Barnett on 2/2/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AudioMergeSelectFileDelegate <NSObject>
-(void)userPickedAudioURL:(AVURLAsset *)url withTitle:(NSString *)title;
@end

@interface AudioMergeSelectViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, weak) NSObject <AudioMergeSelectFileDelegate> *delegate;
@end
