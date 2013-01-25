//
//  Venue.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/22/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Mission;

@interface Venue : NSManagedObject

@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSNumber * foursquareId;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * venueName;
@property (nonatomic, retain) NSString * venueId;
@property (nonatomic, retain) NSSet *missions;
@end

@interface Venue (CoreDataGeneratedAccessors)

- (void)addMissionsObject:(Mission *)value;
- (void)removeMissionsObject:(Mission *)value;
- (void)addMissions:(NSSet *)values;
- (void)removeMissions:(NSSet *)values;

@end
