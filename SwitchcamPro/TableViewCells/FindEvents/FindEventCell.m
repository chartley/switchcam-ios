//
//  FindEventCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/28/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "FindEventCell.h"

@implementation FindEventCell

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

- (IBAction)joinButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(joinButtonPressed:)]) {
		[self.delegate performSelector:@selector(joinButtonPressed:) withObject:self];
	}
}

@end
