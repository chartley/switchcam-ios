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

@property (strong, nonatomic) IBOutlet UIView *loadMoreView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet UILabel *loadMoreLabel;

- (void)getActivity;

- (IBAction)loadMoreButtonAction:(id)sender;

@end
