//
//  HistogramView.h
//  Capture
//
//  Created by Gary Barnett on 9/2/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>

@interface HistogramView : UIView
-(void)updateWithR:(vImagePixelCount *)r andG:(vImagePixelCount *)g andB:(vImagePixelCount *)b vidRes:(CGSize )vidRes;
@end
