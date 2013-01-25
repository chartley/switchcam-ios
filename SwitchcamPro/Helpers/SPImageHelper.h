//
//  SPImageHelper.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPImageHelper : NSObject

void CGImageWriteToFile(CGImageRef image, NSString *path);

@end
