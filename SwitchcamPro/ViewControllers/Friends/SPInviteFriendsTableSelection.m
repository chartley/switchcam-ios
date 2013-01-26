//
//  SPInviteFriendsTableSelection.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/26/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <FacebookSDK/FBUtility.h>
#import "SPInviteFriendsTableSelection.h"
#import "InviteFriendCell.h"

@interface SPInviteFriendsTableSelection ()

@property (nonatomic, retain) NSArray *selection;

@end

@implementation SPInviteFriendsTableSelection

- (void)selectItem:(FBGraphObject *)item
              cell:(UITableViewCell *)cell
{
    if ([FBUtility graphObjectInArray:self.selection withSameIDAs:item] == nil) {
        NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
        [selection addObject:item];
        self.selection = selection;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    [((InviteFriendCell*)cell).fbUserSelectedButton setSelected:YES];
    [self selectionChanged];
}

- (void)deselectItem:(FBGraphObject *)item
                cell:(UITableViewCell *)cell
{
    id<FBGraphObject> selectedItem = [FBUtility graphObjectInArray:self.selection withSameIDAs:item];
    if (selectedItem) {
        NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
        [selection removeObject:selectedItem];
        self.selection = selection;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    [((InviteFriendCell*)cell).fbUserSelectedButton setSelected:NO];
    [self selectionChanged];
}

- (void)selectionChanged
{
    if ([self.delegate respondsToSelector:
         @selector(graphObjectTableSelectionDidChange:)]) {
        // Let the table view finish updating its UI before notifying the delegate.
        [self.delegate performSelector:@selector(graphObjectTableSelectionDidChange:) withObject:self afterDelay:.1];
    }
}

@end
