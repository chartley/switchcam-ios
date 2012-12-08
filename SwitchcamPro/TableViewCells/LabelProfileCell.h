//
//  LabelProfileCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kLabelProfileCellIdentifier @"LabelProfileCellIdentifier"
#define kLabelProfileCellRowHeight 44

@interface LabelProfileCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *leftLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UILabel *profileNameLabel;


@end
