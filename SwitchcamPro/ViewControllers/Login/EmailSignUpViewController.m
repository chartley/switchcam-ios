//
//  EmailLoginViewController.m
//  SwitchcamPro
//
//  Created by Matt Ketterer on 4/8/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import "UAPush.h"
#import "EmailLoginViewController.h"
#import "EmailSignUpViewController.h"
#import "LabelTextFieldCell.h"
#import "ButtonCell.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "SPConstants.h"

@interface EmailSignUpViewController () <UITextFieldDelegate> {
    BOOL isRegistrationComplete;
}

@property (strong, nonatomic) UITextField *firstNameTextField;
@property (strong, nonatomic) UITextField *lastNameTextField;
@property (strong, nonatomic) UITextField *userEmailTextField;
@property (strong, nonatomic) UITextField *userPasswordTextField;

@property (strong, nonatomic) NSString *userFirstNameString;
@property (strong, nonatomic) NSString *userLastNameString;
@property (strong, nonatomic) NSString *userEmailString;
@property (strong, nonatomic) NSString *userPasswordString;
@property (strong, nonatomic) MBProgressHUD *loadingIndicator;

@end

@implementation EmailSignUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        isRegistrationComplete = NO;
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
    [self.navigationItem setTitle:NSLocalizedString(@"Email Login", @"")];
    
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

- (void)signUp {
    [self.loadingIndicator show:YES];
    
    // Completion Blocks
    void (^signUpSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^signUpFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    signUpSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.loadingIndicator hide:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSPHasUserPreviouslyLoggedInKey];
        
        isRegistrationComplete = YES;
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate successfulLoginViewControllerChange];
    };
    
    signUpFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.loadingIndicator hide:YES];
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else if ([[operation response] statusCode] == 401) {
            // Username taken
            NSString *title = NSLocalizedString(@"Email already registered", @"");
            NSString *message = NSLocalizedString(@"This email is already in use, please use another and try again.", @"");
            
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
    
    NSString *path = [NSString stringWithFormat:@"person/"];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:self.userFirstNameString, @"first_name",
                                self.userLastNameString, @"last_name",
                                self.userEmailString, @"email",
                                self.userPasswordString, @"password", nil];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:signUpSuccessBlock failure:signUpFailureBlock];
    
    [operation start];
}

- (void)apnRegistration {
    // Completion Blocks
    void (^apnRegistrationSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^apnRegistrationFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    apnRegistrationSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.loadingIndicator hide:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSPHasUserPreviouslyLoggedInKey];
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate successfulLoginViewControllerChange];
    };
    
    apnRegistrationFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
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
    
    NSString *apnToken = [[UAPush shared] deviceToken];
    
    // Verify we have something
    if (apnToken == nil || [apnToken isEqualToString:@""]) {
        // If nil or empty set to 0
        apnToken = @"0";
    }
    
    NSString *path = [NSString stringWithFormat:@"person/me/token/%@/", apnToken];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:apnRegistrationSuccessBlock failure:apnRegistrationFailureBlock];
    
    [operation start];
}


#pragma mark - IBActions

