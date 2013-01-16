//
//  Comment.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/15/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class User;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSNumber * commentId;
@property (nonatomic, retain) NSDate * submit_date;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) User *user;

@end
