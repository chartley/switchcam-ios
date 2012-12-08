//
//  LabelSwitchCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kLabelSwitchCellIdentifier @"LabelSwitchCellIdentifier"
#define kLabelSwitchCellRowHeight 44

@interface LabelSwitchCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *leftLabel;
@property (strong, nonatomic) IBOutlet UISwitch *staySignedInSwitch;

@end
