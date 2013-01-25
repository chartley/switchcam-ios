//
//  CompleteLoginViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CompleteLoginViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSString *userFullNameString;
@property (strong, nonatomic) NSString *userEmailString;
@property (strong, nonatomic) NSURL *userProfileURL;
@property (strong, nonatomic) UITextField *userEmailTextField;

@end
