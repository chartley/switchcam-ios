//
//  EventActivityViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventTabViewController.h"
#import "ActivityCell.h"

@interface EventActivityViewController : EventTabViewController <ActivityCellDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITableView *eventActivityTableView;

- (void)getActivity;

@end
