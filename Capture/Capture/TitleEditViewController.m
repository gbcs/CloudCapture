//
//  TitleEditViewController.m
//  Capture
//
//  Created by Gary Barnett on 10/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "TitleEditViewController.h"
#import "ImportImageViewController.h"
#import "AppDelegate.h"
#import "TItleElementView.h"


@interface TitleEditViewController () {
    
    __weak IBOutlet UIImageView *bg;
    NSString *backgroundImageStr;
    NSMutableArray *elements;
    UIDynamicAnimator *featureAnimator;
    UIView *featureView;
    UITableView *featureViewTV;
    
    GradientAttributedButton *fontIncrease;
    GradientAttributedButton *fontDecrease;

    NSArray *fontList;
    NSString *currentFont;
    NSString *currentElement;
    NSMutableDictionary *elementViews;
    NSString *picPath;
    NSString *titlePath;
}

@end

@implementation TitleEditViewController

-(void)dealloc {
    [self dealloc2];
}

-(void)dealloc2 {
    NSLog(@"%@:%s", [self class], __func__);
     [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.view) {
        while ([self.view.subviews count]>0) {
            UIView *v = [self.view.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
    }
    

    bg = nil;
    backgroundImageStr = nil;
    elements = nil;
    featureAnimator = nil;
    featureView = nil;
    featureViewTV = nil;
    
    fontIncrease = nil;
    fontDecrease = nil;
    
    fontList = nil;
    currentFont = nil;
    currentElement = nil;
    elementViews = nil;
    picPath = nil;
    titlePath = nil;
    _pageToLoad = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)userTappedClose {
    [self saveTitlePage];
    
    [self performSelector:@selector(dealloc2) withObject:nil afterDelay:0.4];
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (NSString *)pathForNewTitlePage {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"titlePages"];
    
    NSString *result = nil;
    
    NSFileManager *fM = [[NSFileManager alloc] init];
    BOOL fileAlreadyExists = YES;
    
    NSString *resourceFileName = nil;
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    
    SPUserResizableView *v = [elementViews objectForKey:@"title"];
    TItleElementView *c = (TItleElementView *)v.cv;
    
    NSString *titlePrefix = (c.textStr && ([c.textStr length]>0)) ? c.textStr : @"Title";
    
    while (fileAlreadyExists) {
        resourceFileName = [NSString stringWithFormat:@"%@-%@.%@", titlePrefix, [uuid substringToIndex:4], @"title"  ];
        
        if ([fM fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:resourceFileName]]) {
            [NSThread sleepForTimeInterval:1];
        } else {
            fileAlreadyExists = NO;
        }
    }
    
    result = resourceFileName;
    
    assert(result != nil);
    
    return result;
}


-(void)saveTitlePage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"titlingPages"];
  
    if (!titlePath) {
        titlePath = [self pathForNewTitlePage];
    } else {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        [fm removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:titlePath] error:&error];
    }
    
    NSMutableDictionary *dict = [@{
                           @"bgSize" : [NSValue valueWithCGSize:bg.bounds.size],
                           @"bgImage" : picPath ? picPath : @"",
                           @"font" : currentFont,
                           } mutableCopy];
    
    for (NSString *str in [[SettingsTool settings] masterTitlingElementList]) {
        SPUserResizableView *v = [elementViews objectForKey:str];
        if (v)  {
            TItleElementView *t = (TItleElementView *)v.cv;
            
            [dict setObject:@{
                              @"pointSize" : [NSNumber numberWithFloat:t.font.pointSize],
                              @"rect" : [NSValue valueWithCGRect:v.frame],
                              @"text" : t.textStr ? t.textStr : @""
                              } forKey:str];
        }
    }
 
    
    
    if (![NSKeyedArchiver archiveRootObject:[dict copy] toFile:[documentsDirectory stringByAppendingPathComponent:titlePath]]) {
        NSLog(@"Unable to save: %@", [documentsDirectory stringByAppendingPathComponent:titlePath]);
    } else {
        if (self.isBeginTitle) {
            [[SettingsTool settings] setEngineTitlingBeginName:[titlePath stringByDeletingPathExtension]];
        } else {
             [[SettingsTool settings] setEngineTitlingEndName:[titlePath stringByDeletingPathExtension]];
        }
    }
    
}