- (IBAction)switchcamUserSignUp:(id)sender {
    if (isRegistrationComplete) {
        [self.loadingIndicator show:YES];
        [self apnRegistration];
    } else {
        if ([self hasValidLoginFields]) {
            [self signUp];
        } else {
            NSString *title = NSLocalizedString(@"Invalid Fields", @"");
            NSString *message = NSLocalizedString(@"Please ensure that all your fields are filled in and valid and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (IBAction)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Helper Methods

- (BOOL)isValidEmail:(NSString *)emailString {
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailString];
}

- (BOOL)hasValidLoginFields {
    // Empty check
    if (self.userFirstNameString == nil || [self.userFirstNameString isEqualToString:@""]) {
        return NO;
    } else if (self.userLastNameString == nil || [self.userLastNameString isEqualToString:@""]) {
        return NO;
    } else if (self.userEmailString == nil || [self.userEmailString isEqualToString:@""]) {
        return NO;
    } else if (self.userPasswordString == nil || [self.userPasswordString isEqualToString:@""]) {
        return NO;
    }
    
    // Valid email check
    if (![self isValidEmail:self.userEmailString]) {
        return NO;
    }
    
    return YES;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        {
            LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
            [labelTextFieldCell.separator setHidden:YES];
            self.firstNameTextField = labelTextFieldCell.textField;
            [labelTextFieldCell.leftLabel setText:NSLocalizedString(@"First Name", @"")];
            [labelTextFieldCell.textField setPlaceholder:NSLocalizedString(@"John", @"")];
            [labelTextFieldCell.textField setSecureTextEntry:NO];
            [labelTextFieldCell.textField setReturnKeyType:UIReturnKeyNext];
            [labelTextFieldCell.textField setText:self.userFirstNameString];
            break;
        }
            
        case 1:
        {
            LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
            [labelTextFieldCell.separator setHidden:NO];
            self.lastNameTextField = labelTextFieldCell.textField;
            [labelTextFieldCell.leftLabel setText:NSLocalizedString(@"Last Name", @"")];
            [labelTextFieldCell.textField setPlaceholder:NSLocalizedString(@"Doe", @"")];
            [labelTextFieldCell.textField setSecureTextEntry:NO];
            [labelTextFieldCell.textField setReturnKeyType:UIReturnKeyNext];
            [labelTextFieldCell.textField setText:self.userLastNameString];
            break;
        }
        case 2:
        {
            LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
            [labelTextFieldCell.separator setHidden:NO];
            self.userEmailTextField = labelTextFieldCell.textField;
            [labelTextFieldCell.leftLabel setText:NSLocalizedString(@"Email Address", @"")];
            [labelTextFieldCell.textField setPlaceholder:NSLocalizedString(@"johndoe@mail.com", @"")];
            [labelTextFieldCell.textField setSecureTextEntry:NO];
            [labelTextFieldCell.textField setReturnKeyType:UIReturnKeyNext];
            [labelTextFieldCell.textField setText:self.userEmailString];
            break;
        }
            
        case 3:
        {
            LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
            [labelTextFieldCell.separator setHidden:NO];
            self.userPasswordTextField = labelTextFieldCell.textField;
            [labelTextFieldCell.leftLabel setText:NSLocalizedString(@"Password", @"")];
            [labelTextFieldCell.textField setPlaceholder:@""];
            [labelTextFieldCell.textField setSecureTextEntry:YES];
            [labelTextFieldCell.textField setReturnKeyType:UIReturnKeyJoin];
            [labelTextFieldCell.textField setText:self.userPasswordString];
            break;
        }
        case 4:
        {
            ButtonCell *buttonCell = (ButtonCell *)cell;
            [buttonCell.bigButton addTarget:self action:@selector(switchcamUserSignUp:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.row) {
        case 0:
        case 1:
        case 2:
        case 3:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelTextFieldCellIdentifier];
            break;
        }
        case 4:
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
            case 1:
            case 2:
            case 3:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelTextFieldCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
                [labelTextFieldCell.leftLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
                [labelTextFieldCell.textField setTextColor:[UIColor whiteColor]];
                [labelTextFieldCell.textField setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:17]];
                [labelTextFieldCell.textField setDelegate:self];
                break;
            }
            case 4:
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
    } else if (indexPath.row == 4) {
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
        case 1:
        case 2:
        case 3:
        {
            return kLabelTextFieldCellRowHeight;
            break;
        }
        case 4:
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.firstNameTextField) {
        self.userFirstNameString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    } else if (textField == self.lastNameTextField) {
        self.userLastNameString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    } else if (textField == self.userEmailTextField) {
        self.userEmailString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    } else if (textField == self.userPasswordTextField) {
        self.userPasswordString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.firstNameTextField) {
        [self.lastNameTextField becomeFirstResponder];
    } else if (textField == self.lastNameTextField) {
        [self.userEmailTextField becomeFirstResponder];
    } else if (textField == self.userEmailTextField) {
        [self.userPasswordTextField becomeFirstResponder];
    } else if (textField == self.userPasswordTextField) {
        [self switchcamUserSignUp:nil];
    }
    
    return YES;
}

@end
