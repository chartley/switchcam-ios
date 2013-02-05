//
//  MyEventsViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyEventsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITableView *myEventsTableView;

@property (strong, nonatomic) IBOutlet UIView *noEventsFoundView;
@property (strong, nonatomic) IBOutlet UILabel *noEventsFoundHeaderLabel;
@property (strong, nonatomic) IBOutlet UILabel *noEventsFoundDetailLabel;

// Pagination
@property (strong, nonatomic) IBOutlet UIView *loadMoreView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet UILabel *loadMoreLabel;
@property (strong, nonatomic) IBOutlet UIButton *loadMoreButton;

@end
