//
//  SPSerializable.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/10/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPSerializable : NSObject

+(NSString*)formattedStringFromDate:(NSDate*)date;
+(NSDate*)dateFromFormattedString:(NSString*)date;
+(NSString*)englishStringFromDate:(NSDate*)date;

@end
