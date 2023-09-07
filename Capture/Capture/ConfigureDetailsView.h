//
//  ConfigureDetailsView.h
//  Capture
//
//  Created by Gary Barnett on 9/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ConfigureCellDetailDelegate <NSObject>
-(void)userTappedCellWithAction:(NSInteger)action;
@end

@interface ConfigureDetailsView : UIView
@property (nonatomic, weak) NSObject <ConfigureCellDetailDelegate> *delegate;
-(void)updateDescLabel:(NSString *)text;

-(void)useDetails:(NSDictionary *)detailDict andDelegate:(NSObject <ConfigureCellDetailDelegate> *)detailDelegate;
@end
