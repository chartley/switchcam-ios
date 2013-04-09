//
//  LoginViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPPagingScrollView.h"

@interface LoginViewController : UIViewController <SPPagingScrollViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (strong, nonatomic) IBOutlet UIButton *emailLoginButton;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

@property (strong, nonatomic) IBOutlet UIView *slide0View;
@property (strong, nonatomic) IBOutlet UIImageView *switchCamLogo;
@property (strong, nonatomic) IBOutlet UILabel *slide0Label;

@end
