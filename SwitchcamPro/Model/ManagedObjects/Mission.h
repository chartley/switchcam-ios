//
//  Mission.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/25/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Artist, Link, User, UserVideo, Venue;

@interface Mission : NSManagedObject

@property (nonatomic, retain) NSDate * endDatetime;
@property (nonatomic, retain) NSNumber * isCameraCrew;
@property (nonatomic, retain) NSNumber * isFollowing;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * missionId;
@property (nonatomic, retain) NSString * picURL;
@property (nonatomic, retain) NSDate * startDatetime;
@property (nonatomic, retain) NSDate * submissionDeadline;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * missionDescription;
@property (nonatomic, retain) NSString * missionPageURL;
@property (nonatomic, retain) Artist *artist;
@property (nonatomic, retain) NSSet *cameraCrew;
@property (nonatomic, retain) User *createdBy;
@property (nonatomic, retain) NSSet *followers;
@property (nonatomic, retain) NSSet *userVideos;
@property (nonatomic, retain) Venue *venue;
@property (nonatomic, retain) NSSet *links;
@end

@interface Mission (CoreDataGeneratedAccessors)

- (void)addCameraCrewObject:(User *)value;
- (void)removeCameraCrewObject:(User *)value;
- (void)addCameraCrew:(NSSet *)values;
- (void)removeCameraCrew:(NSSet *)values;

- (void)addFollowersObject:(User *)value;
- (void)removeFollowersObject:(User *)value;
- (void)addFollowers:(NSSet *)values;
- (void)removeFollowers:(NSSet *)values;

- (void)addUserVideosObject:(UserVideo *)value;
- (void)removeUserVideosObject:(UserVideo *)value;
- (void)addUserVideos:(NSSet *)values;
- (void)removeUserVideos:(NSSet *)values;

- (void)addLinksObject:(Link *)value;
- (void)removeLinksObject:(Link *)value;
- (void)addLinks:(NSSet *)values;
- (void)removeLinks:(NSSet *)values;

@end
