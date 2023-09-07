//
//  VideoSourceStatusLabel.h
//  Cloud Director
//
//  Created by Gary  Barnett on 3/10/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoSourceStatusLabel : UILabel
@property (nonatomic, copy) NSString *ID;
-(void)listen;
-(void)stopListening;

@end
