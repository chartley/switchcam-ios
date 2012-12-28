//
//  FindEventsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "FindEventsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@interface FindEventsViewController ()

@end

@implementation FindEventsViewController

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
    
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    [self.eventsTableView setTableFooterView:[[UIView alloc] init]];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    // Set the background for any states you plan to use
    [self.findEventsButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.findEventsButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
    // Set Font / Color
    [self.findEventsButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.findEventsButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.findEventsButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.findEventsButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    [self.titleLabel setShadowColor:[UIColor blackColor]];
    [self.titleLabel setShadowOffset:CGSizeMake(0, -1)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // shadowPath, shadowOffset, and rotation is handled by ECSlidingViewController.
    // You just need to set the opacity, radius, and color.
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)locationButtonAction:(id)sender {
    // Fire off request for events near user
    //TODO
}

@end
