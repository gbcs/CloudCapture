//
//  AzureViewController.h
//  Capture
//
//  Created by Gary Barnett on 1/29/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthenticationCredential.h"
#import "CloudStorageClient.h"
#import "BlobContainer.h"
#import "Blob.h"
#import "TableEntity.h"
#import "TableFetchRequest.h"



@protocol AzureUploaderActivityViewControllerDelegate <NSObject>
- (void)AzureDidFinish:(BOOL)completed;
@end

@interface AzureViewController : UIViewController <GradientAttributedButtonDelegate, UITextFieldDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, CloudStorageClientDelegate>
{
    AuthenticationCredential *credential;
    CloudStorageClient *client;
    NSArray *container;
    NSArray *blobArray;
}


@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, weak) id <AzureUploaderActivityViewControllerDelegate> delegate;

- (IBAction)userTappedUpload:(id)sender;
- (IBAction)userTappedCancel:(id)sender;

@end

