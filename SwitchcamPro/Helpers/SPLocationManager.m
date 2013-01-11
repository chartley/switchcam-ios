//
//  SPLocationManager.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import "SPLocationManager.h"

@interface SPLocationManager()
- (BOOL)isValidLocation:(CLLocation *)newLocation withOldLocation:(CLLocation *)oldLocation;
@end

@implementation SPLocationManager

@synthesize currentLocation;
@synthesize locationManagerStartDate;
@synthesize locationTimer;

static SPLocationManager *sharedManager;

+ (SPLocationManager *)sharedInstance {
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedManager = [[SPLocationManager alloc] init];
    });
    
    return sharedManager;
}

- (id)init {
    self = [super init];
    
    if (self) {
        currentLocation = [[CLLocation alloc] init];
        locationManager = [[CLLocationManager alloc] init];
        
        locationManager.delegate        = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.distanceFilter  = 100;
        
        [self start];
        
        locationManagerStartDate = [NSDate date];
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)start {
    [locationManager startUpdatingLocation];
    
    // Stop automatically after 30 seconds
    self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                          target:self
                                                        selector:@selector(stop)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)stop {
    [locationManager stopUpdatingLocation];
    
    [self.locationTimer invalidate];
}

#pragma mark - Private Methods

- (BOOL)isValidLocation:(CLLocation *)newLocation withOldLocation:(CLLocation *)oldLocation {
    // Filter out nil locations
    if (!newLocation) {
        return NO;
    }
    
    // Filter out points by invalid accuracy
    if (newLocation.horizontalAccuracy < 0) {
        return NO;
    }
    
    // Filter out points that are out of order
    NSTimeInterval secondsSinceLastPoint = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
    
    if (secondsSinceLastPoint < 0) {
        return NO;
    }
    
    // Filter out points created before the manager was initialized
    NSTimeInterval secondsSinceManagerStarted = [newLocation.timestamp timeIntervalSinceDate:locationManagerStartDate];
    
    if (secondsSinceManagerStarted < 0) {
        return NO;
    }
    
    // The newLocation is good to use
    return YES;
}

#pragma mark - Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSInteger locationAge = abs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]);
    
    // If the time interval returned from core location is more than two minutes we ignore it because it might be from an old session
    if (locationAge > 120 || ![self isValidLocation:newLocation withOldLocation:oldLocation]) {
        return;
    }
    
    self.currentLocation = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Disabled", nil)
                                                                message:NSLocalizedString(@"Please enable location services if you wish to search for events near you.  App restart is required.", @"")
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil];
                
                [alert show];
            }
            case kCLErrorLocationUnknown:
                // Silent
            default:
                break;
        }
    } else {
        // We handle all non-CoreLocation errors here
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        
        [alert show];
    }
    

}

@end
