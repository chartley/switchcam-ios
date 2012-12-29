//
//  SettingsViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/5/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *settingsTitleLabel;
@property (strong, nonatomic) IBOutlet UITableView *settingsTableView;

@end
