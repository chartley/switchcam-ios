//
//  LabelTextFieldCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kLabelTextFieldCellIdentifier @"LabelTextFieldCellIdentifier"
#define kLabelTextFieldCellRowHeight 44

@interface LabelTextFieldCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *leftLabel;
@property (strong, nonatomic) IBOutlet UITextField *textField;

@end
