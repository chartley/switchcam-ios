//
//  ActivityVideoCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityCell.h"

#define kActivityVideoCellIdentifier @"ActivityVideoCellIdentifier"
#define kActivityVideoCellRowHeight 205

@interface ActivityVideoCell : ActivityCell

@property (strong, nonatomic) IBOutlet UIImageView *videoThumbnailImageView;
@property (strong, nonatomic) IBOutlet UIButton *previewButton;

@end
