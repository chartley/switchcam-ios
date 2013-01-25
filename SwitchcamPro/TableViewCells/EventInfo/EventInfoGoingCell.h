//
//  EventInfoGoingCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/23/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kEventInfoGoingCellIdentifier @"EventInfoGoingCellIdentifier"
#define kEventInfoGoingCellRowHeight 138

@interface EventInfoGoingCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIButton *imGoingButton;
@property (strong, nonatomic) IBOutlet UIButton *imNotGoingButton;
@property (strong, nonatomic) IBOutlet UILabel *goingDetailLabel;

@end
