//
//  EventTabViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/10/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Mission;

@interface EventTabViewController : UIViewController

@property (strong, nonatomic) IBOutlet Mission *selectedMission;
@property (strong, nonatomic) IBOutlet UIScrollView *tabScrollView;

@end
