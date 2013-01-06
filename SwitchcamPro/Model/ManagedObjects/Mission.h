//
//  Mission.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artist, Recording, User, Venue;

@interface Mission : NSManagedObject

@property (nonatomic, retain) NSDate * endDatetime;
@property (nonatomic, retain) NSNumber * isFollowing;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * missionId;
@property (nonatomic, retain) NSDate * startDatetime;
@property (nonatomic, retain) NSDate * submissionDeadline;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * isCameraCrew;
@property (nonatomic, retain) NSSet *cameraCrew;
@property (nonatomic, retain) User *createdBy;
@property (nonatomic, retain) NSSet *followers;
@property (nonatomic, retain) Recording *myRecordings;
@property (nonatomic, retain) Venue *venue;
@property (nonatomic, retain) Artist *artist;
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

@end
