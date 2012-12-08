//
//  MenuItemCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/5/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kMenuItemCellIdentifier @"MenuItemCellIdentifier"
#define kMenuItemCellRowHeight 44

@interface MenuItemCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *leftLabel;

@end
