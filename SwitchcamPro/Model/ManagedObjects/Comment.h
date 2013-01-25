//
//  Comment.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/16/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Activity, User;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSNumber * commentId;
@property (nonatomic, retain) NSDate * submitDate;
@property (nonatomic, retain) NSString * timesince;
@property (nonatomic, retain) NSNumber * rowHeight;
@property (nonatomic, retain) User *person;
@property (nonatomic, retain) Activity *activity;

@end
