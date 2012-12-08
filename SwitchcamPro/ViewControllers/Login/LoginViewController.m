//
//  LoginViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "LoginViewController.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "SPConstants.h"
#import <FacebookSDK/FacebookSDK.h>
#import "SPPagingScrollView.h"
#import "CompleteLoginViewController.h"

@interface LoginViewController ()

@property (strong, nonatomic) MBProgressHUD *loadingIndicator;
@property (strong, nonatomic) FBSession *fbSession;
@property (strong, nonatomic) SPPagingScrollView *pagingScrollView;

@end


@implementation LoginViewController

@synthesize loadingIndicator;
@synthesize fbSession;
@synthesize pagingScrollView;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged:) name:SCSessionStateChangedNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark - Helper Methods

- (BOOL)hasCorrectPermissions {

    return NO;
}

- (void)gatherDataCompleteLogin {
    // Check permissions before starting
    [[FBRequest requestForGraphPath:@"me/permissions"] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphObject> *user, NSError *error) {
        NSDictionary *acceptedPermissions = [[user objectForKey:@"data"] objectAtIndex:0];
        if ([acceptedPermissions objectForKey:@"email"] &&
            [acceptedPermissions objectForKey:@"publish_actions"]) {
            
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
            
        } else {
            // Show error
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"You must accept all permissions in order to use this application.", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
            [alertView show];
            [FBSession.activeSession closeAndClearTokenInformation];
            [loadingIndicator hide:YES];
        }
    }];
}

#pragma mark - IBActions

- (IBAction)facebookConnectButtonAction:(id)sender {
    // The user has initiated a login, so call the openSession method.
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate openReadSessionWithAllowLoginUI:YES];
    
    [loadingIndicator show:YES];
}

- (IBAction)doneButtonAction:(id)sender {
    
    // Show Loading Indicator
    [loadingIndicator show:YES];
}

#pragma mark - Observer Methods

- (void)stateChanged:(NSNotification*)notification {
    FBSession *session = (FBSession *) [notification object];
    
    switch (session.state) {
        case FBSessionStateOpen: {
            [self gatherDataCompleteLogin];
        }
            break;
        case FBSessionStateClosed: {
            [loadingIndicator hide:YES];
        }
            break;
        case FBSessionStateClosedLoginFailed: {
            [loadingIndicator hide:YES];
        }
            break;
        default:
            break;
    }
}

@end
