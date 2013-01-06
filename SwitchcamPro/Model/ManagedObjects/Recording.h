//
//  Recording.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Mission;

@interface Recording : NSManagedObject

@property (nonatomic, retain) NSString * compressedVideoURL;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * isUploaded;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * localVideoAssetURL;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * mimetype;
@property (nonatomic, retain) NSDate * recordEnd;
@property (nonatomic, retain) NSDate * recordStart;
@property (nonatomic, retain) NSNumber * sizeBytes;
@property (nonatomic, retain) NSNumber * sizeMegaBytes;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * uploadDestination;
@property (nonatomic, retain) NSString * uploadedVideoId;
@property (nonatomic, retain) NSString * uploadPath;
@property (nonatomic, retain) NSString * uploadS3Bucket;
@property (nonatomic, retain) Mission *mission;

@end
