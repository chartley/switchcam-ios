//
//  CompleteLoginViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "UAPush.h"
#import "CompleteLoginViewController.h"
#import "LabelProfileCell.h"
#import "LabelTextFieldCell.h"
#import "ButtonCell.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "SPConstants.h"

@interface CompleteLoginViewController () {
    BOOL hasSetEmail;
}

@property (strong, nonatomic) MBProgressHUD *loadingIndicator;

@end

@implementation CompleteLoginViewController

@synthesize loadingIndicator;

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
    [self.navigationItem setTitle:NSLocalizedString(@"Complete sign up...", @"")];
    
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

#pragma mark - Network Calls

- (void)login {
    [loadingIndicator show:YES];
    
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^apnRegistrationSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^apnRegistrationFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    apnRegistrationSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [loadingIndicator hide:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSPHasUserPreviouslyLoggedInKey];
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate successfulLoginViewControllerChange];
    };
    
    apnRegistrationFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [loadingIndicator hide:YES];
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
    
    NSString *apnToken = [[UAPush shared] deviceToken];
    
    // Verify we have something
    if (apnToken == nil || [apnToken isEqualToString:@""]) {
        // If nil or empty set to 0
        apnToken = @"0";
    }
    
    NSString *path = [NSString stringWithFormat:@"person/me/token/%@/", apnToken];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];
    [request setValue:@"facebook" forHTTPHeaderField:@"Auth-Type"];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:apnRegistrationSuccessBlock failure:apnRegistrationFailureBlock];
    
    [operation start];
}

- (void)setEmail {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^setEmailSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^setEmailFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    setEmailSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        hasSetEmail = YES;
        [self login];
    };
    
    setEmailFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [loadingIndicator hide:YES];
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else if ([[operation response] statusCode] == 400) {
            // User may have already set their email address with Switchcam login
            // Continue on if we get a 400 here.
            hasSetEmail = YES;
            [self login];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"We're having trouble connecting to the server, please try again.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alertView show];
        }
    };
    
    // Setup Parameters
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:self.userEmailTextField.text forKey:@"email"];
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"person/me/"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:path parameters:parameters];
    [request setValue:@"facebook" forHTTPHeaderField:@"Auth-Type"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:setEmailSuccessBlock failure:setEmailFailureBlock];
    
    [operation start];
}

#pragma mark - IBActions

- (IBAction)switchcamUserLogin:(id)sender {
    // Check if failure was after email was set
    if (hasSetEmail) {
        // APN Registration with Switchcam API
        [self login];
    } else {
        // Set Email
        [self setEmail];
    }
}

- (IBAction)backButtonAction:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        {
            LabelProfileCell *labelProfileCell = (LabelProfileCell *)cell;
            
            [labelProfileCell.profileNameLabel setText:self.userFullNameString];
            [labelProfileCell.profileImageView setImageWithURL:self.userProfileURL placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
            break;
        }
            
        case 1:
        {
            LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
            self.userEmailTextField = labelTextFieldCell.textField;
            [labelTextFieldCell.textField setText:self.userEmailString];
            break;
        }
        case 2:
        {
            ButtonCell *buttonCell = (ButtonCell *)cell;
            [buttonCell.bigButton addTarget:self action:@selector(switchcamUserLogin:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.row) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelProfileCellIdentifier];
            break;
        }
            
        case 1:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelTextFieldCellIdentifier];
            break;
        }
        case 2:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kButtonCellIdentifier];
            break;
        }
        default:
            break;
    }
    
    if (cell == nil) {
        switch (indexPath.row) {
            case 0:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelProfileCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                break;
            }
                
            case 1:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelTextFieldCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
                [labelTextFieldCell.leftLabel setText:NSLocalizedString(@"Email Address", @"")];
                [labelTextFieldCell.leftLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
                [labelTextFieldCell.textField setTextColor:[UIColor whiteColor]];
                [labelTextFieldCell.textField setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:17]];
                [labelTextFieldCell.textField setDelegate:self];
                
                break;
            }
            case 2:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                // Set Button Image
                UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                        resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                UIImage *buttonImageHighlight = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                                 resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                // Set the background for any states you plan to use
                [((ButtonCell*)cell).bigButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
                [((ButtonCell*)cell).bigButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
                
                // Set Font / Color
                [((ButtonCell*)cell).bigButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
                [((ButtonCell*)cell).bigButton.titleLabel setTextColor:[UIColor whiteColor]];
                [((ButtonCell*)cell).bigButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
                [((ButtonCell*)cell).bigButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
                break;
            }
            default:
                break;
        }
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    // Set backgrounds
    if (indexPath.row == 0) {
        // Top
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-top"]]];
    } else if (indexPath.row == 2) {
        // Bottom
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-bottom"]]];
    } else {
        // Middle
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-middle"]]];
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    switch (indexPath.row) {
        case 0:
        {
            return kLabelProfileCellRowHeight;
            break;
        }
            
        case 1:
        {
            return kLabelTextFieldCellRowHeight;
            break;
        }
        case 2:
        {
            return kButtonCellRowHeight;
            break;
        }
        default:
            return 0;
            break;
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
