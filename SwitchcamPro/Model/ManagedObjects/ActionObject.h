//
//  ActionObject.h
//  SwitchcamPro
//
//  Created by William Ketterer on 2/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Activity, User;

@interface ActionObject : NSManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSNumber * actionObjectId;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSString * thumbURL;
@property (nonatomic, retain) NSString * localURL;
@property (nonatomic, retain) NSString * photoKey;
@property (nonatomic, retain) User *person;
@property (nonatomic, retain) Activity *activity;

@end
