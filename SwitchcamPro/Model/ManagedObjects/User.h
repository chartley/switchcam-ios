//
//  User.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/15/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Activity, Mission, UserVideo;

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * legalTermsAcceptDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pictureURL;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSSet *activities;
@property (nonatomic, retain) NSSet *attendedMission;
@property (nonatomic, retain) NSSet *createdMission;
@property (nonatomic, retain) NSSet *followedMission;
@property (nonatomic, retain) NSSet *uploads;
@property (nonatomic, retain) NSSet *comments;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(Activity *)value;
- (void)removeActivitiesObject:(Activity *)value;
- (void)addActivities:(NSSet *)values;
- (void)removeActivities:(NSSet *)values;

- (void)addAttendedMissionObject:(Mission *)value;
- (void)removeAttendedMissionObject:(Mission *)value;
- (void)addAttendedMission:(NSSet *)values;
- (void)removeAttendedMission:(NSSet *)values;

- (void)addCreatedMissionObject:(Mission *)value;
- (void)removeCreatedMissionObject:(Mission *)value;
- (void)addCreatedMission:(NSSet *)values;
- (void)removeCreatedMission:(NSSet *)values;

- (void)addFollowedMissionObject:(Mission *)value;
- (void)removeFollowedMissionObject:(Mission *)value;
- (void)addFollowedMission:(NSSet *)values;
- (void)removeFollowedMission:(NSSet *)values;

- (void)addUploadsObject:(UserVideo *)value;
- (void)removeUploadsObject:(UserVideo *)value;
- (void)addUploads:(NSSet *)values;
- (void)removeUploads:(NSSet *)values;

- (void)addCommentsObject:(NSManagedObject *)value;
- (void)removeCommentsObject:(NSManagedObject *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
