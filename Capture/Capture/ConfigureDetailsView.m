//
//  ConfigureDetailsView.m
//  Capture
//
//  Created by Gary Barnett on 9/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ConfigureDetailsView.h"

@implementation ConfigureDetailsView {
    NSString *titleStr;
    NSString *descriptionStr;
    UIImage *iconImage;
    BOOL gestureAdded;
    UILabel *descLabel;
}

-(void)dealloc {
    //NSLog(@"%s", __func__);
    
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
   titleStr = nil;
   descriptionStr = nil;
    iconImage = nil;
    descLabel = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.bounds];
        self.layer.masksToBounds = NO;
        self.layer.shadowColor = [UIColor colorWithWhite:0.7 alpha:1.0].CGColor;
        self.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
        self.layer.shadowOpacity = 1.0f;
        self.layer.shadowRadius = 1.0f;
        self.layer.shadowPath = shadowPath.CGPath;
        self.layer.masksToBounds = NO;
    }
    return self;
}

-(void)updateDescLabel:(NSString *)text {
    descLabel.text = text;
}

-(void)userTapped:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self.delegate userTappedCellWithAction:0];
    }
}

-(void)useDetails:(NSDictionary *)detailDict andDelegate:(NSObject <ConfigureCellDetailDelegate> *)detailDelegate {
    self.delegate = detailDelegate;
    
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    
    self.userInteractionEnabled = YES;
    
    titleStr = [detailDict objectForKey:@"title"];
    descriptionStr = [detailDict objectForKey:@"description"];
    
    self.backgroundColor = [[UtilityBag bag] colorWithHexString: @"#f5a372" withAlpha:1.0];
    
    CGRect r = CGRectInset(self.bounds, 5,5);
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(r.origin.x, r.origin.y, r.size.width, 50)];
    l.lineBreakMode = NSLineBreakByCharWrapping;
    [self addSubview:l];
    
    
    UILabel *d = [[UILabel alloc] initWithFrame:CGRectMake(r.origin.x, 40, r.size.width, r.size.height - 40)];
    [self addSubview:d];
    descLabel = d;
    
    l.userInteractionEnabled = YES;
    d.userInteractionEnabled = YES;
    
    l.backgroundColor = [UIColor clearColor];
    d.backgroundColor = [UIColor clearColor];
  
    l.textColor = [UIColor blackColor];
    d.textColor = [UIColor blackColor];
    
    d.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    if ([[SettingsTool settings] isiPhone4] || [[SettingsTool settings] isiPhone4S]) {
        d.font = [d.font fontWithSize:12];
    }
    
    l.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
   
    d.numberOfLines = 0;
    l.numberOfLines = 0;
    
    d.textAlignment = NSTextAlignmentCenter;
    l.textAlignment = NSTextAlignmentCenter;
    
    l.text = titleStr;
    d.text = descriptionStr;
    
    if (!gestureAdded) {
        gestureAdded = YES;
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapped:)];
        [self addGestureRecognizer:tapG];
    }
}

@end
