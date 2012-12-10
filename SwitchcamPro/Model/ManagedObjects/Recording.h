//
//  Recording.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event;

@interface Recording : NSManagedObject

@property (nonatomic, retain) NSString * localVideoAssetURL;
@property (nonatomic, retain) NSDate * recordStart;
@property (nonatomic, retain) NSDate * recordEnd;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSNumber * isUploaded;
@property (nonatomic, retain) NSString * uploadedVideoId;
@property (nonatomic, retain) NSNumber * sizeBytes;
@property (nonatomic, retain) Event *event;

@end
