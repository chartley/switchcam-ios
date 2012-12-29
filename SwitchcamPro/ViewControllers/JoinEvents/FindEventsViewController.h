//
//  FindEventsViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FindEventsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITableView *eventsTableView;
@property (strong, nonatomic) IBOutlet UITextField *eventSearchTextField;
@property (strong, nonatomic) IBOutlet UIButton *findEventsButton;

@end
