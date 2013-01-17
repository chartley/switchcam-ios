//
//  ActivityPostCommentCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/15/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityCell.h"

#define kActivityPostCommentCellIdentifier @"ActivityPostCommentCellIdentifier"
#define kActivityPostCommentCellRowHeight 72

@interface ActivityPostCommentCell : ActivityCell

@property (strong, nonatomic) IBOutlet UITextField *commentTextField;
@property (strong, nonatomic) IBOutlet UIButton *postCommentButton;
@property (strong, nonatomic) IBOutlet UIView *commentBubbleBackground;

@end
