//
//  ConfigureCellView.h
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ConfigureCellDelegate <NSObject>

-(void)userTappedCellWithTag:(NSInteger) tag;

@end

@interface ConfigureCellView : UIView
@property (nonatomic, assign) NSInteger category;
@property (nonatomic, weak) NSObject <ConfigureCellDelegate> *delegate;
-(void)useDetails:(NSDictionary *)detailDict andDelegate:(NSObject <ConfigureCellDelegate> *)d;

@end
