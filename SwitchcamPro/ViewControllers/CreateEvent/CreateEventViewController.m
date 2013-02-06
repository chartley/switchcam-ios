//
//  CreateEventViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 2/4/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "CreateEventViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "SPConstants.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

@interface CreateEventViewController ()

@property (strong, nonatomic) MBProgressHUD *loadingIndicator;

- (void)emailLink;

@end

@implementation CreateEventViewController

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
    
    [self.navigationItem setTitle:NSLocalizedString(@"Create Switchcam Shoots", @"")];
    
    // Add Back button
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setFrame:CGRectMake(0, 0, 30, 30)];
    [backButton setImage:[UIImage imageNamed:@"btn-back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backBarButtonItem];
    [self.navigationItem setHidesBackButton:YES];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.openURLButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.openURLButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
    
    // Set Font / Color
    [self.openURLButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.openURLButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.openURLButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
    [self.openURLButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.createEventBodyLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:13]];
    [self.createEventBodyLabel setTextColor:[UIColor whiteColor]];
    [self.createEventBodyLabel setShadowColor:[UIColor blackColor]];
    [self.createEventBodyLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // Add loading indicator
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.loadingIndicator = [[MBProgressHUD alloc] initWithWindow:appDelegate.window];
    [appDelegate.window addSubview:self.loadingIndicator];
}

- (void)viewDidUnload {
    // Remove Loading Indicator
    [self.loadingIndicator removeFromSuperview];
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - IBActions

- (IBAction)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)emailLinkButtonAction:(id)sender {
    [self.loadingIndicator show:YES];
    [self emailLink];
}

#pragma mark - Network Requests

- (void)emailLink {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^emailLinkSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^emailLinkFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    emailLinkSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.loadingIndicator hide:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success!", @"") message:NSLocalizedString(@"We've sent an email to your mailbox with details for using your Director account.", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Great!", @"") otherButtonTitles: nil];
        [alertView show];
    };
    
    emailLinkFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.loadingIndicator hide:YES];
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"We're having trouble connecting to the server, please try again.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alertView show];
        }
    };
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"addshootrequest/"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];
    
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:emailLinkSuccessBlock failure:emailLinkFailureBlock];
    
    [operation start];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self backButtonAction:nil];
}

@end
