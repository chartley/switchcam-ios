//
//  SCS3Uploader.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol S3UploadDelegate <NSObject>
@required
- (void)startedUpload;	// This method is always called on the main thread.
- (void)percentCompleted:(float) percent;
- (void)uploadCompleted;
- (void)uploadFailed;

@end

@interface SCS3Uploader : NSObject

@property (nonatomic, retain) NSURL *uploadVideoURL; //the video;
@property (nonatomic, retain) NSString *s3VideoURL; //the video;

@property (nonatomic, retain) NSString *bucketName; //the video;




- (void)uploadVideo:(NSData*)videoData withKey:(NSString*)videoKey;
@property (nonatomic, retain) id <S3UploadDelegate> delegate;

@end
