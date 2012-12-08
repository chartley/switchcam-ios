//
//  LabelSubLabelCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kLabelSubLabelCellIdentifier @"LabelSubLabelCellIdentifier"
#define kLabelSubLabelCellRowHeight 44

@interface LabelSubLabelCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *leftLabel;
@property (strong, nonatomic) IBOutlet UILabel *rightLabel;

@end