-(void)loadTitlePage:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"titlingPages"];
    NSString *fpath = [documentsDirectory stringByAppendingPathComponent:name];
    
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithFile:fpath];
   
    if (!dict) {
         NSLog(@"Unable to load: %@", fpath);
    } else {
         titlePath = name;
        
        currentFont = [dict objectForKey:@"font"];
        picPath = [dict objectForKey:@"bgImage"];
        bg.image = [UIImage imageWithContentsOfFile:[[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] stringByAppendingPathComponent:picPath]];
        
        while ([bg.subviews count] >0) {
            UIView *v = [bg.subviews objectAtIndex:0];
            [v removeFromSuperview];
        }
        [elements removeAllObjects];
        [elementViews removeAllObjects];
        currentElement = nil;
        
        for (NSString *element in [[SettingsTool settings] masterTitlingElementList]) {
            NSDictionary *elementDict = [dict objectForKey:element];
            if (elementDict) {
                SPUserResizableView *v = [[SPUserResizableView alloc] initWithFrame:[[elementDict objectForKey:@"rect"] CGRectValue]];
                TItleElementView *c = [[TItleElementView alloc] initWithFrame:CGRectMake(0,0,v.bounds.size.width, v.bounds.size.height)];
                c.element = element;
                c.textStr = [elementDict objectForKey:@"text"];
                c.font = [UIFont fontWithName:currentFont size:[[elementDict objectForKey:@"pointSize"] floatValue]];
                v.delegate = self;
                v.tag = [elements indexOfObject:element];
                [v setContentView:c];
                
                [elementViews setObject:v forKey:element];
                [bg addSubview:v];
                [bg bringSubviewToFront:v];
                [elements addObject:element];
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.preferredContentSize= CGSizeMake(568,320);
   
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationItem.title = @"Title Editor";
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedCancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedClose)];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(useBackgroundImage:) name:@"updateEngineDetailList" object:nil];
    self.navigationController.toolbarHidden = NO;
  
    [self setupToolbar];
    
    elementViews = [@{ } mutableCopy];
    elements = [@[] mutableCopy];
    
    bg.layer.borderWidth = 2.0f;
    bg.layer.borderColor = [UIColor whiteColor].CGColor;
    
}

-(void)setupToolbar {
    
    if (!currentFont) {
        currentFont = @"Optima-Bold";
    }
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [UIFont fontWithName:currentFont size:17], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    self.navigationController.navigationBar.titleTextAttributes = strAttr;
    
    self.toolbarItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Background" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedBGButton)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Font" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedFontButton)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Elements" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedElementsButton)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Text" style:UIBarButtonItemStylePlain target:self action:@selector(userTappedTextButton)],
                          ];

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
    [fontIncrease removeFromSuperview];
    [fontDecrease removeFromSuperview];
    
    CGFloat xPos = self.view.frame.size.width - 56;
    
    CGFloat yPos = (320*0.333f) - 25;
    
    fontIncrease = [self installButtonAtRect:CGRectMake(xPos, yPos, 55,50) andTag:10];
    yPos  = (320*0.667f) - 25;
    fontDecrease = [self installButtonAtRect:CGRectMake(xPos, yPos, 55,50) andTag:11];
 
    
    NSString *bColor = @"#666666";
    NSString *eColor = @"#333333";
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    
    NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                              [UIFont systemFontOfSize:12], NSFontAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, nil
                              ];
    
    NSAttributedString *buttonStr = [[NSAttributedString alloc] initWithString:@"A-" attributes:strAttr];
    [fontDecrease setTitle:buttonStr disabledTitle:buttonStr beginGradientColorString:bColor endGradientColor:eColor];
    fontDecrease.enabled = YES;
    fontDecrease.delegate = self;
    [fontDecrease update];
    
    buttonStr = [[NSAttributedString alloc] initWithString:@"A+" attributes:strAttr];
    [fontIncrease setTitle:buttonStr disabledTitle:buttonStr beginGradientColorString:bColor endGradientColor:eColor];
    fontIncrease.enabled = YES;
    fontIncrease.delegate = self;
    [fontIncrease update];
    
    
    [self.view addSubview:fontIncrease];
    [self.view addSubview:fontDecrease];
    
    if (self.view.frame.size.width == 568.0f) {
        bg.frame = CGRectMake(62, 35, 444, 250);
    } else if (self.view.frame.size.width == 480.0f) {
        bg.frame = CGRectMake(0, 35, 444, 250);
    }

    if (self.pageToLoad) {
        [self loadTitlePage:self.pageToLoad];
        self.pageToLoad = nil;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        bg.frame = CGRectMake(62,50, 444, 250);
    }
 
}

