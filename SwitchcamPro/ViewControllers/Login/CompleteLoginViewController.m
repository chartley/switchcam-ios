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
    
    // Start App
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate successfulLoginViewControllerChange];
}

- (IBAction)valueChanged:(id)sender {
    
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
            labelSwitchCell.staySignedInSwitch = labelSwitchCell.staySignedInSwitch;
            [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
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
                break;
            }
            default:
                break;
        }
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
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


@end
