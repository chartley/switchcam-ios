//
//  SCS3Uploader.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <AWSiOSSDK/S3/S3TransferManager.h>
#import "SCS3Uploader.h"
#import "Reachability.h"
#import "SPConstants.h"
#import "SCBucketNameGenerator.h"
#import "AppDelegate.h"

@interface SCS3Uploader () {
    BOOL        _doneUploadingToS3;
    NSString *uploadVideoKey;
}

@property (strong, nonatomic) AmazonS3Client *s3;
@property (strong, nonatomic) S3TransferManager *tm;

@end

@implementation SCS3Uploader

@synthesize s3, tm;
@synthesize bucketName;

static SCS3Uploader *sharedManager;

+ (SCS3Uploader *)sharedInstance {
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedManager = [[SCS3Uploader alloc] init];
    });
    
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.bucketName = [SCBucketNameGenerator bucketName];
    }

    return self;
}

- (void)showUploadInProgressAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"You can only upload one piece of media at a time.  Please wait for the current upload to complete before uploading another.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
    [alertView show];
}

- (void)showUploadOn3GDisabledAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"You've disabled uploading over 3G.  Connect to a wireless network or enabled uploading over 3G in settings.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
    [alertView show];
}

-(BOOL)isWifiAvailable {
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    return !( [r currentReachabilityStatus] == NotReachable);
}

- (void)uploadVideo:(NSData*)videoData withKey:(NSString*)videoKey;
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (appDelegate.isUserUploading) {
        // Alert
        [self performSelectorOnMainThread:@selector(showUploadInProgressAlert) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kUploadOver3GEnabled] && ![self isWifiAvailable]) {
        // Alert
        [self performSelectorOnMainThread:@selector(showUploadOn3GDisabledAlert) withObject:nil waitUntilDone:NO];
        return;
    }
    
    // Use S3Transfer
    // Note that this is not the preferred way to create the AmazonS3Client object. Do not ship apps with your credentials in them.
    // Switchcam throws caution to the wind
    if (s3 == nil) {
        s3 = [[AmazonS3Client alloc] initWithAccessKey:kAWS_ACCESS_KEY_ID
                                         withSecretKey:kAWS_SECRET_KEY];
        self.tm = [S3TransferManager new];
        self.tm.s3 = s3;
        self.tm.delegate = self;
    }

    uploadVideoKey = videoKey;
    
    // Upload image data.  Remember to set the content type.
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:videoKey inBucket:self.bucketName];
    por.contentType = @"video/mp4";
    por.data        = videoData;
    [por setDelegate:self];
    
    NSNumber *percentComplete = [NSNumber numberWithFloat:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadStartedNotification object:percentComplete];

    [self.tm upload:por];
}

#pragma mark - AWS Delegate Methods

-(void)request:(AmazonServiceRequest *)request didSendData:(NSInteger)bytesWritten
totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    NSNumber *percentComplete = [NSNumber numberWithFloat:(float)(((float)totalBytesWritten) / ((float)totalBytesExpectedToWrite))  * 100.0];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadPercentCompleteNotification object:percentComplete];
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    _doneUploadingToS3 = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadCompletedNotification object:uploadVideoKey];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    _doneUploadingToS3 = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadFailedNotification object:uploadVideoKey];
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    _doneUploadingToS3 = YES;
}

@end
