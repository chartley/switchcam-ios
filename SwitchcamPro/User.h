//
//  User.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/15/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Mission;

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

@end
