//
//  Activity.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/16/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, User, UserVideo;

@interface Activity : NSManagedObject

@property (nonatomic, retain) NSString * actionObjectContentTypeName;
@property (nonatomic, retain) NSNumber * actionObjectId;
@property (nonatomic, retain) NSString * activityId;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSNumber * deletable;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSNumber * liked;
@property (nonatomic, retain) NSString * photoThumbnailURL;
@property (nonatomic, retain) NSNumber * rowHeight;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * timesince;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * verb;
@property (nonatomic, retain) NSNumber * iLiked;
@property (nonatomic, retain) NSNumber * iCommented;
@property (nonatomic, retain) User *person;
@property (nonatomic, retain) UserVideo *userVideo;
@property (nonatomic, retain) NSSet *latestComments;
@end

@interface Activity (CoreDataGeneratedAccessors)

- (void)addLatestCommentsObject:(Comment *)value;
- (void)removeLatestCommentsObject:(Comment *)value;
- (void)addLatestComments:(NSSet *)values;
- (void)removeLatestComments:(NSSet *)values;

@end
