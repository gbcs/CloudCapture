//
//  ConnectionButtonWIthID.h
//  Cloud Director
//
//  Created by Gary  Barnett on 3/11/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConnectionButtonWIthID : UIButton
@property (nonatomic, copy) NSString *ID;

-(void)listen;
-(void)stopListening;

@end
