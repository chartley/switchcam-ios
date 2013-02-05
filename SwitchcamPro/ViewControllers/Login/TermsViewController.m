//
//  TermsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/21/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <AFNetworking.h>
#import <FacebookSDK/FacebookSDK.h>
#import <QuartzCore/QuartzCore.h>
#import "TermsViewController.h"
#import "CompleteLoginViewController.h"
#import "SPConstants.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

@interface TermsViewController ()

@property (strong, nonatomic) MBProgressHUD *loadingIndicator;

@end

@implementation TermsViewController

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
    
    // Add Back button
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setFrame:CGRectMake(0, 0, 30, 30)];
    [backButton setImage:[UIImage imageNamed:@"btn-back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backBarButtonItem];
    [self.navigationItem setHidesBackButton:YES];
    
    [self.navigationItem setTitle:NSLocalizedString(@"Terms & Conditions", @"")];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.iAgreeButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.iAgreeButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
    
    // Round the corners on the accept area
    [self.acceptView.layer setCornerRadius:5.0f];
    [self.acceptView.layer setBorderColor:RGBA(58, 60, 61, 1).CGColor];
    [self.acceptView.layer setBorderWidth:1.5f];
    [self.acceptView.layer setMasksToBounds:YES];
    
    // Set Font
    [self.acceptTermsLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
    
    // Load stored TOS
    [self.webView loadRequest:[NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"TOS" ofType:@"html"] isDirectory:NO]]];
    
    // Add loading indicator
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.loadingIndicator = [[MBProgressHUD alloc] initWithWindow:appDelegate.window];
    [appDelegate.window addSubview:self.loadingIndicator];
}

- (void)viewDidUnload {
    // Remove Loading Indicator
    [self.loadingIndicator removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - IBAction

- (IBAction)iAgreeButtonAction:(id)sender {
    [self.loadingIndicator show:YES];
    
    [self acceptTerms];
}

- (IBAction)backButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Network Request

- (void)acceptTerms {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^acceptTermsSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^acceptTermsFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    acceptTermsSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.loadingIndicator hide:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSPUserAcceptedTermsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Get Information about the user
        [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphObject> *user, NSError *error) {
            NSString *userFullName = [NSString stringWithFormat:@"%@ %@", [user objectForKey:@"first_name"], [user objectForKey:@"last_name"]];
            NSURL *profileImageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", [user objectForKey:@"id"]]];
            
            // Add data to next controller and start
            CompleteLoginViewController *completeLoginViewController = [[CompleteLoginViewController alloc] init];
            [completeLoginViewController setUserEmailString:[user objectForKey:@"email"]];
            [completeLoginViewController setUserFullNameString:userFullName];
            [completeLoginViewController setUserProfileURL:profileImageURL];
            [self.navigationController pushViewController:completeLoginViewController animated:YES];
            [self.navigationController setNavigationBarHidden:NO];
        }];
    };
    
    acceptTermsFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
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
    
    // Setup Parameters
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:@"now" forKey:@"legal_terms_accept_date"];
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"person/me/"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:path parameters:parameters];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:acceptTermsSuccessBlock failure:acceptTermsFailureBlock];
    
    [operation start];
}

@end
