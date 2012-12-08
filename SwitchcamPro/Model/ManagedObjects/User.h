//
//  User.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Event;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSDate * legalTermsAcceptDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pictureURL;
@property (nonatomic, retain) NSSet *attendedEvents;
@property (nonatomic, retain) NSSet *createdEvents;
@property (nonatomic, retain) NSSet *followedEvents;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addAttendedEventsObject:(Event *)value;
- (void)removeAttendedEventsObject:(Event *)value;
- (void)addAttendedEvents:(NSSet *)values;
- (void)removeAttendedEvents:(NSSet *)values;

- (void)addCreatedEventsObject:(Event *)value;
- (void)removeCreatedEventsObject:(Event *)value;
- (void)addCreatedEvents:(NSSet *)values;
- (void)removeCreatedEvents:(NSSet *)values;

- (void)addFollowedEventsObject:(Event *)value;
- (void)removeFollowedEventsObject:(Event *)value;
- (void)addFollowedEvents:(NSSet *)values;
- (void)removeFollowedEvents:(NSSet *)values;

@end
