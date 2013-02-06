//
//  ActivityNoteCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityCell.h"

#define kActivityNoteCellIdentifier @"ActivityNoteCellIdentifier"
#define kActivityNoteCellRowHeight 205

@interface ActivityNoteCell : ActivityCell

@property (strong, nonatomic) IBOutlet UILabel *noteLabel;
@property (strong, nonatomic) IBOutlet UIView *noteBackground;

@end
