//
//  TermsViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/21/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TermsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIButton *iAgreeButton;
@property (strong, nonatomic) IBOutlet UILabel *acceptTermsLabel;
@property (strong, nonatomic) IBOutlet UIView *acceptView;

- (IBAction)iAgreeButtonAction:(id)sender;

@end
