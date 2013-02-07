//
//  AddressAnnotation.h
//  SwitchcamPro
//
//  Created by William Ketterer on 2/6/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AddressAnnotation : NSObject<MKAnnotation> 

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subTitle;

@end
