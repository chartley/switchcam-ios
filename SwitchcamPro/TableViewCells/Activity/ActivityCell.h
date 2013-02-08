//
//  ActivityCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ActivityCell;

@protocol ActivityCellDelegate <NSObject>

- (void)previewButtonPressed:(ActivityCell*)activityCell;
- (void)likeButtonPressed:(ActivityCell*)activityCell;
- (void)commentButtonPressed:(ActivityCell*)activityCell;
- (void)postCommentButtonPressed:(ActivityCell*)activityCell;

@end

@interface ActivityCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *activityTopSeparatorView;

@property (strong, nonatomic) IBOutlet UILabel *contributorLabel;
@property (strong, nonatomic) IBOutlet UIImageView *contributorImageView;
@property (strong, nonatomic) IBOutlet UILabel *verbLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *commentButton;
@property (strong, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *commentCountLabel;

@property (weak, nonatomic) id<ActivityCellDelegate> delegate;

- (IBAction)previewButtonAction:(id)sender;
- (IBAction)likeButtonAction:(id)sender;
- (IBAction)commentButtonAction:(id)sender;
- (IBAction)postCommentButtonAction:(id)sender;

@end
