//
//  EventInfoOrganizerCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/22/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kEventInfoOrganizerCellIdentifier @"EventInfoOrganizerCellIdentifier"
#define kEventInfoOrganizerCellRowHeight 60

@interface EventInfoOrganizerCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *organizerMessageLabel;
@property (strong, nonatomic) IBOutlet UIView *bottomSeparatorView;

@end
