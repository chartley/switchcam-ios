//
//  Activity.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/15/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class User, UserVideo;

@interface Activity : NSManagedObject

@property (nonatomic, retain) NSString * actionObjectContentType;
@property (nonatomic, retain) NSNumber * actionObjectId;
@property (nonatomic, retain) NSString * activityId;
@property (nonatomic, retain) NSString * activityType;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSNumber * deletable;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSNumber * rowHeight;
@property (nonatomic, retain) NSString * targetContentType;
@property (nonatomic, retain) NSNumber * targetId;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * timesince;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * verb;
@property (nonatomic, retain) NSString * photoThumbnailURL;
@property (nonatomic, retain) NSNumber * liked;
@property (nonatomic, retain) User *person;
@property (nonatomic, retain) UserVideo *userVideo;

@end
