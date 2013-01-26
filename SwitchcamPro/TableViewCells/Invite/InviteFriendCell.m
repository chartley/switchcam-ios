//
//  InviteFriendCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/26/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import "InviteFriendCell.h"

static const CGFloat titleFontHeight = 16;
static const CGFloat subtitleFontHeight = 12;
static const CGFloat pictureEdge = 40;
static const CGFloat pictureMargin = 1;
static const CGFloat horizontalMargin = 4;
static const CGFloat titleTopNoSubtitle = 11;
static const CGFloat titleTopWithSubtitle = 3;
static const CGFloat subtitleTop = 23;
static const CGFloat titleHeight = titleFontHeight * 1.25;
static const CGFloat subtitleHeight = subtitleFontHeight * 1.25;

@interface InviteFriendCell ()

@property (nonatomic, retain) UIImageView *pictureView;
@property (nonatomic, retain) UILabel* titleSuffixLabel;

@end

@implementation InviteFriendCell

@synthesize titleSuffixLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        [self.contentView setBackgroundColor:[UIColor clearColor]];
        
        // Add button
        self.fbUserSelectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.fbUserSelectedButton setFrame:CGRectMake(260, 10, 23, 24)];
        [self.fbUserSelectedButton setImage:[UIImage imageNamed:@"icn-unselected"] forState:UIControlStateNormal];
        [self.fbUserSelectedButton setImage:[UIImage imageNamed:@"icn-selected"] forState:UIControlStateSelected];
        [self.fbUserSelectedButton setUserInteractionEnabled:NO];
        [self.contentView addSubview:self.fbUserSelectedButton];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateFonts {
    if (self.boldTitle) {
        self.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    } else {
        self.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    }
    
    if (self.boldTitleSuffix) {
        self.titleSuffixLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    } else {
        self.titleSuffixLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    }
    
    [self.textLabel setTextColor:[UIColor whiteColor]];
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    [self.titleSuffixLabel setTextColor:[UIColor whiteColor]];
    [self.titleSuffixLabel setBackgroundColor:[UIColor clearColor]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateFonts];
    
    BOOL hasPicture = (self.picture != nil);
    BOOL hasSubtitle = (self.subtitle != nil);
    BOOL hasTitleSuffix = (self.titleSuffix != nil);
    
    CGFloat pictureWidth = hasPicture ? pictureEdge : 0;
    CGSize cellSize = self.contentView.bounds.size;
    CGFloat textLeft = (hasPicture ? ((2 * pictureMargin) + pictureWidth) : 0) + horizontalMargin;
    CGFloat textWidth = cellSize.width - (textLeft + 30);  // Extra room for custom checkbox
    CGFloat titleTop = hasSubtitle ? titleTopWithSubtitle : titleTopNoSubtitle;
    
    self.pictureView.frame = CGRectMake(pictureMargin, pictureMargin, pictureEdge, pictureWidth);
    self.detailTextLabel.frame = CGRectMake(textLeft, subtitleTop, textWidth, subtitleHeight);
    if (!hasTitleSuffix) {
        self.textLabel.frame = CGRectMake(textLeft, titleTop, textWidth, titleHeight);
    } else {
        CGSize titleSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
        CGSize spaceSize = [@" " sizeWithFont:self.textLabel.font];
        CGFloat titleWidth = titleSize.width + spaceSize.width;
        self.textLabel.frame = CGRectMake(textLeft, titleTop, titleWidth, titleHeight);
        
        CGFloat titleSuffixLeft = textLeft + titleWidth;
        CGFloat titleSuffixWidth = textWidth - titleWidth;
        self.titleSuffixLabel.frame = CGRectMake(titleSuffixLeft, titleTop, titleSuffixWidth, titleHeight);
    }
    
    [self.pictureView setHidden:!(hasPicture)];
    [self.detailTextLabel setHidden:!(hasSubtitle)];
    [self.titleSuffixLabel setHidden:!(hasTitleSuffix)];
}

@end
