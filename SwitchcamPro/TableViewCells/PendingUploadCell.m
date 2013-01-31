//
//  PendingUploadCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PendingUploadCell.h"
#import "SPConstants.h"

@implementation PendingUploadCell

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
    
    // Set Fonts
    [self.previewLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:12]];
    [self.previewLabel setTextColor:[UIColor whiteColor]];
    [self.previewLabel setShadowColor:[UIColor blackColor]];
    [self.previewLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.uploadLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:12]];
    [self.uploadLabel setTextColor:[UIColor whiteColor]];
    [self.uploadLabel setShadowColor:[UIColor blackColor]];
    [self.uploadLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.deleteLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:12]];
    [self.deleteLabel setTextColor:[UIColor whiteColor]];
    [self.deleteLabel setShadowColor:[UIColor blackColor]];
    [self.deleteLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.pendingUploadCountLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
    [self.pendingUploadCountLabel setTextColor:[UIColor whiteColor]];
    [self.pendingUploadCountLabel setShadowColor:[UIColor blackColor]];
    [self.pendingUploadCountLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.pendingUploadLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:15]];
    [self.pendingUploadLabel setTextColor:[UIColor whiteColor]];
    [self.pendingUploadLabel setShadowColor:[UIColor blackColor]];
    [self.pendingUploadLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.pendingUploadTimeLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
    [self.pendingUploadTimeLabel setTextColor:[UIColor whiteColor]];
    [self.pendingUploadTimeLabel setShadowColor:[UIColor blackColor]];
    [self.pendingUploadTimeLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.pendingUploadLengthLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:13]];
    [self.pendingUploadLengthLabel setTextColor:RGBA(105, 105, 105, 1)];
    [self.pendingUploadLengthLabel setShadowColor:[UIColor blackColor]];
    [self.pendingUploadLengthLabel setShadowOffset:CGSizeMake(0, -1)];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Button Actions

- (IBAction)previewButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(previewButtonPressed:)]) {
		[self.delegate performSelector:@selector(previewButtonPressed:) withObject:self];
	}
}

- (IBAction)uploadButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(uploadButtonPressed:)]) {
		[self.delegate performSelector:@selector(uploadButtonPressed:) withObject:self];
	}
}

- (IBAction)deleteButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(deleteButtonPressed:)]) {
		[self.delegate performSelector:@selector(deleteButtonPressed:) withObject:self];
	}
}

@end
