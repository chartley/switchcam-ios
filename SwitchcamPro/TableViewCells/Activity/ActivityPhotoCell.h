//
//  ActivityPhotoCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityCell.h"

#define kActivityPhotoCellIdentifier @"ActivityPhotoCellIdentifier"
#define kActivityPhotoCellRowHeight 205

@interface ActivityPhotoCell : ActivityCell

@property (strong, nonatomic) IBOutlet UIImageView *photoThumbnailImageView;
@property (strong, nonatomic) IBOutlet UIButton *previewButton;

@end
