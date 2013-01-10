//
//  EventVideosViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventTabViewController.h"
#import "PendingUploadCell.h"


@interface EventVideosViewController : EventTabViewController <PendingUploadCellDelegate>

@property (strong, nonatomic) IBOutlet UITableView *eventVideosTableView;

@property (strong, nonatomic) IBOutlet UIView *noVideosFoundView;
@property (strong, nonatomic) IBOutlet UILabel *noVideosFoundHeaderLabel;
@property (strong, nonatomic) IBOutlet UILabel *noVideosFoundDetailLabel;

@end
