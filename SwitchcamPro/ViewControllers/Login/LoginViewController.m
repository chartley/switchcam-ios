//
//  LoginViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "SPConstants.h"
#import <FacebookSDK/FacebookSDK.h>
#import "CompleteLoginViewController.h"
#import "UIImage+H568.h"
#import "SlideView.h"

@interface LoginViewController ()

@property (strong, nonatomic) MBProgressHUD *loadingIndicator;
@property (strong, nonatomic) FBSession *fbSession;
@property (strong, nonatomic) SPPagingScrollView *pagingScrollView;
@property (strong, nonatomic) NSMutableArray *walkthroughViews;

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
    
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-signin"]];
    [self.view addSubview:backgroundImageView];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-fb-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"btn-fb-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    // Set the background for any states you plan to use
    [self.loginButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.loginButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
    // Listen for app fade in
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slideUpSwitchCamAnimation) name:kAppFadeInCompleteNotification object:nil];
    
    // Load Walkthrough Views
    [self loadWalthroughViews];
    
    // Create paging scrollview
    self.pagingScrollView = [[SPPagingScrollView alloc] initWithFrame:self.view.frame];
    [self.pagingScrollView setBackgroundColor:[UIColor clearColor]];
    [self.pagingScrollView setPagingDelegate:self];
    [self.pagingScrollView setDelegate:self];
    [self.view addSubview:self.pagingScrollView];
    [self.pagingScrollView reloadPages];
    
    // Set Font / Color
    [self.slide0Label setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.slide0Label setTextColor:[UIColor whiteColor]];
    [self.slide0Label setShadowColor:[UIColor blackColor]];
    [self.slide0Label setShadowOffset:CGSizeMake(0, -1)];
    
    // Fix layout
    [self.view sendSubviewToBack:self.pagingScrollView];
    [self.view sendSubviewToBack:backgroundImageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    
}

#pragma mark - Helper Methods

- (void)loadWalthroughViews {
    self.walkthroughViews = [NSMutableArray arrayWithCapacity:7];
    
    [self.walkthroughViews addObject:self.slide0View];
    
    for (int i = 1; i < 7; i++) {
        NSString *nibToLoad = [NSString stringWithFormat:@"Slide%dView", i];
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:nibToLoad owner:self options:nil];
        SlideView *slideView = [nibArray objectAtIndex:0];
        
        if (slideView.topLabel) {
            // Set Font / Color
            [slideView.topLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:15]];
            [slideView.topLabel setTextColor:[UIColor whiteColor]];
            [slideView.topLabel setShadowColor:[UIColor blackColor]];
            [slideView.topLabel setShadowOffset:CGSizeMake(0, -1)];
        }

        if (slideView.bottomLabel) {
            // Set Font / Color
            [slideView.bottomLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:15]];
            [slideView.bottomLabel setTextColor:[UIColor whiteColor]];
            [slideView.bottomLabel setShadowColor:[UIColor blackColor]];
            [slideView.bottomLabel setShadowOffset:CGSizeMake(0, -1)];
        }
        
        [self.walkthroughViews addObject:slideView];
    }
    
    NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"Slide1View" owner:self options:nil];
    [self.walkthroughViews addObject:[nibArray objectAtIndex:0]];
    
    nibArray = [[NSBundle mainBundle] loadNibNamed:@"Slide2View" owner:self options:nil];
    [self.walkthroughViews addObject:[nibArray objectAtIndex:0]];
    
    nibArray = [[NSBundle mainBundle] loadNibNamed:@"Slide3View" owner:self options:nil];
    [self.walkthroughViews addObject:[nibArray objectAtIndex:0]];
    
    nibArray = [[NSBundle mainBundle] loadNibNamed:@"Slide4View" owner:self options:nil];
    [self.walkthroughViews addObject:[nibArray objectAtIndex:0]];
    
    nibArray = [[NSBundle mainBundle] loadNibNamed:@"Slide5View" owner:self options:nil];
    [self.walkthroughViews addObject:[nibArray objectAtIndex:0]];
    
    nibArray = [[NSBundle mainBundle] loadNibNamed:@"Slide6View" owner:self options:nil];
    [self.walkthroughViews addObject:[nibArray objectAtIndex:0]];
}

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

#pragma mark - Animations

- (void)slideUpSwitchCamAnimation {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.switchCamLogo setFrame:CGRectMake(self.switchCamLogo.frame.origin.x, 80, self.switchCamLogo.frame.size.width, self.switchCamLogo.frame.size.height)];
    } completion:^(BOOL finished) {
        [self fadeInControlsAnimation];
    }];
}

- (void)fadeInControlsAnimation {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.loginButton setAlpha:1.0];
        [self.facebookLogo setAlpha:1.0];
        [self.pageControl setAlpha:1.0];
        [self.slide0Label setAlpha:1.0];
    } completion:^(BOOL finished) {
    }];
}

#pragma mark - SPPagingScrollViewDelegate

- (NSInteger)numberOfPagesInPagingScrollView:(SPPagingScrollView *)pagingScrollView {
    return 7;
}

- (UIView *)pagingScrollView:(SPPagingScrollView *)pagingScrollView pageForIndex:(NSInteger)index {
    return [self.walkthroughViews objectAtIndex:index];
}

#pragma mark - UISCrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    [self.pagingScrollView scrollViewDidScroll];
    [self.pageControl setCurrentPage:[self.pagingScrollView indexOfSelectedPage]];
}
@end
