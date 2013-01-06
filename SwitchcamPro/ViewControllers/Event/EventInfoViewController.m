//
//  EventInfoViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "AFNetworking.h"
#import "EventInfoViewController.h"
#import "SPConstants.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "Mission.h"

@interface EventInfoViewController ()

@property (strong, nonatomic) MBProgressHUD *blockingLoadingIndicator;

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
    
    // Add loading indicator
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.blockingLoadingIndicator = [[MBProgressHUD alloc] initWithWindow:appDelegate.window];
    [appDelegate.window addSubview:self.blockingLoadingIndicator];
}

- (void)viewDidUnload {
    // Remove Loading Indicator
    [self.blockingLoadingIndicator removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)imGoingButtonAction:(id)sender {
    if (![self.imGoingButton isSelected]) {
        [self joinCameraCrew];
    }
}

- (IBAction)imNotGoingButtonAction:(id)sender {
    if (![self.imNotGoingButton isSelected]) {
        [self followMission];
    }
}

#pragma mark - Network Request

- (void)joinCameraCrew {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^joinCameraCrewSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^joinCameraCrewFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    joinCameraCrewSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.blockingLoadingIndicator hide:YES];
        
        [self.imGoingButton setSelected:YES];
        [self.imNotGoingButton setSelected:NO];
        [self.goingDetailLabel setText:NSLocalizedString(@"We'll send you updates during the shoot and notify you when to start shooting.", @"")];
    };
    
    joinCameraCrewFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.blockingLoadingIndicator hide:YES];
        
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
    
    NSString *path = [NSString stringWithFormat:@"mission/%@/camera_crew/", self.selectedMission.missionId];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:joinCameraCrewSuccessBlock failure:joinCameraCrewFailureBlock];
    
    [operation start];
}

- (void)followMission {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^followMissionSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^followMissionFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    followMissionSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.blockingLoadingIndicator hide:YES];
        [self.imGoingButton setSelected:NO];
        [self.imNotGoingButton setSelected:YES];
        [self.goingDetailLabel setText:NSLocalizedString(@"Bummer! Watch the activity feed during the event and we'll notify you when the final event is built!", @"")];
    };
    
    followMissionFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.blockingLoadingIndicator hide:YES];
        
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
    
    NSString *path = [NSString stringWithFormat:@"mission/%@/follower/", self.selectedMission.missionId];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:followMissionSuccessBlock failure:followMissionFailureBlock];
    
    [operation start];
}

@end
