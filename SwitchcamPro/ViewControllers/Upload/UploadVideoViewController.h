//
//  UploadVideoViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserVideo;

@interface UploadVideoViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) UserVideo *userVideoToUpload;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *lengthLabel;
@property (strong, nonatomic) IBOutlet UILabel *sizeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *videoThumbnailImageView;
@property (strong, nonatomic) IBOutlet UIToolbar *headerToolbar;
@property (strong, nonatomic) IBOutlet UILabel *headerToolbarLabel;
@property (strong, nonatomic) IBOutlet UITableView *uploadTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UITextField *videoTitleTextField;

- (IBAction)backButtonAction:(id)sender;

@end
