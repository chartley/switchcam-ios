//
//  CreateEventViewController.h
//  SwitchcamPro
//
//  Created by William Ketterer on 2/4/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateEventViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *createEventBodyLabel;
@property (strong, nonatomic) IBOutlet UIImageView *titleImageView;
@property (strong, nonatomic) IBOutlet UIButton *openURLButton;

- (IBAction)emailLinkButtonAction:(id)sender;

@end
