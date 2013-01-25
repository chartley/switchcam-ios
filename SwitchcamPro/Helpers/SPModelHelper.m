//
//  SPModelHelper.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "SPModelHelper.h"

@implementation SPModelHelper

+(BOOL)resetCoreData {
    RKManagedObjectStore *objectStore = [[RKObjectManager sharedManager] managedObjectStore];
    
    NSError *error = nil;
    [objectStore resetPersistentStores:&error];
    
    return YES;
}

@end
