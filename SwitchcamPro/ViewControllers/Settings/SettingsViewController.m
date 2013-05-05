//
//  SettingsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/5/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AFNetworking/AFNetworking.h>
#import <AVFoundation/AVFoundation.h>
#import "SettingsViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "LabelSwitchCell.h"
#import "ProfileCell.h"
#import "ButtonCell.h"
#import "AppDelegate.h"
#import "SPConstants.h"

#define kUploadQualityCellIdentifier @"UploadQualityCellIdentifier"
#define kSeparatorTag 999

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
    self.navigationController.view.layer.shadowOpacity = 0.75f;
    self.navigationController.view.layer.shadowRadius = 10.0f;
    self.navigationController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    [self.settingsTableView reloadData];
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

- (IBAction)valueChanged:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUploadOver3GEnabled]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUploadOver3GEnabled];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUploadOver3GEnabled];
    }
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
                    [labelSwitchCell.staySignedInSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kUploadOver3GEnabled]];
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
        case 1:{
            NSString *uploadQuality = [[NSUserDefaults standardUserDefaults] objectForKey:kUploadQualityKey];
            switch (indexPath.row) {
                case 0:
                {
                    [cell.textLabel setText:NSLocalizedString(@"540p", @"")];
                    [cell.detailTextLabel setText:NSLocalizedString(@"Small file size", @"")];
                    
                    if ([uploadQuality isEqualToString:AVAssetExportPreset960x540]) {
                        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                    } else {
                        [cell setAccessoryType:UITableViewCellAccessoryNone];
                    }
                    break;
                }
                case 1:
                {
                    [cell.textLabel setText:NSLocalizedString(@"720p", @"")];
                    [cell.detailTextLabel setText:NSLocalizedString(@"Better quality, medium file size", @"")];
                    
                    if ([uploadQuality isEqualToString:AVAssetExportPreset1280x720]) {
                        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                    } else {
                        [cell setAccessoryType:UITableViewCellAccessoryNone];
                    }
                    break;
                }
                case 2:
                {
                    [cell.textLabel setText:NSLocalizedString(@"1080p", @"")];
                    [cell.detailTextLabel setText:NSLocalizedString(@"Best quality, larger file size", @"")];

                    if ([uploadQuality isEqualToString:AVAssetExportPreset1920x1080]) {
                        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                    } else {
                        [cell setAccessoryType:UITableViewCellAccessoryNone];
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 2:
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
                    UIImage *buttonImage = nil;
                    UIImage *buttonImageHighlight = nil;
                    
                    NSString *loginType = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserLoginTypeKey];
                    if ([loginType isEqualToString:kSPUserLoginTypeEmail]) {
                        buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                                resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                        buttonImageHighlight = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                                         resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                        [buttonCell.bigButton setTitle:NSLocalizedString(@"Disconnect", @"") forState:UIControlStateNormal];
                        [buttonCell.bigButton addTarget:self action:@selector(disconnectFacebookButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                    } else {
                        buttonImage = [[UIImage imageNamed:@"btn-fb-lg"]
                                       resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                        buttonImageHighlight = [[UIImage imageNamed:@"btn-fb-lg-pressed"]
                                                resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                        [buttonCell.bigButton setTitle:NSLocalizedString(@" Disconnect Facebook", @"") forState:UIControlStateNormal];
                        [buttonCell.bigButton setImage:[UIImage imageNamed:@"icn-fb"] forState:UIControlStateNormal];
                        [buttonCell.bigButton addTarget:self action:@selector(disconnectFacebookButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                    }

                    // Set the background states
                    [buttonCell.bigButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
                    [buttonCell.bigButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
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
    } else if (section == 1) {
        return 3;
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
            cell = [tableView dequeueReusableCellWithIdentifier:kUploadQualityCellIdentifier];
            break;
        }
        case 2:
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
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kUploadQualityCellIdentifier];
                [cell.textLabel setTextColor:[UIColor whiteColor]];
                [cell.textLabel setBackgroundColor:[UIColor clearColor]];
                [cell.textLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
                
                [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
                [cell.detailTextLabel setBackgroundColor:[UIColor clearColor]];
                [cell.detailTextLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:14]];
                
                UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 43, 320, 1)];
                separator.tag = kSeparatorTag;
                [separator setBackgroundColor:RGBA(47, 50, 51, 1)];
                [cell addSubview:separator];
                break;
            }
            case 2:
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
        // Single
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-single"]]];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            // Top
            [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-top"]]];
        } else if (indexPath.row == 1) {
            // Middle
            [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-middle"]]];
        } else {
            // Bottom
            [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-bottom"]]];
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
    return 3;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        // Upload quality cells
        if (indexPath.row == 0) {
            // Low
            [[NSUserDefaults standardUserDefaults] setObject:AVAssetExportPreset960x540 forKey:kUploadQualityKey];
        } else if (indexPath.row == 1) {
            // Medium
            [[NSUserDefaults standardUserDefaults] setObject:AVAssetExportPreset1280x720 forKey:kUploadQualityKey];
        } else {
            // High
            [[NSUserDefaults standardUserDefaults] setObject:AVAssetExportPreset1920x1080 forKey:kUploadQualityKey];
        }
    }
    [tableView reloadData];
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
            return 44;
            break;
        }
        case 2:
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *titleLabelContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    if (section == 1) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, 44)];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [titleLabel setText:NSLocalizedString(@"Upload Quality", @"")];
        [titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
        [titleLabel setTextColor:[UIColor whiteColor]];
        [titleLabelContainer addSubview:titleLabel];
    } else {
    }
    return titleLabelContainer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 35;
    } else {
        return 0;
    }
}

@end
