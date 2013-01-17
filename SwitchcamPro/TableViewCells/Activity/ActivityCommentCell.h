//
//  ActivityCommentCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/15/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityCell.h"

#define kActivityCommentCellIdentifier @"ActivityCommentCellIdentifier"
#define kActivityCommentCellRowHeight 62

@interface ActivityCommentCell : ActivityCell

@property (strong, nonatomic) IBOutlet UILabel *commentLabel;
@property (strong, nonatomic) IBOutlet UIView *commentBubbleBackground;

@end
