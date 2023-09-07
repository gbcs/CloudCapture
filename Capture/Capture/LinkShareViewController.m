//
//  LinkShareViewController.m
//  Capture
//
//  Created by Gary Barnett on 1/31/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "LinkShareViewController.h"

@interface LinkShareViewController ()

@end

@implementation LinkShareViewController {
    __weak IBOutlet GradientAttributedButton *testButton;
    __weak IBOutlet GradientAttributedButton *closeButton;
    __weak IBOutlet GradientAttributedButton *shareButton;
    __weak IBOutlet UILabel *urlLabel;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    urlLabel.text = [_url absoluteString];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Upload Complete";
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[UtilityBag bag] colorWithHexString:@"#FFFFFF"];
    shadow.shadowOffset = CGSizeMake(0,-1.0f);
    
    
    NSAttributedString *testStr = [[NSAttributedString alloc] initWithString:@"Test" attributes:@{
                                                                                                    NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]-1],
                                                                                                    NSShadowAttributeName : shadow,
                                                                                                    NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                    }];
    
    NSAttributedString *shareStr = [[NSAttributedString alloc] initWithString:@"Share" attributes:@{
                                                                                                     NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]-1],
                                                                                                     NSShadowAttributeName : shadow,
                                                                                                     NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                     }];
    
    NSAttributedString *closeStr = [[NSAttributedString alloc] initWithString:@"Close" attributes:@{
                                                                                                       NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]-1],
                                                                                                       NSShadowAttributeName : shadow,
                                                                                                       NSForegroundColorAttributeName : [[UtilityBag bag] colorWithHexString:@"#FFFFFF"]
                                                                                                       }];
   
    testButton.enabled = YES;
    testButton.delegate = self;
    testButton.tag = 999;
    
    shareButton.enabled = YES;
    shareButton.delegate = self;
    shareButton.tag = 1000;
    
    closeButton.enabled = YES;
    closeButton.delegate = self;
    closeButton.tag = 1001;
    
    NSString *bgColor = @"#444444";
    NSString *endColor = @"#111111";
    
    [testButton setTitle:testStr disabledTitle:testStr beginGradientColorString:bgColor endGradientColor:endColor];
    [testButton update];
    
    [shareButton setTitle:shareStr disabledTitle:shareStr beginGradientColorString:bgColor endGradientColor:endColor];
    [shareButton update];
    
    [closeButton setTitle:closeStr disabledTitle:closeStr beginGradientColorString:bgColor endGradientColor:endColor];
    [closeButton update];
}

-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    
    if (tag == 999) {
        [[UIApplication sharedApplication] openURL:_url];
        return;
    }
    
    if (tag == 1001) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[ _url] applicationActivities:nil];
    [vc.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.navigationBar setTranslucent:NO];
    [vc.navigationController.toolbar setBarStyle:UIBarStyleBlack];
    [vc.navigationController.toolbar    setTranslucent:NO];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
