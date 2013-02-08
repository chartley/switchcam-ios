//
//  ActivityPhotoCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ActivityPhotoCell.h"

@implementation ActivityPhotoCell

- (void)awakeFromNib {
    // Thumbnail border
    [self.photoThumbnailImageView.layer setCornerRadius:5.0f];
    [self.photoThumbnailImageView.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.photoThumbnailImageView.layer setBorderWidth:1.5f];
    [self.photoThumbnailImageView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.photoThumbnailImageView.layer setShadowOpacity:0.8];
    [self.photoThumbnailImageView.layer setShadowRadius:3.0];
    [self.photoThumbnailImageView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    [self.photoThumbnailImageView.layer setMasksToBounds:YES];
}

@end
