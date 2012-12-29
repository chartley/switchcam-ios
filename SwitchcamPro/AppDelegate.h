//
//  AppDelegate.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECSlidingViewController;

extern NSString *const SCSessionStateChangedNotification;
extern NSString *const SCAPINetworkRequestCanStartNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ECSlidingViewController *slidingViewController;

// Facebook
- (BOOL)openReadSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (BOOL)openWriteSessionWithAllowLoginUI:(BOOL)allowLoginUI;

// Callback
- (void)successfulLoginViewControllerChange;

@end
