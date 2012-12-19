//
//  CompleteLoginViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/4/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "CompleteLoginViewController.h"
#import "LabelProfileCell.h"
#import "LabelSubLabelCell.h"
#import "LabelSwitchCell.h"
#import "ButtonCell.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "SPConstants.h"

@interface CompleteLoginViewController ()

@property (strong, nonatomic) MBProgressHUD *loadingIndicator;
@property (strong, nonatomic) UISwitch *staySignedInSwitch;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Network Calls

- (void)login {    
    // Completion Blocks
    void (^userLoginSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^userLoginFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    userLoginSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [loadingIndicator hide:YES];
        NSLog(@"%@",[[operation response] allHeaderFields]);
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate successfulLoginViewControllerChange];
    };
    
    userLoginFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [loadingIndicator hide:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"Your username/password did not match, please try again.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alertView show];
    };
    
    // Some push registration
    /*
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"api/v1/mission/" parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:userLoginSuccessBlock failure:userLoginFailureBlock];
    
    [operation start];
     */
}

#pragma mark - IBActions

- (IBAction)switchcamUserLogin:(id)sender {
    // Save switch setting
    [[NSUserDefaults standardUserDefaults] setBool:self.staySignedInSwitch.isOn forKey:kSPStaySignedInKey];
    
    // Start App
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate successfulLoginViewControllerChange];
}

- (IBAction)backButtonAction:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        {
            LabelProfileCell *labelProfileCell = (LabelProfileCell *)cell;
            
            [labelProfileCell.profileNameLabel setText:self.userFullNameString];
            [labelProfileCell.profileImageView setImageWithURL:self.userProfileURL placeholderImage:[UIImage imageNamed:@""]];
            break;
        }
            
        case 1:
        {
            LabelSubLabelCell *labelSubLabelCell = (LabelSubLabelCell *)cell;
            [labelSubLabelCell.rightLabel setText:self.userEmailString];
            break;
        }
        case 2:
        {
            LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
            self.staySignedInSwitch = labelSwitchCell.staySignedInSwitch;
            break;
        }
        case 3:
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
    return 4;
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
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelSubLabelCellIdentifier];
            break;
        }
        case 2:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelSwitchCellIdentifier];
            break;
        }
        case 3:
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
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelSubLabelCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                break;
            }
            case 2:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelSwitchCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                break;
            }
            case 3:
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
                [((ButtonCell*)cell).bigButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
                [((ButtonCell*)cell).bigButton.titleLabel setTextColor:[UIColor whiteColor]];
                [((ButtonCell*)cell).bigButton.titleLabel setShadowColor:[UIColor blackColor]];
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
    } else if (indexPath.row == 3) {
        // Bottom
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-bottom"]]];
    } else {
        // Middle
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-middle"]]];
    }
    
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
            return kLabelSubLabelCellRowHeight;
            break;
        }
        case 2:
        {
            return kLabelSwitchCellRowHeight;
            break;
        }
        case 3:
        {
            return kButtonCellRowHeight;
            break;
        }
        default:
            return 0;
            break;
    }
}


@end
