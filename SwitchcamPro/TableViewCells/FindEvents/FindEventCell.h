//
//  FindEventCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/28/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kFindEventCellIdentifier @"FindEventCellIdentifier"
#define kFindEventCellRowHeight 65

@class FindEventCell;

@protocol FindEventCellDelegate <NSObject>

- (void)joinButtonPressed:(FindEventCell*)findEventCell;

@end

@interface FindEventCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UILabel *detailLabel;
@property (strong, nonatomic) IBOutlet UIButton *joinButton;

@property (weak, nonatomic) id<FindEventCellDelegate> delegate;

@end
