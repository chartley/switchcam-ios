//
//  PendingUploadCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LKBadgeView.h"

#define kPendingUploadCellIdentifier @"PendingUploadCellIdentifier"
#define kPendingUploadCellTopIdentifier @"PendingUploadCellTopIdentifier"
#define kPendingUploadCellEventVideoIdentifier @"PendingUploadCellEventVideoIdentifier"
#define kPendingUploadCellEventVideoTopIdentifier @"PendingUploadCellEventVideoTopIdentifier"
#define kHostedEventVideoTopCellIdentifier @"HostedEventVideoTopCellIdentifier"
#define kHostedEventVideoCellIdentifier @"HostedEventVideoCellIdentifier"

#define kPendingUploadCellRowHeight 134
#define kPendingUploadCellTopRowHeight 181
#define kPendingUploadCellEventVideoTopRowHeight 208
#define kPendingUploadCellEventVideoRowHeight 174
#define kHostedEventVideoCellTopRowHeight 208
#define kHostedEventVideoCellRowHeight 174

#define kBufferBetweenThumbnailLabels 10

@class PendingUploadCell;

@protocol PendingUploadCellDelegate <NSObject>

- (void)previewButtonPressed:(PendingUploadCell*)pendingUploadCell;
- (void)uploadButtonPressed:(PendingUploadCell*)pendingUploadCell;
- (void)deleteButtonPressed:(PendingUploadCell*)pendingUploadCell;

@end

@interface PendingUploadCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *pendingUploadLabel;

@property (strong, nonatomic) LKBadgeView *pendingUploadCountBadge;
@property (strong, nonatomic) IBOutlet UIImageView *videoThumbnailImageView;
@property (strong, nonatomic) IBOutlet UIButton *previewButton;
@property (strong, nonatomic) IBOutlet UIButton *uploadButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButtonButton;
@property (strong, nonatomic) IBOutlet UILabel *previewLabel;
@property (strong, nonatomic) IBOutlet UILabel *uploadLabel;
@property (strong, nonatomic) IBOutlet UILabel *deleteLabel;
@property (strong, nonatomic) IBOutlet UILabel *pendingUploadTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *pendingUploadLengthLabel;

@property (strong, nonatomic) IBOutlet UILabel *yourVideosLabel;
@property (strong, nonatomic) IBOutlet UILabel *yourVideosCountLabel;



@property (weak, nonatomic) id<PendingUploadCellDelegate> delegate;

- (IBAction)previewButtonAction:(id)sender;
- (IBAction)uploadButtonAction:(id)sender;
- (IBAction)deleteButtonAction:(id)sender;

@end
