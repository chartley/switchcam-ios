//
//  StatusBarToastAndProgressView.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/16/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusBarToastAndProgressView : UIWindow

- (void)showProgressView;
- (void)updateProgressLabelWithAmount:(float)progress;
- (void)hideProgressView;
- (void)showToastWithMessage:(NSString*)message;

@end
