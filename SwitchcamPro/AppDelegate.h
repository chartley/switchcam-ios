//
//  AppDelegate.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const SCSessionStateChangedNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Facebook
- (BOOL)openReadSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (BOOL)openWriteSessionWithAllowLoginUI:(BOOL)allowLoginUI;

// Callback
- (void)successfulLoginViewControllerChange;

@end
