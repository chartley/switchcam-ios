//
//  SettingsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/5/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AFNetworking/AFNetworking.h>
#import "SettingsViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "LabelSwitchCell.h"
#import "ProfileCell.h"
#import "ButtonCell.h"
#import "AppDelegate.h"
#import "SPConstants.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

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
    
    [self.navigationItem setTitle:NSLocalizedString(@"Settings", @"")];
    
    // Menu Button and Location Button
    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setFrame:CGRectMake(0, 0, 30, 30)];
    [menuButton setImage:[UIImage imageNamed:@"btn-sidemenu"] forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(menuButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    [self.navigationItem setLeftBarButtonItem:menuBarButtonItem];
    [self.navigationItem setHidesBackButton:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
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

- (IBAction)disconnectFacebookButtonAction:(id)sender {
    // Sign out
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate logoutUser];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {
                    LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
                    [labelSwitchCell.leftLabel setText:NSLocalizedString(@"Upload over 3G", @"")];
                    labelSwitchCell.staySignedInSwitch = labelSwitchCell.staySignedInSwitch;
                    [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
                    [labelSwitchCell.labelSwitchSeparator setHidden:YES];
                    break;
                }
                    
                case 1:
                {
                    LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
                    [labelSwitchCell.leftLabel setText:NSLocalizedString(@"Push Notification 1", @"")];
                    labelSwitchCell.tag = indexPath.row;
                    [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
                    [labelSwitchCell.labelSwitchSeparator setHidden:NO];
                    break;
                }
                case 2:
                {
                    LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
                    [labelSwitchCell.leftLabel setText:NSLocalizedString(@"Push Notification 2", @"")];
                    labelSwitchCell.tag = indexPath.row;
                    [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
                    [labelSwitchCell.labelSwitchSeparator setHidden:NO];
                    break;
                }
                case 3:
                {
                    LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
                    [labelSwitchCell.leftLabel setText:NSLocalizedString(@"Push Notification 3", @"")];
                    labelSwitchCell.tag = indexPath.row;
                    [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
                    [labelSwitchCell.labelSwitchSeparator setHidden:NO];
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                {
                    NSString *userFullName = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFullName];
                    NSString *profileImageURLString = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserProfileURL];
                    NSURL *profileImageURL = [NSURL URLWithString:profileImageURLString];
                    
                    ProfileCell *profileCell = (ProfileCell *)cell;
                    [profileCell.profileNameLabel setText:userFullName];
                    [profileCell.profileImageView setImageWithURL:profileImageURL placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];

                    
                    

                    break;
                }
                    
                case 1:
                {
                    ButtonCell *buttonCell = (ButtonCell *)cell;
                    // Set Button Image
                    UIImage *buttonImage = [[UIImage imageNamed:@"btn-fb-lg"]
                                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"btn-fb-lg-pressed"]
                                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                    // Set the background for any states you plan to use
                    [buttonCell.bigButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
                    [buttonCell.bigButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
                    [buttonCell.bigButton setTitle:NSLocalizedString(@" Disconnect Facebook", @"") forState:UIControlStateNormal];
                    [buttonCell.bigButton setImage:[UIImage imageNamed:@"icn-fb"] forState:UIControlStateNormal];
                    [buttonCell.bigButton addTarget:self action:@selector(disconnectFacebookButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                    break;
                }
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return 2;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelSwitchCellIdentifier];
            [((LabelSwitchCell*)cell).leftLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
            break;
        }
            
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:kProfileCellIdentifier];
                    break;
                }
                case 1:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:kButtonCellIdentifier];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
    
    if (cell == nil) {
        switch (indexPath.section) {
            case 0:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelSwitchCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                break;
            }
                
            case 1:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ProfileCell" owner:self options:nil];
                        cell = [nibArray objectAtIndex:0];
                        break;
                    }
                    case 1:
                    {
                        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
                        cell = [nibArray objectAtIndex:0];
                        break;
                    }
                    default:
                        break;
                }
                break;
            }
            default:
                break;
        }
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    // Set backgrounds
    if (indexPath.section == 0) {
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
    } else {
        if (indexPath.row == 0) {
            // Top
            [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-top"]]];
        } else {
            // Bottom
            [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-bottom"]]];
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    switch (indexPath.section) {
        case 0:
        {
            return kLabelSwitchCellRowHeight;
            break;
        }
            
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    return kProfileCellRowHeight;
                    break;
                }
                case 1:
                {
                    return kButtonCellRowHeight;
                    break;
                }
                    
                default:
                    return 0;
                    break;
            }
            break;
        }
        default:
            return 0;
            break;
    }
}

@end
