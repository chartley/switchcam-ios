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
#import "Venue.h"
#import "Link.h"
#import "EventInfoGoingCell.h"
#import "EventInfoOrganizerCell.h"
#import "EventInfoDetailCell.h"
#import "EventInfoLinksCell.h"

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

- (IBAction)directionsButtonAction:(id)sender {
    NSString *mapURLString = @"";
    
    // Create address string and percent escape
    NSString *addressString = [NSString stringWithFormat:@"%@, %@, %@, %@", self.selectedMission.venue.street, self.selectedMission.venue.city, self.selectedMission.venue.state, self.selectedMission.venue.country];
    addressString = [addressString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // Check if user has google maps
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        mapURLString = [NSString stringWithFormat:@"comgooglemaps://?q=%@&zoom=15&views=transit", addressString];
    } else {
        mapURLString = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@", addressString];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapURLString]];
}

- (IBAction)linkButtonAction:(id)sender {
    UIButton *pressedButton = (UIButton*)sender;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leaving app", @"") message:NSLocalizedString(@"Pressing OK will open this link in Safari", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    [alertView setTag:pressedButton.tag];
    [alertView show];
}

#pragma mark - Network Request

- (void)joinCameraCrew {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^joinCameraCrewSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^joinCameraCrewFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    joinCameraCrewSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        // Do Nothing
    };
    
    joinCameraCrewFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        // Fail silently
    };
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"mission/%@/camera_crew/", self.selectedMission.missionId];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:joinCameraCrewSuccessBlock failure:joinCameraCrewFailureBlock];
    
    [operation start];
    
    // Update buttons
    [self.imGoingButton setSelected:YES];
    [self.imNotGoingButton setSelected:NO];
    [self.goingDetailLabel setText:NSLocalizedString(@"We'll send you updates during the shoot and notify you when to start shooting.", @"")];
    [self.goingDetailLabel sizeToFit];
    
    // Update Participation Drawer
    [self.eventViewController showParticipateDrawer];
    
    // Update mission
    [self.selectedMission setIsCameraCrew:[NSNumber numberWithBool:YES]];
    [self.selectedMission setIsFollowing:[NSNumber numberWithBool:NO]];
    
    NSError *error = nil;
    if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

