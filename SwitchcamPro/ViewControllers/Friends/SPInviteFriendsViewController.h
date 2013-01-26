//
//  SPInviteFriendsViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/26/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FBFriendPickerViewController.h>

@interface SPInviteFriendsViewController : FBFriendPickerViewController <UISearchBarDelegate, FBViewControllerDelegate>

@property (nonatomic, setter=setTagging:) BOOL isTagging;

@end
