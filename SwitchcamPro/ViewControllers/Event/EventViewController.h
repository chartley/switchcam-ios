//
//  EventViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SPTabView.h"
#import "SCCamViewController.h"

@class Mission;
@class SPTabsViewController;
@class SPTabStyle;
@class SPTabsView;
@class UIPlaceHolderTextView;

@interface EventViewController : UIViewController <SPTabViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, SCCamViewControllerDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate> {
    NSArray *viewControllers;
    SPTabsView *tabsContainerView;
    SPTabStyle *tabStyle;
    NSUInteger currentTabIndex;
}

@property (nonatomic, retain) SPTabStyle *style;
@property (strong, nonatomic) Mission *mission;
@property (strong, nonatomic) IBOutlet UIView *toolbarDrawer;
@property (strong, nonatomic) IBOutlet UIButton *sharePhotoButton;
@property (strong, nonatomic) IBOutlet UILabel *sharePhotoLabel;
@property (strong, nonatomic) IBOutlet UIButton *shareNoteButton;
@property (strong, nonatomic) IBOutlet UIImageView *shareNoteButtonBackground;
@property (strong, nonatomic) IBOutlet UILabel *shareNoteLabel;
@property (strong, nonatomic) IBOutlet UIPlaceHolderTextView *shareNoteTextView;
@property (strong, nonatomic) IBOutlet UIButton *postNoteButton;


@property (strong, nonatomic) IBOutlet UILabel *eventLocationLabel;
@property (strong, nonatomic) IBOutlet UILabel *eventDateLabel;
@property (strong, nonatomic) IBOutlet UIImageView *eventImageView;
@property (strong, nonatomic) IBOutlet UIScrollView *eventScrollView;

@property (strong, nonatomic) IBOutlet UIView *shareDrawer;
@property (strong, nonatomic) IBOutlet UIButton *shareFacebookButton;
@property (strong, nonatomic) IBOutlet UIButton *shareTwitterButton;
@property (strong, nonatomic) IBOutlet UIButton *shareEmailButton;
@property (strong, nonatomic) IBOutlet UIButton *inviteFacebookFriendsButton;
@property (strong, nonatomic) IBOutlet UILabel *shareDrawerLabel;


- (id)initWithViewControllers:(NSArray *)viewControllers
                        style:(SPTabStyle *)style;
- (id)initWithMission:(Mission*)mission;

- (void)showParticipateDrawer;
- (void)hideParticipateDrawer;
- (void)moveTabsToTop;

@end