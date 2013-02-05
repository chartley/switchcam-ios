//
//  PeopleCell.h
//  SwitchcamPro
//
//  Created by William Ketterer on 2/4/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPeopleCellIdentifier @"PeopleCellIdentifier"
#define kPeopleCellRowHeight 54

@interface PeopleCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *person1ImageView;
@property (strong, nonatomic) IBOutlet UIImageView *person2ImageView;
@property (strong, nonatomic) IBOutlet UIImageView *person3ImageView;
@property (strong, nonatomic) IBOutlet UIImageView *person4ImageView;
@property (strong, nonatomic) IBOutlet UIImageView *person5ImageView;

@end
