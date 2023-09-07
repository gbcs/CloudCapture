//
//  PhotoEditView.m
//  Capture
//
//  Created by Gary  Barnett on 3/26/14.
//  Copyright (c) 2014 Gary Barnett. All rights reserved.
//

#import "PhotoEditView.h"

@implementation PhotoEditView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)dealloc {
    CGImageRelease(_image);
    _image = nil;
}

-(void)useImage:(CGImageRef )updatedImage {
    if (_image) {
        CGImageRelease(_image);
    }
    CGImageRetain(updatedImage);
    _image = updatedImage;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, self.frame.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
       
    CGContextDrawImage(context, self.bounds, _image);
}


@end
