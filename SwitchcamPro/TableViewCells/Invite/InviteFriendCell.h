//
//  InviteFriendCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/26/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FBGraphObjectTableCell.h>

#define kInviteFriendCellIdentifier @"InviteFriendCellIdentifier"
#define kInviteFriendCellRowHeight 44

@interface InviteFriendCell : FBGraphObjectTableCell

@property (strong, nonatomic) IBOutlet UIButton *fbUserSelectedButton;

@end
