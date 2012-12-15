//
//  User.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/15/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event;

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * legalTermsAcceptDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pictureURL;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSSet *attendedMission;
@property (nonatomic, retain) NSSet *createdMission;
@property (nonatomic, retain) NSSet *followedMission;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addAttendedMissionObject:(Event *)value;
- (void)removeAttendedMissionObject:(Event *)value;
- (void)addAttendedMission:(NSSet *)values;
- (void)removeAttendedMission:(NSSet *)values;

- (void)addCreatedMissionObject:(Event *)value;
- (void)removeCreatedMissionObject:(Event *)value;
- (void)addCreatedMission:(NSSet *)values;
- (void)removeCreatedMission:(NSSet *)values;

- (void)addFollowedMissionObject:(Event *)value;
- (void)removeFollowedMissionObject:(Event *)value;
- (void)addFollowedMission:(NSSet *)values;
- (void)removeFollowedMission:(NSSet *)values;

@end
