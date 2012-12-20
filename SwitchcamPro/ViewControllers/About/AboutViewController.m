//
//  AboutViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "AboutViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "SPConstants.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

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
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.switchcamButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.switchcamButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
    
    // Set Button Image
    UIImage *twitterButtonImage = [[UIImage imageNamed:@"btn-twitter-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *twitterHighlightButtonImage = [[UIImage imageNamed:@"btn-twitter-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.twitterButton setBackgroundImage:twitterButtonImage forState:UIControlStateNormal];
    [self.twitterButton setBackgroundImage:twitterHighlightButtonImage forState:UIControlStateSelected];
    
    // Set Button Image
    UIImage *facebookButtonImage = [[UIImage imageNamed:@"btn-fb-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *facebookHighlightButtonImage = [[UIImage imageNamed:@"btn-fb-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.facebookButton setBackgroundImage:facebookButtonImage forState:UIControlStateNormal];
    [self.facebookButton setBackgroundImage:facebookHighlightButtonImage forState:UIControlStateSelected];
    
    // Set Font / Color
    [self.switchcamButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.switchcamButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.switchcamButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.switchcamButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.twitterButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.twitterButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.twitterButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.twitterButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.facebookButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.facebookButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.facebookButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.facebookButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.aboutTitleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:17]];
    
    [self.aboutLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
    [self.aboutLabel setTextColor:[UIColor whiteColor]];
    [self.aboutLabel setShadowColor:[UIColor blackColor]];
    [self.aboutLabel setShadowOffset:CGSizeMake(0, -1)];
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

- (IBAction)switchcamButtonAction:(id)sender {
    
}

- (IBAction)twitterButtonAction:(id)sender {
    
}

- (IBAction)facebookButtonAction:(id)sender {
    
}

@end
