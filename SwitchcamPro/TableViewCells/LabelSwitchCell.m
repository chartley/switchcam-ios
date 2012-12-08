//
//  LabelSwitchCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "LabelSwitchCell.h"

@implementation LabelSwitchCell

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

@end
