//
//  Recording.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/10/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event;

@interface Recording : NSManagedObject

@property (nonatomic, retain) NSNumber * isUploaded;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * localVideoAssetURL;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * recordEnd;
@property (nonatomic, retain) NSDate * recordStart;
@property (nonatomic, retain) NSNumber * sizeBytes;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * uploadedVideoId;
@property (nonatomic, retain) NSString * uploadDestination;
@property (nonatomic, retain) NSString * uploadS3Bucket;
@property (nonatomic, retain) NSString * mimetype;
@property (nonatomic, retain) NSNumber * sizeMegaBytes;
@property (nonatomic, retain) NSString * uploadPath;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * compressedVideoURL;
@property (nonatomic, retain) Event *event;

@end