-(void)userTappedElementsButton {
    [self showFeatureViewForOption:@"elements"];
}

-(void)userTappedFontButton {
    [self showFeatureViewForOption:@"font"];
}


-(void)userTappedTextButton {
    if (!currentElement) {
        return;
    }
    
    if (![currentElement isEqualToString:@"custom"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Editable" message:@"This field is updated at the time of recording." delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [self showFeatureViewForOption:@"text"];
}

-(void)userTappedCancel {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)useBackgroundImage:(NSNotification *)n {
    picPath = n.object;
    
    if (picPath) {
        bg.image =  [UIImage imageWithContentsOfFile:[[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] stringByAppendingPathComponent:picPath]];
    } else {
        bg.image = nil;
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)userTappedBGButton {
    ImportImageViewController *vc = [[ImportImageViewController alloc] initWithNibName:@"ImportImageViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)closeFeatureView {
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ featureView] ];
    
 
    UIView *dSub = [featureView.subviews objectAtIndex:0];
        
    for (UIView *v in dSub.subviews) {
        if ([v isKindOfClass:[UITextView class]]) {
                [v resignFirstResponder];
            }
        }
    
    [featureAnimator removeAllBehaviors];
    [featureAnimator addBehavior:gravity];
    
}

-(GradientAttributedButton *)installButtonAtRect:(CGRect)rect andTag:(NSInteger)tag {
    GradientAttributedButton *button = [[GradientAttributedButton alloc] initWithFrame:rect];
    button.delegate = self;
    button.tag = tag;
    return button;
}


-(void)showFeatureViewForOption:(NSString *)whichOne {
    if (featureAnimator) {
        [featureAnimator removeAllBehaviors];
        featureAnimator = nil;
    }
    if (featureView) {
        featureViewTV = nil;
        [featureView removeFromSuperview];
        featureView = nil;
    }
    
    [self makeFeatureViewForOption:whichOne];
    
    featureAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ featureView ] ];
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[ featureView ] ];
    
    CGFloat bottomY = self.view.frame.size.height - 35;
    
    [collision addBoundaryWithIdentifier:@"detailView" fromPoint:CGPointMake(0, bottomY) toPoint:CGPointMake(self.view.frame.size.width, bottomY)];
    
    [featureAnimator addBehavior:gravity];
    [featureAnimator addBehavior:collision];
    
    if ([whichOne isEqualToString:@"font"]) {
        [self performSelectorInBackground:@selector(buildFontList) withObject:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (tableView.tag) {
        case 0:
        {
            UITableViewCell *cell = [featureViewTV cellForRowAtIndexPath:indexPath];
            NSString *elementName = [[[SettingsTool settings] masterTitlingElementList] objectAtIndex:indexPath.row];
            if ([elements indexOfObject:elementName] == NSNotFound) {
                [elements addObject:elementName];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                [elements removeObject:elementName];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
            break;
        case 1:
        {
            NSString *fontName = [fontList objectAtIndex:indexPath.row];
            currentFont = fontName;
            [tableView reloadData];
        }
            break;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    
    switch (tableView.tag) {
        case 0:
            count = [[[SettingsTool settings] masterTitlingElementList] count];
            break;
        case 1:
            count = [fontList count];
            break;
    }
    
	return count;
}

-(NSArray *)engineImageList {
    NSFileManager *fM = [[NSFileManager alloc] init];
    NSError *error = nil;
    
    NSArray *list = [fM  contentsOfDirectoryAtPath:[[[UtilityBag bag] docsPath] stringByAppendingPathComponent:@"backgroundPages"] error:&error];
    
    if (list) {
        return list;
    }
    
    return @[ ];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (tableView.tag == 0) {
        NSString *elementName = [[[SettingsTool settings] masterTitlingElementList] objectAtIndex:indexPath.row];
        cell.textLabel.text = elementName;
        cell.accessoryType = ([elements indexOfObject:elementName] == NSNotFound) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    } else if (tableView.tag == 1) {
        NSString *fontName = [fontList objectAtIndex:indexPath.row];
        cell.textLabel.text = fontName;
        cell.textLabel.font = [UIFont fontWithName:fontName size:17];
        cell.accessoryType = [currentFont isEqualToString:fontName] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }

    return cell;
}


-(void)userTappedDetailView:(UIGestureRecognizer *)g {
    if ((g) && (g.state != UIGestureRecognizerStateEnded) ) {
        return;
    }
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ featureView] ];
    
    [featureAnimator removeAllBehaviors];
    [featureAnimator addBehavior:gravity];
}

-(void)installDetailHeaderAtIndex:(NSInteger)index  subView:(UIView *)v withTitle:(NSString *)title LMR:(NSInteger)lmr {
    
    CGFloat x = 0;
    CGFloat w = v.bounds.size.width;
    
    if (lmr > 0) { // left half
        w = ( v.bounds.size.width / 2.0f) - 10;
    }
    
    if (lmr == 2) {
        x =  (v.bounds.size.width / 2.0f);
    }
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, 10 + (75 *index), w, 25)];
    l.text = title;
    l.font = [UIFont systemFontOfSize:15];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    [v addSubview:l];
}


