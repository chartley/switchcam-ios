//
//  EventViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPTabsViewController.h"

@class Event;

@interface EventViewController : SPTabsViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) Event *event;
@property (strong, nonatomic) IBOutlet UIView *toolbarDrawer;

@end
