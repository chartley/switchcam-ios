//
//  SPInviteFriendsTableDataSource.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/26/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "SPInviteFriendsTableDataSource.h"
#import "InviteFriendCell.h"

// Magic number - iPhone address book doesn't show scrubber for less than 5 contacts
static const NSInteger kMinimumCountToCollate = 6;

@implementation SPInviteFriendsTableDataSource

#pragma mark - Private Methods

- (FBGraphObjectTableCell *)cellWithTableView:(UITableView *)tableView
{
    static NSString * const cellKey = @"fbTableCell";
    InviteFriendCell *cell =
    (InviteFriendCell*)[tableView dequeueReusableCellWithIdentifier:cellKey];
    
    if (!cell) {
        cell = [[InviteFriendCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kInviteFriendCellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    InviteFriendCell *cell = (InviteFriendCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        [cell.fbUserSelectedButton setSelected:YES];
    } else {
        [cell.fbUserSelectedButton setSelected:NO];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

@end
