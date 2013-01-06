//
//  EventViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPTabView.h"

@class Mission;
@class SPTabsViewController;
@class SPTabsFooterView;
@class SPTabStyle;
@class SPTabsView;

@interface EventViewController : UIViewController <SPTabViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate> {
    NSArray *viewControllers;
    SPTabsView *tabsContainerView;
    SPTabsFooterView *footerView;
    SPTabStyle *tabStyle;
    NSUInteger currentTabIndex;
}

@property (nonatomic, retain) SPTabStyle *style;
@property (strong, nonatomic) Mission *mission;
@property (strong, nonatomic) IBOutlet UIView *toolbarDrawer;
@property (strong, nonatomic) IBOutlet UIButton *sharePhotoButton;
@property (strong, nonatomic) IBOutlet UILabel *sharePhotoLabel;
@property (strong, nonatomic) IBOutlet UIButton *shareNoteButton;
@property (strong, nonatomic) IBOutlet UILabel *shareNoteLabel;
@property (strong, nonatomic) IBOutlet UILabel *eventLocationLabel;
@property (strong, nonatomic) IBOutlet UILabel *eventDateLabel;
@property (strong, nonatomic) IBOutlet UIImageView *eventImageView;
@property (strong, nonatomic) IBOutlet UIScrollView *eventScrollView;

- (id)initWithViewControllers:(NSArray *)viewControllers
                        style:(SPTabStyle *)style;
- (id)initWithMission:(Mission*)mission;

@end