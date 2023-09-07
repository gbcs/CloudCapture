//
//  ConfigureDetailsButtonView.m
//  Capture
//
//  Created by Gary Barnett on 9/17/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ConfigureDetailsButtonView.h"

@implementation ConfigureDetailsButtonView {
    NSString *titleStr;
    NSString *descriptionStr;
    UIImage *iconImage;
    BOOL gestureAdded;
    UILabel *descLabel;
}

-(void)dealloc {
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

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    [self.delegate userTappedCellWithAction:tag];
}

-(GradientAttributedButton *)getButtonWithRect:(CGRect)r andDict:(NSDictionary *)dict position:(CGFloat)pos row:(NSInteger)row {
    CGSize buttonSize = CGSizeMake(90,44);
    
    if ([[SettingsTool settings] isiPhone4S]) {
        buttonSize = CGSizeMake(70,44);
    }
    
    CGFloat yOffset = 50;
    
    if (row == 1) {
        yOffset = 100;
    }
    
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:CGRectMake(r.origin.x + (r.size.width *pos) - (buttonSize.width / 2.0f), r.size.height - yOffset, buttonSize.width, buttonSize.height)];
   
    button.delegate = self;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    NSAttributedString *activeText = [[NSAttributedString alloc] initWithString:[dict objectForKey:@"title"] attributes:@{
                                                                                                                                NSFontAttributeName : [UIFont preferredFontForTextStyle:@"Body"],
                                                                                                                                NSShadowAttributeName : shadow,
                                                                                                                                NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                                                }];
    
    
    button.tag = [[dict objectForKey:@"tag"] integerValue];
    
    [button setTitle:activeText disabledTitle:activeText beginGradientColorString:@"#000099" endGradientColor:@"#000066"];
    
    button.enabled = YES;
    [button update];
    
    return button;
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
    
    CGRect r = CGRectInset(self.bounds, 5,0);
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(r.origin.x, r.origin.y, r.size.width, 25)];
    [self addSubview:l];
    
    UILabel *d = [[UILabel alloc] initWithFrame:CGRectMake(r.origin.x, 40, r.size.width, r.size.height - 120)];
    [self addSubview:d];
    
    descLabel = d;
    
    NSDictionary *buttonDict = [detailDict objectForKey:@"button1"];
    NSDictionary *button2Dict = [detailDict objectForKey:@"button2"];
    NSDictionary *button3Dict = [detailDict objectForKey:@"button3"];
    NSDictionary *button4Dict = [detailDict objectForKey:@"button4"];
    NSDictionary *button5Dict = [detailDict objectForKey:@"button5"];
    NSDictionary *button6Dict = [detailDict objectForKey:@"button6"];
    
    if (button4Dict && button5Dict && button6Dict) {
        [self addSubview:[self getButtonWithRect:r andDict:button4Dict position:0.25f row:1]];
        [self addSubview:[self getButtonWithRect:r andDict:button5Dict position:0.50f row:1]];
        [self addSubview:[self getButtonWithRect:r andDict:button6Dict position:0.75f row:1]];
    } else if (button4Dict && button5Dict) {
        [self addSubview:[self getButtonWithRect:r andDict:button4Dict position:0.33f row:1]];
        [self addSubview:[self getButtonWithRect:r andDict:button5Dict position:0.66f row:1]];
    } else if (button4Dict) {
        [self addSubview:[self getButtonWithRect:r andDict:button4Dict position:0.50f row:1]];
    }
    
    
    
    if (buttonDict && button2Dict && button3Dict) {
        [self addSubview:[self getButtonWithRect:r andDict:buttonDict position:0.25f row:0]];
        [self addSubview:[self getButtonWithRect:r andDict:button2Dict position:0.50f row:0]];
        [self addSubview:[self getButtonWithRect:r andDict:button3Dict position:0.75f row:0]];
    } else if (buttonDict && button2Dict) {
        [self addSubview:[self getButtonWithRect:r andDict:buttonDict position:0.33f row:0]];
        [self addSubview:[self getButtonWithRect:r andDict:button2Dict position:0.66f row:0]];
    } else if (buttonDict) {
        [self addSubview:[self getButtonWithRect:r andDict:buttonDict position:0.50f row:0]];
    }
    
    l.userInteractionEnabled = YES;
    d.userInteractionEnabled = YES;
    
    l.backgroundColor = [UIColor clearColor];
    d.backgroundColor = [UIColor clearColor];
    
    l.textColor = [UIColor blackColor];
    d.textColor = [UIColor blackColor];
    
    d.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    l.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
    d.numberOfLines = 0;
    
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
