//
//  ButtonCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kButtonCellIdentifier @"ButtonCellIdentifier"
#define kButtonCellRowHeight 44

@interface ButtonCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIButton *bigButton;

@end
