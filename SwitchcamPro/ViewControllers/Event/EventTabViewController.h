//
//  EventTabViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/10/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventViewController.h"

@class Mission;

@interface EventTabViewController : UIViewController

@property (strong, nonatomic) IBOutlet Mission *selectedMission;
@property (strong, nonatomic) IBOutlet UIScrollView *tabScrollView;
@property (strong, nonatomic) EventViewController *eventViewController;

// Pagination
@property (strong, nonatomic) IBOutlet UIView *loadMoreView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet UILabel *loadMoreLabel;
@property (strong, nonatomic) IBOutlet UIButton *loadMoreButton;


@end
