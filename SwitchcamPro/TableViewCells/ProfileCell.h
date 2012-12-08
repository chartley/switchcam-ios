//
//  ProfileCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/5/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kProfileCellIdentifier @"ProfileCellIdentifier"
#define kProfileCellRowHeight 44

@interface ProfileCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UILabel *profileNameLabel;

@end
