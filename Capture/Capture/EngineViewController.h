//
//  EngineViewController.h
//  Capture
//
//  Created by Gary Barnett on 7/27/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EngineViewController : UIViewController <GradientAttributedButtonDelegate, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    __weak IBOutlet UIImageView *chromaKeySetup;
    __weak IBOutlet UIImageView *headphone;
    __weak IBOutlet UIImageView *audioDisk;
    __weak IBOutlet UIImageView *microphone;
    __weak IBOutlet UIImageView *histogram;
    __weak IBOutlet UIImageView *overlaySetup;
    __weak IBOutlet UIImageView *preview;
    __weak IBOutlet UIImageView *disk;
    __weak IBOutlet UIImageView *remote;
    __weak IBOutlet UIImageView *titling;
    __weak IBOutlet UIImageView *overlay;
    __weak IBOutlet UIImageView *imageEffect;
    __weak IBOutlet UIImageView *colorControl;
    __weak IBOutlet UIImageView *chromaKey;
    __weak IBOutlet UIImageView *camera;
    __weak IBOutlet UIImageView *remoteSetup;
    __weak IBOutlet UIImageView *titlingSetup;

    __weak IBOutlet UIImageView *gain;
    __weak IBOutlet UIImageView *mode;
    __weak IBOutlet UIImageView *sampleRate;
    __weak IBOutlet UIImageView *encoding;
    __weak IBOutlet UIImageView *pattern;
    
}
@property (nonatomic, assign) BOOL directMode;
@property (nonatomic, assign) BOOL audioControlsOnly;
- (IBAction)userTappedClose:(id)sender;

@end
