//
//  Link.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/25/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@class Mission;

@interface Link : NSManagedObject

@property (nonatomic, retain) NSNumber * linkId;
@property (nonatomic, retain) NSString * linkURL;
@property (nonatomic, retain) NSString * linkName;
@property (nonatomic, retain) Mission *mission;

@end
