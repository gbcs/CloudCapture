//
//  GPUVideoCompositor.h
//  Capture
//
//  Created by Gary Barnett on 12/3/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface GPUVideoCompositor : NSObject <AVVideoCompositing>
- (id)initWithVideoComposition:(AVVideoComposition *)videoComposition;

-(void)setupQueues;
@end
