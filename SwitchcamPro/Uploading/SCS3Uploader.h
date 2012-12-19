//
//  SCS3Uploader.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSiOSSDK/S3/AmazonS3Client.h>

#define kSCS3UploadStartedNotification @"SCS3UploadStartedNotification"
#define kSCS3UploadPercentCompleteNotification @"SCS3UploadPercentCompleteNotification"
#define kSCS3UploadCompletedNotification @"SCS3UploadCompletedNotification"
#define kSCS3UploadFailedNotification @"SCS3UploadFailedNotification"

@interface SCS3Uploader : NSObject <AmazonServiceRequestDelegate> 

@property (nonatomic, strong) NSURL *uploadVideoURL; //the video;
@property (nonatomic, strong) NSString *s3VideoURL; //the video;
@property (nonatomic, strong) NSString *bucketName; //the video;

- (void)uploadVideo:(NSData*)videoData withKey:(NSString*)videoKey;

@end
