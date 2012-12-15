//
//  Mission.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/15/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Recording, User;

@interface Mission : NSManagedObject

@property (nonatomic, retain) NSDate * endDatetime;
@property (nonatomic, retain) NSNumber * missionId;
@property (nonatomic, retain) NSNumber * following;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * startDatetime;
@property (nonatomic, retain) NSDate * submissionDeadline;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *cameraCrew;
@property (nonatomic, retain) User *createdBy;
@property (nonatomic, retain) NSSet *followers;
@property (nonatomic, retain) Recording *myRecordings;
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
