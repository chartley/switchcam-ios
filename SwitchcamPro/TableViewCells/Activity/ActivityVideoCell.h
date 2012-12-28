//
//  ActivityVideoCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPendingUploadCellIdentifier @"PendingUploadCellIdentifier"
#define kPendingUploadCellRowHeight 200

@class ActivityVideoCell;

@protocol ActivityVideoCellDelegate <NSObject>

- (void)previewButtonPressed:(ActivityVideoCell*)pendingUploadCell;
- (void)likeButtonPressed:(ActivityVideoCell*)pendingUploadCell;
- (void)commentButtonPressed:(ActivityVideoCell*)pendingUploadCell;

@end

@interface ActivityVideoCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *videoThumbnailImageView;
@property (strong, nonatomic) IBOutlet UIImageView *contributorImageView;
@property (strong, nonatomic) IBOutlet UIButton *previewButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *commentButton;
@property (strong, nonatomic) IBOutlet UILabel *contributorLabel;
@property (strong, nonatomic) IBOutlet UILabel *addedAVideoLabel;
@property (strong, nonatomic) IBOutlet UILabel *addedTimeLabel;

@property (weak, nonatomic) id<ActivityVideoCellDelegate> delegate;

- (IBAction)previewButtonAction:(id)sender;
- (IBAction)likeButtonAction:(id)sender;
- (IBAction)commentButtonAction:(id)sender;

@end
