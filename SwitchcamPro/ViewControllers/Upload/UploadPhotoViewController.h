//
//  UploadPhotoViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 2/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionObject.h"

@interface UploadPhotoViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) ActionObject *photoToUpload;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *photoThumbnailImageView;
@property (strong, nonatomic) IBOutlet UIToolbar *headerToolbar;
@property (strong, nonatomic) IBOutlet UILabel *headerToolbarLabel;
@property (strong, nonatomic) IBOutlet UITableView *uploadTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)backButtonAction:(id)sender;

@end
