//
//  ActivityVideoCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ActivityVideoCell.h"

@implementation ActivityVideoCell

- (void)awakeFromNib {
    // Thumbnail border
    [self.videoThumbnailImageView.layer setCornerRadius:5.0f];
    [self.videoThumbnailImageView.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.videoThumbnailImageView.layer setBorderWidth:1.5f];
    [self.videoThumbnailImageView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.videoThumbnailImageView.layer setShadowOpacity:0.8];
    [self.videoThumbnailImageView.layer setShadowRadius:3.0];
    [self.videoThumbnailImageView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    [self.videoThumbnailImageView.layer setMasksToBounds:YES];
}

@end
