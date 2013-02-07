//
//  MKMapView+ZoomLevel.h
//  SwitchcamPro
//
//  Created by William Ketterer on 2/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

@end
