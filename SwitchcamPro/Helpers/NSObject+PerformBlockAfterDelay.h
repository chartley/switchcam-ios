//
//  NSObject+PerformBlockAfterDelay.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/28/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PerformBlockAfterDelay)

- (void)performBlock:(void (^)(void))block
          afterDelay:(NSTimeInterval)delay;

- (void)fireBlockAfterDelay:(void (^)(void))block;

@end
