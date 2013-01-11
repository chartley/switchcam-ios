//
//  UserVideo.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/9/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

// States
#define kUserVideoStateDELETED          -20         // completely removed from system
#define kUserVideoStateREMOVING         -10         // remove requested from system
#define kUserVideoStateFAILURE          -5          // somehow broken, generally failure during upload / transcode
#define kUserVideoStateINITIALIZING     0           // upload registered
#define kUserVideoStateUSER_UPLOADING   10          // user has started uploading
#define kUserVideoStateSTORAGE_TRANSFER 20          // transferring user upload to S3 bucket
#define kUserVideoStateENCODER_TRANSFER 30          // transferring user upload to S3 bucket
#define kUserVideoStateTRANSCODING      40          // transcodes being performed
#define kUserVideoStateDEPLOYING        50          // deploying to serving infrastructure
#define kUserVideoStateANALYZING        60          // analyzing content to allow placement
#define kUserVideoStateSERVING          70          // deployed to edge server(s) and serving video

@class Mission, User;

@interface UserVideo : NSManagedObject

@property (nonatomic, retain) NSString * compressedVideoURL;
@property (nonatomic, retain) NSNumber * durationSeconds;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * inputTitle;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * localVideoAssetURL;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * mimetype;
@property (nonatomic, retain) NSDate * recordEnd;
@property (nonatomic, retain) NSDate * recordStart;
@property (nonatomic, retain) NSNumber * sizeBytes;
@property (nonatomic, retain) NSNumber * sizeMegaBytes;
@property (nonatomic, retain) NSString * thumbnailHDURL;
@property (nonatomic, retain) NSString * thumbnailLocalURL;
@property (nonatomic, retain) NSString * thumbnailSDURL;
@property (nonatomic, retain) NSDate * uploadDate;
@property (nonatomic, retain) NSString * uploadDestination;
@property (nonatomic, retain) NSString * uploadPath;
@property (nonatomic, retain) NSString * uploadS3Bucket;
@property (nonatomic, retain) NSString * videoId;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) Mission *mission;
@property (nonatomic, retain) User *uploadedBy;

@end
