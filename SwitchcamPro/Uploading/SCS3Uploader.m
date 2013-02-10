//
//  SCS3Uploader.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "SCS3Uploader.h"
#import "Reachability.h"
#import "SPConstants.h"
#import "SCBucketNameGenerator.h"
#import "AppDelegate.h"

@interface SCS3Uploader () {
    BOOL        _doneUploadingToS3;
    NSString *uploadVideoKey;
}

@end

@implementation SCS3Uploader

@synthesize bucketName;

- (id)init {
    self = [super init];
    if (self) {
        self.bucketName = [SCBucketNameGenerator bucketName];
    }

    return self;
}

-(void)upload:(NSData*)dataToUpload inBucket:(NSString*)bucket forKey:(NSString*)key {
    @try {
        AmazonS3Client *s3 = [[[AmazonS3Client alloc] initWithAccessKey:kAWS_ACCESS_KEY_ID withSecretKey:kAWS_SECRET_KEY] autorelease];
        
        S3CreateBucketRequest *cbr = [[[S3CreateBucketRequest alloc] initWithName:bucket] autorelease];
        [s3 createBucket:cbr];
        
        S3PutObjectRequest *por = [[[S3PutObjectRequest alloc] initWithKey:key inBucket:bucket] autorelease];
        NSInputStream *stream = [NSInputStream inputStreamWithData:dataToUpload];
        por.contentType = @"video/mp4";
        por.contentLength = [dataToUpload length];
        por.stream = stream;
        
        [s3 putObject:por];
    }
    @catch ( AmazonServiceException *exception ) {
        NSLog( @"Upload Failed, Reason: %@", exception );
    }
}

const int PART_SIZE = (5 * 1024 * 1024); // 5MB is the smallest part size allowed for a multipart upload. (Only the last part can be smaller.)

-(void)multipartUpload:(NSData*)dataToUpload inBucket:(NSString*)bucket forKey:(NSString*)key {
    AmazonS3Client *s3 = [[[AmazonS3Client alloc] initWithAccessKey:kAWS_ACCESS_KEY_ID withSecretKey:kAWS_SECRET_KEY] autorelease];
    
    @try {
        [s3 createBucketWithName:bucket];
        
        S3InitiateMultipartUploadRequest *initReq = [[[S3InitiateMultipartUploadRequest alloc] initWithKey:key inBucket:bucket] autorelease];
        S3MultipartUpload *upload = [s3 initiateMultipartUpload:initReq].multipartUpload;
        S3CompleteMultipartUploadRequest *compReq = [[[S3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:upload] autorelease];
        
        int numberOfParts = [self countParts:dataToUpload];
        for ( int part = 0; part < numberOfParts; part++ ) {
            
            NSNumber *percentComplete = [NSNumber numberWithFloat:(float)(((float)part) / ((float)numberOfParts))  * 100.0];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadPercentCompleteNotification object:percentComplete];
            
            NSData *dataForPart = [self getPart:part fromData:dataToUpload];
            
            NSInputStream *stream = [NSInputStream inputStreamWithData:dataForPart];
            
            S3UploadPartRequest *upReq = [[S3UploadPartRequest alloc] initWithMultipartUpload:upload];
            upReq.partNumber = ( part + 1 );
            upReq.contentLength = [dataForPart length];
            upReq.contentType = @"video/mp4";
            upReq.stream = stream;
            
            S3UploadPartResponse *response = [s3 uploadPart:upReq];
            [compReq addPartWithPartNumber:( part + 1 ) withETag:response.etag];
        }
        
        [s3 completeMultipartUpload:compReq];
    }
    @catch ( AmazonServiceException *exception ) {
        NSLog( @"Multipart Upload Failed, Reason: %@", exception  );
    }
}

-(NSData*)getPart:(int)part fromData:(NSData*)fullData
{
    NSRange range;
    range.length = PART_SIZE;
    range.location = part * PART_SIZE;
    
    int maxByte = (part + 1) * PART_SIZE;
    if ( [fullData length] < maxByte ) {
        range.length = [fullData length] - range.location;
    }
    
    return [fullData subdataWithRange:range];
}

-(int)countParts:(NSData*)fullData
{
    int q = (int)([fullData length] / PART_SIZE);
    int r = (int)([fullData length] % PART_SIZE);
    
    return ( r == 0 ) ? q : q + 1;
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
    
    uploadVideoKey = videoKey;
    //[AmazonLogger verboseLogging];
    NSNumber *percentComplete = [NSNumber numberWithFloat:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadStartedNotification object:percentComplete];
    
    if ([self countParts:videoData] == 1) {
        _doneUploadingToS3 = NO;
        AmazonS3Client *s3 = [[[AmazonS3Client alloc] initWithAccessKey:kAWS_ACCESS_KEY_ID withSecretKey:kAWS_SECRET_KEY] autorelease];
        @try {
            // Create the picture bucket.
            [s3 createBucket:[[[S3CreateBucketRequest alloc] initWithName:self.bucketName] autorelease]];
            
            // Upload image data.  Remember to set the content type.
            S3PutObjectRequest *por = [[[S3PutObjectRequest alloc] initWithKey:videoKey inBucket:self.bucketName] autorelease];
            por.contentType = @"video/mp4";
            por.data        = videoData;
            [por setDelegate:self];
            
            // Put the image data into the specified s3 bucket and object.
            [s3 putObject:por];
            
            do {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            } while (!_doneUploadingToS3);
            
            por.delegate = nil;
        }
        @catch (AmazonClientException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadFailedNotification object:nil];
            NSLog( @"Single Upload Failed, Reason: %@", exception  );
            _doneUploadingToS3 = YES;
        }
    } else {
        
        AmazonS3Client *s3 = [[[AmazonS3Client alloc] initWithAccessKey:kAWS_ACCESS_KEY_ID withSecretKey:kAWS_SECRET_KEY] autorelease];
        
        @try {
            [s3 createBucket:[[[S3CreateBucketRequest alloc] initWithName:self.bucketName] autorelease]];
            
            S3InitiateMultipartUploadRequest *initReq = [[[S3InitiateMultipartUploadRequest alloc] initWithKey:videoKey inBucket:self.bucketName] autorelease];
            S3MultipartUpload *upload = [s3 initiateMultipartUpload:initReq].multipartUpload;
            S3CompleteMultipartUploadRequest *compReq = [[[S3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:upload] autorelease];
            
            int numberOfParts = [self countParts:videoData];
            
            for ( int part = 0; part < numberOfParts; part++ ) {
                
                NSNumber *percentComplete = [NSNumber numberWithFloat:(float)(((float)part) / ((float)numberOfParts))  * 100.0];
                [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadPercentCompleteNotification object:percentComplete];
                
                NSData *dataForPart = [self getPart:part fromData:videoData];
                
                NSInputStream *stream = [NSInputStream inputStreamWithData:dataForPart];
                
                S3UploadPartRequest *upReq = [[S3UploadPartRequest alloc] initWithMultipartUpload:upload];
                upReq.partNumber = ( part + 1 );
                upReq.contentLength = [dataForPart length];
                upReq.contentType = @"video/mp4";
                upReq.stream = stream;
                
                S3UploadPartResponse *response = [s3 uploadPart:upReq];
                [compReq addPartWithPartNumber:( part + 1 ) withETag:response.etag];
            }
            
            [s3 completeMultipartUpload:compReq];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadCompletedNotification object:videoKey];
            
        }
        @catch ( AmazonServiceException *exception ) {
            NSLog( @"Multipart Upload Failed, Reason: %@", exception  );
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadFailedNotification object:videoKey];
        }
    }
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
