//
//  ConfigureDetailsButtonView.h
//  Capture
//
//  Created by Gary Barnett on 9/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfigureDetailsView.h"

@interface ConfigureDetailsButtonView : ConfigureDetailsView <GradientAttributedButtonDelegate>

@property (nonatomic, weak) NSObject <ConfigureCellDetailDelegate> *delegate;

-(void)useDetails:(NSDictionary *)detailDict andDelegate:(NSObject <ConfigureCellDetailDelegate> *)detailDelegate;

-(void)updateDescLabel:(NSString *)text;

@end
