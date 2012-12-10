//
//  LabelInvisibleButtonCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kLabelInvisibleButtonCellIdentifier @"LabelInvisibleButtonCellIdentifier"
#define kLabelInvisibleButtonCellRowHeight 44

@interface LabelInvisibleButtonCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *leftLabel;
@property (strong, nonatomic) IBOutlet UIButton *invisibleButton;

@end
