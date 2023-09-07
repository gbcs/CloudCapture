//
//  ConfigureCellView.m
//  Capture
//
//  Created by Gary Barnett on 9/15/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ConfigureCellView.h"

@implementation ConfigureCellView {
    NSString *titleStr;
    NSString *descriptionStr;
    UIImage *iconImage;
    BOOL gestureAdded;
}

-(void)dealloc {
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }

    titleStr = nil;
    descriptionStr = nil;
    iconImage = nil;
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

-(void)userTapped:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        [self.delegate userTappedCellWithTag:g.view.tag];
    }
}

-(void)useDetails:(NSDictionary *)detailDict andDelegate:(NSObject <ConfigureCellDelegate> *)cellDelegate {
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    
    self.userInteractionEnabled = YES;
    
    self.delegate = cellDelegate;
  
    titleStr = [detailDict objectForKey:@"title"];
    descriptionStr = [detailDict objectForKey:@"description"];
    iconImage = [UIImage imageNamed:[detailDict objectForKey:@"icon"]];
    
    NSString *tapStr = @"Tap For Details";
    if ([detailDict objectForKey:@"tapStr"]) {
        tapStr = [detailDict objectForKey:@"tapStr"];
    }
    
    BOOL selected = [[detailDict objectForKey:@"selected"] boolValue];
   
    self.backgroundColor = [[UtilityBag bag] colorWithHexString:selected ? @"#e5b382" : @"#f5a372" withAlpha:1.0];
    
    CGRect r = CGRectInset(self.bounds, 5,0);
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(r.origin.x, r.origin.y, r.size.width, 55)];
    [self addSubview:l];
    
    UILabel *d = [[UILabel alloc] initWithFrame:CGRectMake(r.origin.x, r.size.height - 60, r.size.width, 40)];
    [self addSubview:d];
    
    if ([detailDict objectForKey:@"largeDetailTextArea"]) {
        d.frame = CGRectMake(d.frame.origin.x, d.frame.origin.y - 15, d.frame.size.width, d.frame.size.height + 15);
         d.numberOfLines = 3;
    } else {
         d.numberOfLines = 2;
    }
    
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(r.origin.x, r.size.height - 20, r.size.width, 20)];
    [self addSubview:t];
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:iconImage];
    iv.frame = CGRectMake((self.frame.size.width / 2.0f) - (30 / 2.0f), 37,30,30);
    [self addSubview:iv];
    
    l.userInteractionEnabled = YES;
    d.userInteractionEnabled = YES;
    t.userInteractionEnabled = YES;
    iv.userInteractionEnabled = YES;
    
    l.backgroundColor = [UIColor clearColor];
    d.backgroundColor = [UIColor clearColor];
    t.backgroundColor = [UIColor clearColor];
    iv.backgroundColor = [UIColor clearColor];
    
    t.font = [UIFont boldSystemFontOfSize:12];
    t.textAlignment = NSTextAlignmentCenter;
    t.text = tapStr;

    d.font = [UIFont systemFontOfSize:12];
   
    d.textAlignment = NSTextAlignmentCenter;
    
    l.font = [UIFont boldSystemFontOfSize:14];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 3;
    l.text = titleStr;
    d.text = descriptionStr;
    
    if (!gestureAdded) {
        gestureAdded = YES;
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapped:)];
        [self addGestureRecognizer:tapG];
    }
}

@end
