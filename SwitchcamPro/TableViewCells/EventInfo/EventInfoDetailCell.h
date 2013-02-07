//
//  EventInfoDetailCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 1/22/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#define kEventInfoDetailCellIdentifier @"EventInfoDetailCellIdentifier"
#define kEventInfoDetailCellRowHeight 200

@interface EventInfoDetailCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *streetAddressLabel;
@property (strong, nonatomic) IBOutlet UILabel *cityStateZipLabel;
@property (strong, nonatomic) IBOutlet UILabel *tapForDirectionsLabel;
@property (strong, nonatomic) IBOutlet UIButton *directionsButton;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end
