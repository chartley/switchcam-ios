//
//  FindEventsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FindEventsViewController.h"
#import "ECSlidingViewController.h"
#import "EventViewController.h"
#import "MenuViewController.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "SPConstants.h"
#import "Mission.h"

@interface FindEventsViewController () <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation FindEventsViewController

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
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-signin"]];
    [backgroundImageView setFrame:CGRectMake(0, 175, backgroundImageView.frame.size.width, backgroundImageView.frame.size.height)];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    [self.eventsTableView setTableFooterView:[[UIView alloc] init]];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    // Set the background for any states you plan to use
    [self.findEventsButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.findEventsButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
    // Set Frame of textfield
    [self.eventSearchTextField setFrame:CGRectMake(self.eventSearchTextField.frame.origin.x, self.eventSearchTextField.frame.origin.y, self.eventSearchTextField.frame.size.width, 40)];
    
    // Set Font / Color
    [self.findEventsButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:20]];
    [self.findEventsButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.findEventsButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.findEventsButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:18]];
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    [self.titleLabel setShadowColor:[UIColor blackColor]];
    [self.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.noEventsFoundHeaderLabel setFont:[UIFont fontWithName:@"SourceSansPro-SemiBold" size:17]];
    [self.noEventsFoundHeaderLabel setTextColor:[UIColor whiteColor]];
    [self.noEventsFoundHeaderLabel setShadowColor:[UIColor blackColor]];
    [self.noEventsFoundHeaderLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.noEventsFoundDetailLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:17]];
    [self.noEventsFoundDetailLabel setTextColor:[UIColor whiteColor]];
    [self.noEventsFoundDetailLabel setShadowColor:[UIColor blackColor]];
    [self.noEventsFoundDetailLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // Load up any cached events
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Mission"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDatetime" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"following == NO"];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 30;
    NSError *error = nil;
    
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    [self.fetchedResultsController performFetch:&error];
    
    [self findEventsWithLocation:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)locationButtonAction:(id)sender {
    // Resign first responder if up
    [self.eventSearchTextField resignFirstResponder];
    
    // Fire off request for events near user
    [self findEventsWithLocation:YES];
}

- (IBAction)findYourEventButtonAction:(id)sender {
    [self.eventSearchTextField resignFirstResponder];
    [self findEventsWithLocation:NO];
}

#pragma mark - Network Calls

- (void)findEventsWithLocation:(BOOL)usingLocation {
    NSDictionary *parameters = nil;
    
    // Check if we have search text
    if (self.eventSearchTextField.text != nil && ![self.eventSearchTextField.text isEqualToString:@""]) {
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:self.eventSearchTextField.text, @"terms", nil];
    }
    
    //TODO Location
    if (usingLocation) {
        
    }
    
    // Load the object model via RestKit
    [[RKObjectManager sharedManager] getObjectsAtPath:@"mission/" parameters:parameters success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        // Show correct view depending on result count
        if ([[mappingResult array] count] == 0) {
            [self.noEventsFoundView setHidden:NO];
            [self.eventsTableView setHidden:YES];
        } else {
            [self.noEventsFoundView setHidden:YES];
            [self.eventsTableView setHidden:NO];
        }
        
        // Mark these missions as following
        for (Mission *mission in [mappingResult array]) {
            if (mission.following == nil) {
                mission.following = [NSNumber numberWithBool:NO];
            }
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventsTableView reloadData];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Load failed with error: %@", error);
        // Error message
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
    }];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    Mission *mission = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d. MMMM YYYY"];
    NSString *startEventTimeString = [dateFormatter stringFromDate:[mission startDatetime]];
    
    NSString *detailString = [NSString stringWithFormat:@"%@ %@", @"San Francisco", startEventTimeString];
    
    FindEventCell *findEventCell = (FindEventCell *)cell;
    [findEventCell.locationLabel setText:[mission title]];
    [findEventCell.detailLabel setText:detailString];
    [findEventCell setDelegate:self];
    [findEventCell setTag:indexPath.row];
    
    if ([[mission following] boolValue]) {
        [findEventCell.joinButton setEnabled:NO];
    } else {
        [findEventCell.joinButton setEnabled:YES];
    }
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    return kFindEventCellRowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFindEventCellIdentifier];
    
    if (cell == nil) {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"FindEventCell" owner:self options:nil];
        cell = [nibArray objectAtIndex:0];
        
        // Set Custom Font
        FindEventCell *findEventCell = (FindEventCell *)cell;
        [findEventCell.locationLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:17]];
        [findEventCell.detailLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        
        [findEventCell.locationLabel setShadowColor:[UIColor blackColor]];
        [findEventCell.detailLabel setShadowColor:[UIColor blackColor]];
        
        [findEventCell.locationLabel setShadowOffset:CGSizeMake(0, 1)];
        [findEventCell.detailLabel setShadowOffset:CGSizeMake(0, 1)];
        
        // Set Button Image
        UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
        
        // Set Button Image
        UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
        
        [findEventCell.joinButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
        
        // Set the background for any states you plan to use
        [findEventCell.joinButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [findEventCell.joinButton setBackgroundImage:highlightButtonImage forState:UIControlStateHighlighted];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.eventsTableView reloadData];
}

#pragma mark - FindEventCellDelegate methods

- (void)joinButtonPressed:(FindEventCell*)findEventCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:findEventCell.tag inSection:0];
    Mission *mission = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Load Event View Controller
    EventViewController *viewController = [[EventViewController alloc] init];
    [viewController setMission:mission];
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;

        CGRect frame = appDelegate.slidingViewController.topViewController.view.frame;
        appDelegate.slidingViewController.topViewController = viewController;
        appDelegate.slidingViewController.topViewController.view.frame = frame;
        [appDelegate.slidingViewController resetTopView];
    }];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.eventSearchTextField) {
        [self findEventsWithLocation:NO];
    }
    
    return YES;
}

@end