- (void)followMission {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^followMissionSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^followMissionFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    followMissionSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {        
        // Do Nothing
    };
    
    followMissionFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        // Fail silently
    };
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"mission/%@/follower/", self.selectedMission.missionId];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:followMissionSuccessBlock failure:followMissionFailureBlock];
    
    [operation start];
    
    // Update buttons
    [self.imGoingButton setSelected:NO];
    [self.imNotGoingButton setSelected:YES];
    [self.goingDetailLabel setText:NSLocalizedString(@"Bummer! Watch the activity feed during the event, and we'll notify you when the final event is built!", @"")];
    [self.goingDetailLabel sizeToFit];
    
    // Update Participation Drawer
    [self.eventViewController hideParticipateDrawer];
    
    // Update mission
    [self.selectedMission setIsCameraCrew:[NSNumber numberWithBool:NO]];
    [self.selectedMission setIsFollowing:[NSNumber numberWithBool:YES]];
    
    NSError *error = nil;
    if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        {
            EventInfoGoingCell *eventInfoGoingCell = (EventInfoGoingCell *)cell;
            // Check if we are camera crew or following and adjust view accordingly
            if ([self.selectedMission.isCameraCrew boolValue]) {
                [eventInfoGoingCell.imGoingButton setSelected:YES];
                [eventInfoGoingCell.imNotGoingButton setSelected:NO];
                [eventInfoGoingCell.goingDetailLabel setText:NSLocalizedString(@"We'll send you updates during the shoot and notify you when to start shooting.", @"")];
            } else if ([self.selectedMission.isFollowing boolValue]) {
                [eventInfoGoingCell.imGoingButton setSelected:NO];
                [eventInfoGoingCell.imNotGoingButton setSelected:YES];
                [eventInfoGoingCell.goingDetailLabel setText:NSLocalizedString(@"Bummer! Watch the activity feed during the event, and we'll notify you when the final event is built!", @"")];
            } else {
                [eventInfoGoingCell.imGoingButton setSelected:NO];
                [eventInfoGoingCell.imNotGoingButton setSelected:NO];
                [eventInfoGoingCell.goingDetailLabel setText:NSLocalizedString(@"Let us know if you're attending or not and we'll notify you when to start shooting or when the event video is complete!", @"")];
            }
            
            [self.goingDetailLabel sizeToFit];
            break;
        }
            
        case 1:
        {
            EventInfoOrganizerCell *eventInfoOrganizerCell = (EventInfoOrganizerCell *)cell;
            [eventInfoOrganizerCell.organizerMessageLabel setText:self.selectedMission.missionDescription];
            
            // Calculate height
            CGSize labelSize = [self.selectedMission.missionDescription sizeWithFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:13.0] constrainedToSize:CGSizeMake(280, 5000) lineBreakMode:NSLineBreakByWordWrapping];
            [eventInfoOrganizerCell.organizerMessageLabel setFrame:CGRectMake(eventInfoOrganizerCell.organizerMessageLabel.frame.origin.x, eventInfoOrganizerCell.organizerMessageLabel.frame.origin.y, labelSize.width, labelSize.height)];
            
            int height = 75 + labelSize.height;
            [eventInfoOrganizerCell.bottomSeparatorView setFrame:CGRectMake(0, height-1, 320, 1)];
            
            break;
        }
            
        case 2:
        {
            EventInfoDetailCell *eventInfoDetailCell = (EventInfoDetailCell *)cell;
            
            // Get date string
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"cccc, MMMM d yyyy"];
            
            // Populate fields
            [eventInfoDetailCell.dateLabel setText:[dateFormatter stringFromDate:self.selectedMission.startDatetime]];
            [eventInfoDetailCell.locationNameLabel setText:self.selectedMission.venue.venueName];
            [eventInfoDetailCell.streetAddressLabel setText:self.selectedMission.venue.street];
            [eventInfoDetailCell.cityStateZipLabel setText:[NSString stringWithFormat:@"%@, %@ %@", self.selectedMission.venue.city, self.selectedMission.venue.state, @""]];
            
            // Set Action
            [eventInfoDetailCell.directionsButton addTarget:self action:@selector(directionsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        case 3:
        {
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.selectedMission.links count] > 0) {
        return 4;
    } else {
        return 3;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.row) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kEventInfoGoingCellIdentifier];
            break;
        }
            
        case 1:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kEventInfoOrganizerCellIdentifier];
            break;
        }
        case 2:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kEventInfoDetailCellIdentifier];
            break;
        }
        case 3:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kEventInfoLinksCellIdentifier];
        }
        default:
            break;
    }
    
    if (cell == nil) {
        switch (indexPath.row) {
            case 0:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"EventInfoGoingCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                // Set Fonts
                EventInfoGoingCell *eventInfoGoingCell = (EventInfoGoingCell *)cell;
                
                // Keep these objects
                self.imGoingButton = eventInfoGoingCell.imGoingButton;
                self.imNotGoingButton = eventInfoGoingCell.imNotGoingButton;
                self.goingDetailLabel = eventInfoGoingCell.goingDetailLabel;
                
                [self.imGoingButton addTarget:self action:@selector(imGoingButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                [self.imNotGoingButton addTarget:self action:@selector(imNotGoingButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                
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
                [self.imGoingButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
                [self.imGoingButton.titleLabel setTextColor:[UIColor whiteColor]];
                [self.imGoingButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
                [self.imGoingButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
                
                [self.imNotGoingButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
                [self.imNotGoingButton.titleLabel setTextColor:[UIColor whiteColor]];
                [self.imNotGoingButton.titleLabel setShadowColor:RGBA(112, 54, 26, 1.0)];
                [self.imNotGoingButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
                
                [self.goingDetailLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:13]];
                [self.goingDetailLabel setTextColor:RGBA(166,166,166,1)];
                [self.goingDetailLabel setShadowColor:[UIColor blackColor]];
                [self.goingDetailLabel setShadowOffset:CGSizeMake(0, -1)];
                break;
            }
                
            case 1:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"EventInfoOrganizerCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                // Set Fonts
                EventInfoOrganizerCell *eventInfoOrganizerCell = (EventInfoOrganizerCell *)cell;
                [eventInfoOrganizerCell.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:13.0]];
                [eventInfoOrganizerCell.organizerMessageLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:13.0]];
                break;
            }
                
            case 2:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"EventInfoDetailCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                // Set Fonts
                EventInfoDetailCell *eventInfoDetailCell = (EventInfoDetailCell *)cell;
                [eventInfoDetailCell.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:13.0]];
                [eventInfoDetailCell.dateLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:14.0]];
                [eventInfoDetailCell.locationNameLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:14.0]];
                [eventInfoDetailCell.streetAddressLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:14.0]];
                [eventInfoDetailCell.cityStateZipLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:14.0]];
                [eventInfoDetailCell.tapForDirectionsLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:11.0]];
                break;
            }
            case 3:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"EventInfoLinksCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                // Set Fonts
                EventInfoLinksCell *eventInfoLinksCell = (EventInfoLinksCell *)cell;
                [eventInfoLinksCell.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:13.0]];
                [eventInfoLinksCell.subTitleLabel setFont:[UIFont fontWithName:@"SourceSansPro-LightIt" size:13.0]];
                
                int i = 0;
                
                // Make sure array index is same
                NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"linkName" ascending:NO];
                NSArray *linkArray = [self.selectedMission.links sortedArrayUsingDescriptors:@[descriptor]];
                
                for (Link *link in linkArray) {
                    UIButton *linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    [linkButton setFrame:CGRectMake(20, 55 + (40*i), 280, 40)];
                    
                    // Set Button Image
                    UIImage *buttonImage = [[UIImage imageNamed:@"btn-lg-grey"]
                                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"btn-lg-grey-pressed"]
                                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
                    // Set the background for any states you plan to use
                    [linkButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
                    [linkButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
                    [linkButton setTitle:link.linkName forState:UIControlStateNormal];
                    [linkButton setTag:i];
                    [linkButton addTarget:self action:@selector(linkButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                    [linkButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
                    [linkButton.titleLabel setTextColor:[UIColor whiteColor]];
                    [linkButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
                    [linkButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
                    [eventInfoLinksCell.contentView addSubview:linkButton];
                    i++;
                }
                break;
            }
            default:
                break;
        }
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
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
            return kEventInfoGoingCellRowHeight;
            break;
        }
        case 1:
        {
            // Calculate height
            CGSize labelSize = [self.selectedMission.missionDescription sizeWithFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:13.0] constrainedToSize:CGSizeMake(280, 5000) lineBreakMode:NSLineBreakByWordWrapping];

            
            int height = 75 + labelSize.height;
            return height;
            break;
        }
            
        case 2:
        {
            return kEventInfoDetailCellRowHeight;
            break;
        }
        case 3:
        {
            // Calculate height
            int height = 55 + ([self.selectedMission.links count] * 52);
            return height;
            break;
        }
        default:
            return 0;
            break;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Canceled
    } else {
        // Launch Link
        
        // Make sure array index is same
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"linkName" ascending:NO];
        NSArray *linkArray = [self.selectedMission.links sortedArrayUsingDescriptors:@[descriptor]];
        
        Link *link = [linkArray objectAtIndex:alertView.tag];
        NSURL *urlToLaunch = [NSURL URLWithString:[link linkURL]];
        
        [[UIApplication sharedApplication] openURL:urlToLaunch];
    }
}

@end
