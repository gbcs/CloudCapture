//
//  PhotoEditViewController.m
//  Capture
//
//  Created by Gary  Barnett on 3/26/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "PhotoEditViewController.h"

@interface PhotoEditViewController ()

@end

@implementation PhotoEditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
  
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _editView;
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ALAssetRepresentation *rep = [_asset defaultRepresentation];
    CGImageRef image = [rep fullScreenImage];
    
    UIImage *i = [UIImage imageWithCGImage:image];
    
    _editView = [[PhotoEditView alloc] initWithFrame:CGRectMake(0,0,i.size.width, i.size.height)];
    [_editView useImage:image];
    [_scroller addSubview:_editView];
    [_scroller setContentSize:_editView.frame.size];
    
    CGFloat zoomX = _scroller.frame.size.width / _editView.frame.size.width;
    CGFloat zoomY = _scroller.frame.size.height / _editView.frame.size.height;
    
    CGFloat z = MIN(zoomX, zoomY);
    
    [_scroller setMinimumZoomScale:z];
    [_scroller setMaximumZoomScale:z*10.0];
    [_scroller setZoomScale:z];
    
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
