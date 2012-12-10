//
//  SCS3Uploader.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SCS3Uploader.h"
#import "Reachability.h"
#import "SPConstants.h"
#import "SCBucketNameGenerator.h"

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
        por.contentType = @"video/quicktime";
        por.contentLength = [dataToUpload length];
        por.stream = stream;
        
        [s3 putObject:por];
    }
    @catch ( AmazonServiceException *exception ) {
        //NSLog( @"Upload Failed, Reason: %@", exception );
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
            upReq.contentType = @"video/quicktime";
            upReq.stream = stream;
            
            S3UploadPartResponse *response = [s3 uploadPart:upReq];
            [compReq addPartWithPartNumber:( part + 1 ) withETag:response.etag];
        }
        
        [s3 completeMultipartUpload:compReq];
    }
    @catch ( AmazonServiceException *exception ) {
        //NSLog( @"Multipart Upload Failed, Reason: %@", exception  );
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


- (void)uploadVideo:(NSData*)videoData withKey:(NSString*)videoKey;
{
    
    //[AmazonLogger verboseLogging];
    
    NSNumber *percentComplete = [NSNumber numberWithFloat:0.4 * 100];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadPercentCompleteNotification object:percentComplete];
    
    if ([self countParts:videoData] == 1) {
        AmazonS3Client *s3 = [[[AmazonS3Client alloc] initWithAccessKey:kAWS_ACCESS_KEY_ID withSecretKey:kAWS_SECRET_KEY] autorelease];
        @try {
            
            
            // Create the picture bucket.
            [s3 createBucket:[[[S3CreateBucketRequest alloc] initWithName:self.bucketName] autorelease]];
            
            // Upload image data.  Remember to set the content type.
            S3PutObjectRequest *por = [[[S3PutObjectRequest alloc] initWithKey:videoKey inBucket:self.bucketName] autorelease];
            por.contentType = @"video/quicktime";
            por.data        = videoData;
            
            // Put the image data into the specified s3 bucket and object.
            [s3 putObject:por];
            //     NSLog( @"single part Upload Completed"  );
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadCompletedNotification object:nil];
        }
        @catch (AmazonClientException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadFailedNotification object:nil];
            //  NSLog( @"single part Upload Failed"  );
            // TODO FIX ME
            //[Constants showAlertMessage:exception.message withTitle:@"Upload Error"];
            
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
                upReq.contentType = @"video/quicktime";
                upReq.stream = stream;
                
                S3UploadPartResponse *response = [s3 uploadPart:upReq];
                [compReq addPartWithPartNumber:( part + 1 ) withETag:response.etag];
            }
            
            [s3 completeMultipartUpload:compReq];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadCompletedNotification object:nil];
            
        }
        @catch ( AmazonServiceException *exception ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSCS3UploadFailedNotification object:nil];
        }
    }
    // Initial the S3 Client.
    
    
}

-(BOOL)isWifiAvailable {
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    return !( [r currentReachabilityStatus] == NotReachable); 
}

@end