-(void)makeFeatureViewForOption:(NSString *)whichOne {
    if (featureView) {
            // NSLog(@"detail view already present");
        return;
    }
    
    if ([whichOne isEqualToString:@"elements"]) {
        CGRect f = CGRectMake((self.view.frame.size.width / 2.0f) - (350 / 2.0f),0,350,250);
        
        featureView = [[UIView alloc] initWithFrame:CGRectMake(f.origin.x, 0 - f.size.height, f.size.width, f.size.height)];
        featureView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        
        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        [featureView addSubview:dSub];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Titling Elements" LMR:0];
        
        featureViewTV = [[UITableView alloc] initWithFrame:CGRectMake(0,42,dSub.bounds.size.width,dSub.bounds.size.height - 42)];
        [featureViewTV setTintColor:[UIColor blackColor]];
        featureViewTV.tag = 0;
        featureViewTV.delegate = self;
        featureViewTV.dataSource = self;
        [dSub addSubview:featureViewTV];
        
        
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        button = [self installButtonAtRect:CGRectMake(f.size.width - 85 ,0,80,40) andTag:10700];
        title = [[NSAttributedString alloc] initWithString:@"Done" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        button.tag = 0;
        [dSub addSubview:button];
    } else if ([whichOne isEqualToString:@"font"]) {
        CGRect f = CGRectMake((self.view.frame.size.width / 2.0f) - (350 / 2.0f),0,350,250);
        
        featureView = [[UIView alloc] initWithFrame:CGRectMake(f.origin.x, 0 - f.size.height, f.size.width, f.size.height)];
        featureView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        
        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [featureView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:@"Font" LMR:0];
        
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.center = dSub.center;
        [dSub addSubview:activityView];
        activityView.tag = 555;
        [activityView startAnimating];
        
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        button = [self installButtonAtRect:CGRectMake(f.size.width - 85 ,0 ,80,40) andTag:10700];
        title = [[NSAttributedString alloc] initWithString:@"Done" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        button.tag = 1;
        [dSub addSubview:button];
   
        
    } else if ([whichOne isEqualToString:@"text"]) {
        CGRect f = CGRectMake((self.view.frame.size.width / 2.0f) - (350 / 2.0f),0,350,250);
        
        featureView = [[UIView alloc] initWithFrame:CGRectMake(f.origin.x, 0 - f.size.height, f.size.width, f.size.height)];
        featureView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        
        UIView *dSub = [[UIView alloc] initWithFrame:featureView.bounds];
        dSub.backgroundColor = [[UtilityBag bag] colorWithHexString:@"#888888"];
        [featureView addSubview:dSub];
        [self installDetailHeaderAtIndex:0 subView:dSub withTitle:[NSString stringWithFormat:@"Text For %@", currentElement] LMR:0];
        
        GradientAttributedButton *button = nil;
        NSAttributedString *title = nil;
        
        NSString *bColor = @"#666666";
        NSString *eColor = @"#333333";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        
        NSDictionary *strAttr =  [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                  [[UtilityBag bag] standardFont], NSFontAttributeName,
                                  paragraphStyle, NSParagraphStyleAttributeName, nil
                                  ];
        
        button = [self installButtonAtRect:CGRectMake(f.size.width - 85 ,0 ,80,40) andTag:10700];
        title = [[NSAttributedString alloc] initWithString:@"Done" attributes:strAttr];
        [button setTitle:title disabledTitle:title beginGradientColorString:bColor endGradientColor:eColor];
        button.enabled = YES;
        [button update];
        button.tag = 1;
        [dSub addSubview:button];
        
        UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(0,42,dSub.bounds.size.width,80)];
        tv.delegate = self;
        SPUserResizableView *v = [elementViews objectForKey:currentElement];
        TItleElementView *t = (TItleElementView *)v.cv;
        tv.font = [t.font fontWithSize:12.0f];
        tv.text = t.textStr;
        [dSub addSubview:tv];
        [tv performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:1.0f];
    }
    
    [self.view addSubview:featureView];
    [self.view bringSubviewToFront:featureView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    NSString *textStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    SPUserResizableView *v = [elementViews objectForKey:currentElement];
    TItleElementView *t = (TItleElementView *)v.cv;
    t.textStr = textStr;
    [t setNeedsDisplay];
    return YES;
}

-(CGRect)rectForNewElement:(NSString *)name {
    CGRect r = CGRectZero;
    
    if ([name isEqualToString:@"title"]) {
        r = CGRectMake(0, 25, bg.frame.size.width, 50);
    } else if ([name isEqualToString:@"author"]) {
        r = CGRectMake(50, 105, 150, 50);
    } else if ([name isEqualToString:@"Date+Time"]) {
        r = CGRectMake(250, 105, 150, 50);
    } else if ([name isEqualToString:@"location"]) {
        r = CGRectMake(50, 155, 150, 50);
    } else if ([name isEqualToString:@"scene"]) {
        r = CGRectMake(250, 155, 150, 50);
    } else if ([name isEqualToString:@"take"]) {
        r = CGRectMake(50, 205, 150, 50);
    } else if ([name isEqualToString:@"custom"]) {
        r = CGRectMake(250, 205, 150, 50);
    }
    
    return r;
}

-(void)userPanned:(UIPanGestureRecognizer *)g {
    static CGPoint beginPoint;
    static CGRect beginFrame;
    
    if (g.state == UIGestureRecognizerStateBegan) {
        beginPoint = [g locationInView:self.view];
        beginFrame = g.view.frame;
    } else {
        CGPoint p = [g locationInView:self.view];
        
        CGPoint t = CGPointMake(beginPoint.x - p.x, beginPoint.y - p.y);
        
        CGRect newFrame = CGRectMake(beginFrame.origin.x - t.x, beginFrame.origin.y - t.y, beginFrame.size.width, beginFrame.size.height);
        
        if (newFrame.origin.x < 0.0f) {
            newFrame.origin.x = 0.0f;
        }
        
        if (newFrame.origin.y < 0.0f) {
            newFrame.origin.y = 0.0f;
        }
        
        if (newFrame.origin.x + newFrame.size.width > bg.bounds.size.width) {
            newFrame.size.width = bg.bounds.size.width - newFrame.origin.x;
        }
        
        if (newFrame.origin.y + newFrame.size.height > bg.bounds.size.height) {
            newFrame.size.height = bg.bounds.size.height - newFrame.origin.y;
        }
        
        g.view.frame = newFrame;
    }

}

CGPoint CGPointDistance(CGPoint point1, CGPoint point2) {
    return CGPointMake(point2.x - point1.x, point2.y - point1.y);
}

-(void)userPinched:(UIPinchGestureRecognizer *)g {
    static CGRect originalRect;
    static CGPoint originalLoc;
    
    CGFloat maxScale = bg.bounds.size.width / g.view.bounds.size.width;
    CGFloat maxY = bg.bounds.size.height / g.view.bounds.size.height;
   
    if (maxY < maxScale) {
        maxScale = maxY;
    }
    
    CGFloat newScale = g.scale;
    
    if (newScale > maxScale) {
        newScale = maxScale;
    }
    
    if (newScale < 0.25f) {
        newScale = 0.25f;
    }
    
    if (g.state == UIGestureRecognizerStateBegan) {
        originalRect = g.view.frame;
        originalLoc = [g locationInView:self.view];
    } else {
        CGRect newRect = CGRectMake(originalRect.origin.x, originalRect.origin.y, originalRect.size.width * newScale, originalRect.size.height * newScale);
        
        if (newRect.origin.x < 0.0f) {
            newRect.origin.x = 0.0f;
        }
        
        if (newRect.origin.y < 0.0f) {
            newRect.origin.y = 0.0f;
        }
        
        if (newRect.origin.x + newRect.size.width > bg.bounds.size.width) {
            newRect.size.width = bg.bounds.size.width - newRect.origin.x;
        }
        
        if (newRect.origin.y + newRect.size.height > bg.bounds.size.height) {
            newRect.size.height = bg.bounds.size.height - newRect.origin.y;
        }

        g.view.frame = newRect;
    }
}


-(void)updateElements {
    for (NSString *str in [[SettingsTool settings] masterTitlingElementList]) {
        SPUserResizableView *v = [elementViews objectForKey:str];
        if (v && [elements indexOfObject:str] == NSNotFound)  {
            [v removeFromSuperview];
            [elementViews removeObjectForKey:str];
        }
    }
    
    for (NSString *str in elements) {
        SPUserResizableView *v = [elementViews objectForKey:str];
        if (!v) {
            v = [[SPUserResizableView alloc] initWithFrame:[self rectForNewElement:str]];
            TItleElementView *c = [[TItleElementView alloc] initWithFrame:CGRectMake(0,0,v.bounds.size.width, v.bounds.size.height)];
            c.element = str;
            c.font = [UIFont fontWithName:currentFont size:12.0];
            v.delegate = self;
            v.tag = [elements indexOfObject:str];
            [v setContentView:c];
            
            [elementViews setObject:v forKey:str];
        }
        
        [bg addSubview:v];
        [bg bringSubviewToFront:v];
    }
}


- (void)userResizableViewDidBeginEditing:(SPUserResizableView *)userResizableView {
    for (SPUserResizableView *v in [elementViews allValues]) {
        if (![v isEqual:userResizableView]) {
            [v hideEditingHandles];
        }
    }
    
    TItleElementView *t = (TItleElementView *)userResizableView.cv;
    currentElement = t.element;
}

- (void)userResizableViewDidEndEditing:(SPUserResizableView *)userResizableView {
    TItleElementView *t = (TItleElementView *)userResizableView.cv;

    [t setNeedsDisplay];
}


-(void)userPressedGradientAttributedButtonWithTag:(NSInteger)tag {
    switch (tag) {
        case 0:
        {
            [self updateElements];
            [self closeFeatureView];
        }
            break;
        case 1:
        {
            for (NSString *str in [[SettingsTool settings] masterTitlingElementList]) {
                SPUserResizableView *v = [elementViews objectForKey:str];
                if (v)  {
                    TItleElementView *t = (TItleElementView *)v.cv;
                    CGFloat pointSize = t.font.pointSize;
                    t.font = [UIFont fontWithName:currentFont size:pointSize];
                    [t setNeedsDisplay];
                }
            }
            
            [self setupToolbar];
            [self closeFeatureView];
        }
            break;
        case 10: //font increase
        {
            if (!currentElement) {
                return;
            }
            
            SPUserResizableView *v = [elementViews objectForKey:currentElement];
            TItleElementView *t = (TItleElementView *)v.cv;
            
            CGFloat size = t.font.pointSize + 0.5f;
            
            if (size > 128.0f) {
                size = 128.0f;
            }
            
            t.font  = [t.font fontWithSize:size];
            [t setNeedsDisplay];
        }
            break;
        case 11: //font decrease
        {
            if (!currentElement) {
                return;
            }
            
            SPUserResizableView *v = [elementViews objectForKey:currentElement];
            TItleElementView *t = (TItleElementView *)v.cv;
            
            CGFloat size = t.font.pointSize - 0.5f;
            
            if (size < 8.0f) {
                size = 8.0f;
            }
            
            t.font  = [t.font fontWithSize:size];
            [t setNeedsDisplay];
        }
            break;

    }
}

-(void)buildFontList {
	NSArray *fontNameList = [UIFont familyNames];
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (NSString *fontFamilyName in fontNameList) {
        for (NSString *fontName in [UIFont fontNamesForFamilyName:fontFamilyName]) {
            [list addObject:fontName];
        }
        
    }
    
	fontList = [[list copy] sortedArrayUsingComparator: ^(id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2];
	}];

    [self performSelectorOnMainThread:@selector(showFontList) withObject:nil waitUntilDone:YES];
}

-(void)showFontList {
    UIView *dSub = [featureView.subviews objectAtIndex:0];
    
    for (UIView *v in dSub.subviews) {
        if ([v isKindOfClass:[UIActivityIndicatorView class]]) {
            [v removeFromSuperview];
        }
    }
     
    featureViewTV = [[UITableView alloc] initWithFrame:CGRectMake(0,42,dSub.bounds.size.width,dSub.bounds.size.height - 42)];
    [featureViewTV setTintColor:[UIColor blackColor]];
    featureViewTV.tag = 1;
    featureViewTV.delegate = self;
    featureViewTV.dataSource = self;
    [dSub addSubview:featureViewTV];
}




@end
