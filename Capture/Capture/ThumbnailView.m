//
//  ThumbnailView.m
//  Capture
//
//  Created by Gary Barnett on 9/7/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import "ThumbnailView.h"

@implementation ThumbnailView {
    CGImageRef _image;
}

-(CGImageRef )currentImage {
    return _image;
}

-(void)dealloc {
    while ([self.subviews count]>0) {
        UIView *v = [self.subviews objectAtIndex:0];
        [v removeFromSuperview];
    }
    
    CGImageRelease(_image);
    _image = nil;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}
-(void)setImage:(CGImageRef )image {
    if (_image) {
        CGImageRelease(_image);
    }
    _image = image;
    CGImageRetain(_image);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    CGRect imageRect = self.bounds;

    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, imageRect, _image);
    
}


@end
