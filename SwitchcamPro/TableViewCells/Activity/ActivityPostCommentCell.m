//
//  ActivityPostCommentCell.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/15/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ActivityPostCommentCell.h"

@implementation ActivityPostCommentCell

- (void)awakeFromNib {
    UIBezierPath *maskPath;
    maskPath = [UIBezierPath bezierPathWithRoundedRect:self.commentBubbleBackground.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(5.0, 5.0)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.commentBubbleBackground.layer.mask = maskLayer;
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
