//
//  EventInfoViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventTabViewController.h"

@interface EventInfoViewController : EventTabViewController

@property (strong, nonatomic) IBOutlet UITableView *eventInfoTableView;

@property (strong, nonatomic) IBOutlet UIButton *imGoingButton;
@property (strong, nonatomic) IBOutlet UIButton *imNotGoingButton;
@property (strong, nonatomic) IBOutlet UILabel *goingDetailLabel;

@end
