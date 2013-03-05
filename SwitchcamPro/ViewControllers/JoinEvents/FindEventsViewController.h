//
//  FindEventsViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FindEventsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITableView *eventsTableView;
@property (strong, nonatomic) IBOutlet UITextField *eventSearchTextField;
@property (strong, nonatomic) IBOutlet UIButton *findEventsButton;

@property (strong, nonatomic) IBOutlet UIView *noEventsFoundView;
@property (strong, nonatomic) IBOutlet UILabel *noEventsFoundHeaderLabel;
@property (strong, nonatomic) IBOutlet UILabel *noEventsFoundDetailLabel;
@property (strong, nonatomic) IBOutlet UIButton *noEventsFoundCreateShootButton;

@property (strong, nonatomic) IBOutlet UIView *findEventsFooterView;
@property (strong, nonatomic) IBOutlet UIButton *createShootButton;

// Pagination
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet UILabel *loadMoreLabel;
@property (strong, nonatomic) IBOutlet UIButton *loadMoreButton;

@end
