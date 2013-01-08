//
//  ActivityNoteCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import "ActivityNoteCell.h"

@implementation ActivityNoteCell

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

- (IBAction)likeButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(likeButtonPressed:)]) {
		[self.delegate performSelector:@selector(likeButtonPressed:) withObject:self];
	}
}

- (IBAction)commentButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(commentButtonPressed:)]) {
		[self.delegate performSelector:@selector(commentButtonPressed:) withObject:self];
	}
}

@end
