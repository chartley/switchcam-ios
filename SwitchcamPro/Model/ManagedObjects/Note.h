//
//  Note.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/28/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Activity;

@interface Note : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSNumber * noteId;
@property (nonatomic, retain) Activity *activity;

@end
