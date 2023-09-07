//
//  CameraViewController.h
//  Cloud Director
//
//  Created by Gary Barnett on 12/26/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface CameraViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) NSString *cameraID;

-(void)handlePreviewImage:(NSData *)previewData;

@end
