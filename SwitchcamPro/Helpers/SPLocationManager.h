//
//  SPLocationManager.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SPLocationManager : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSDate *locationManagerStartDate;
    NSTimer *locationTimer;
}

@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, retain) NSDate *locationManagerStartDate;
@property (nonatomic, retain) NSTimer *locationTimer;

+ (SPLocationManager *)sharedInstance;
- (void)start;
- (void)stop;

@end
