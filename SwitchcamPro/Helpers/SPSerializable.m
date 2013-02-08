//
//  SPSerializable.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/10/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "SPSerializable.h"

@implementation SPSerializable

+(NSString*)formattedStringFromDate:(NSDate*)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+(NSDate*)dateFromFormattedString:(NSString*)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss"];
    return [dateFormatter dateFromString:date];
}


+(NSString*)englishStringFromDate:(NSDate*)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    return formattedDateString;
}

@end
