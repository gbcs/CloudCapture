//
//  SpriteTitlingViewController.m
//  Capture
//
//  Created by Gary Barnett on 8/28/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "SpriteTitlingViewController.h"
#import <SpriteKit/SpriteKit.h>
#import "TitlingScene.h"

@interface SpriteTitlingViewController () {
    SKScene *spriteScene;
    SKView *spriteView;
    UIView *testView;
}

@end

@implementation SpriteTitlingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
    spriteScene = [[TitlingScene alloc] initWithSize:CGSizeMake(568,320)];
    spriteScene.scaleMode = SKSceneScaleModeResizeFill;
    
    spriteView = [[SKView alloc] initWithFrame:CGRectMake(0,0,568,320)];
    
    spriteView.showsFPS = YES;
    spriteView.showsNodeCount = YES;
    
    
    
    
    [spriteView presentScene:spriteScene];
    
    [self.view addSubview:spriteView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *)titlingView {

    return spriteView;
}


@end
