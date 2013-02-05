//
//  EventPeopleViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventTabViewController.h"

@interface EventPeopleViewController : EventTabViewController

@property (strong, nonatomic) IBOutlet UITableView *eventPeopleTableView;

@property (strong, nonatomic) IBOutlet UIView *noPeopleFoundView;
@property (strong, nonatomic) IBOutlet UILabel *noPeopleFoundHeaderLabel;
@property (strong, nonatomic) IBOutlet UILabel *noPeopleFoundDetailLabel;

@end
