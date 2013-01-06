//
//  Artist.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Mission;

@interface Artist : NSManagedObject

@property (nonatomic, retain) NSNumber * artistId;
@property (nonatomic, retain) NSString * artistName;
@property (nonatomic, retain) NSSet *missions;
@end

@interface Artist (CoreDataGeneratedAccessors)

- (void)addMissionsObject:(Mission *)value;
- (void)removeMissionsObject:(Mission *)value;
- (void)addMissions:(NSSet *)values;
- (void)removeMissions:(NSSet *)values;

@end
