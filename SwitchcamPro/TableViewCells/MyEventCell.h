//
//  MyEventCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kMyEventCellIdentifier @""
#define kMyEventCellRowHeight 120

@interface MyEventCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *eventNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *eventLocationLabel;
@property (strong, nonatomic) IBOutlet UILabel *eventDateLabel;
@property (strong, nonatomic) IBOutlet UIButton *eventLocationButton;

@end
