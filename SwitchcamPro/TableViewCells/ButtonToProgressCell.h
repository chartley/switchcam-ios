//
//  ButtonToProgressCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kButtonToProgressCellIdentifier @"ButtonToProgressCellIdentifier"
#define kButtonToProgressCellRowHeight 60

@interface ButtonToProgressCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIButton *bigButton;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;

@end
