//
//  EventInfoViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "EventInfoViewController.h"
#import "SPConstants.h"

@interface EventInfoViewController ()

@end

@implementation EventInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-lg-grey"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *selectedButtonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.imGoingButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.imGoingButton setBackgroundImage:selectedButtonImage forState:UIControlStateSelected];
    
    // Set the background for any states you plan to use
    [self.imNotGoingButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.imNotGoingButton setBackgroundImage:selectedButtonImage forState:UIControlStateSelected];
    
    // Set Font / Color
    [self.imGoingButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:17]];
    [self.imGoingButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.imGoingButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.imGoingButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.imNotGoingButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:17]];
    [self.imNotGoingButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.imNotGoingButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.imNotGoingButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.goingDetailLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:14]];
    [self.goingDetailLabel setTextColor:RGBA(166,166,166,1)];
    [self.goingDetailLabel setShadowColor:[UIColor blackColor]];
    [self.goingDetailLabel setShadowOffset:CGSizeMake(0, -1)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)imGoingButtonAction:(id)sender {
    [self.imGoingButton setSelected:YES];
    [self.imNotGoingButton setSelected:NO];
    [self.goingDetailLabel setText:NSLocalizedString(@"We'll send you updates during the shoot and notify you when to start shooting.", @"")];
}

- (IBAction)imNotGoingButtonAction:(id)sender {
    [self.imGoingButton setSelected:NO];
    [self.imNotGoingButton setSelected:YES];
    [self.goingDetailLabel setText:NSLocalizedString(@"Bummer! Watch the activity feed during the event and we'll notify you when the final event is built!", @"")];
}

@end
