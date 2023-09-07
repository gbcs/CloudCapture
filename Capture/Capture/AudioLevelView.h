//
//  AudioLevelView.h
//  iArchiver
//
//  Created by Gary Barnett on 5/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioLevelView : UIView {
    float value;
    BOOL ready;
}
@property (nonatomic, assign) BOOL isLeft;

-(void)updateValue:(float)newVal;
-(void)noDataForThisTrack;
@end

