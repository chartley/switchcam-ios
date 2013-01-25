//
//  EventInfoLinksCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/22/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kEventInfoLinksCellIdentifier @"EventInfoLinksCellIdentifier"
#define kEventInfoLinksCellRowHeight 60

@interface EventInfoLinksCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;

@end
