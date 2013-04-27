//
//  SPConstants.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

// API Server Configuration
#define kAPIHost @"http://api.switchcam.com/api/v1/"

// AWS
#define kAWS_ACCESS_KEY_ID          @"AKIAIDTVJ7AMJAP7ISYQ"
#define kAWS_SECRET_KEY             @"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"

// Constants for the Bucket and Object name.
#define kAWS_VIDEO_BUCKET         @"upload-switchcam-ios"

// User Defaults
#define kSPUserFacebookIdKey @"SPUserFacebookIdKey"
#define kSPUserFacebookTokenKey @"SPUserFacebookTokenKey"
#define kSPUserLoginTypeKey @"SPUserLoginTypeKey"
#define kSPUserAcceptedTermsKey @"SPUserAcceptedTermsKey"
#define kSPUserIdKey @"SPUserIdKey"
#define kSPHasUserPreviouslyLoggedInKey @"SPHasUserPreviouslyLoggedInKey"

#define kSPUserFullName @"SPUserFullName"
#define kSPUserProfileURL @"SPUserProfileURL"

#define kHasAppLaunchedPreviously @"HasAppLaunchedPreviously" // First Run check
#define kUploadOver3GEnabled @"UploadOver3GEnabled"

#define kUploadQualityKey @"UploadQuality"

// Login Types
#define kSPUserLoginTypeEmail @"email"
#define kSPUserLoginTypeFacebook @"facebook"

// Color Ease
#define RGBA(r,g,b,a) [UIColor colorWithRed: r/255.0f green: g/255.0f \
blue: b/255.0f alpha: a]

// Notifications
#define kAppFadeInCompleteNotification @"AppFadeInCompleteNotification"

// Device
#define HEIGHT_IPHONE_5 568
#define IS_IPHONE   ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds ].size.height == HEIGHT_IPHONE_5 )
