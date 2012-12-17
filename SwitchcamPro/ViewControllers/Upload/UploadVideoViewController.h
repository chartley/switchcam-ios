//
//  UploadVideoViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Recording;

@interface UploadVideoViewController : UIViewController

@property (strong, nonatomic) Recording *recordingToUpload;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *lengthLabel;
@property (strong, nonatomic) IBOutlet UILabel *sizeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *videoThumbnailImageView;
@property (strong, nonatomic) IBOutlet UIToolbar *headerToolbar;
@property (strong, nonatomic) IBOutlet UILabel *headerToolbarLabel;

- (IBAction)backButtonAction:(id)sender;

@end
