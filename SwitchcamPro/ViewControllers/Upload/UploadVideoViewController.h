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

@end
