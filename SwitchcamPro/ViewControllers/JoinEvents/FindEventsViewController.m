//
//  FindEventsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <QuartzCore/QuartzCore.h>
#import "SPLocationManager.h"
#import "FindEventsViewController.h"
#import "ECSlidingViewController.h"
#import "EventViewController.h"
#import "MenuViewController.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "SPConstants.h"
#import "Mission.h"
#import "Venue.h"
#import "Artist.h"
#import "SPNavigationController.h"
#import "CreateEventViewController.h"
#import "FindEventCell.h"

@interface FindEventsViewController () <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) RKPaginator *shootPaginator;
@property (nonatomic, strong) NSMutableArray *shootArray;

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
    UIImageView *tableBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-signin"]];
    [tableBackgroundImageView setFrame:CGRectMake(0, 138, tableBackgroundImageView.frame.size.width, tableBackgroundImageView.frame.size.height)];
    [self.view addSubview:tableBackgroundImageView];
    [self.view sendSubviewToBack:tableBackgroundImageView];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [backgroundImageView setFrame:CGRectMake(0, 0, backgroundImageView.frame.size.width, backgroundImageView.frame.size.height)];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    // Menu Button and Location Button
    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setFrame:CGRectMake(0, 0, 30, 30)];
    [menuButton setImage:[UIImage imageNamed:@"btn-sidemenu"] forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(menuButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    [self.navigationItem setLeftBarButtonItem:menuBarButtonItem];
    [self.navigationItem setHidesBackButton:YES];
    
    UIButton *locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [locationButton setFrame:CGRectMake(0, 0, 30, 30)];
    [locationButton setImage:[UIImage imageNamed:@"btn-location"] forState:UIControlStateNormal];
    [locationButton addTarget:self action:@selector(locationButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *locationBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:locationButton];
    [self.navigationItem setRightBarButtonItem:locationBarButtonItem];
    
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
    [self.findEventsButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
    [self.findEventsButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.navigationItem setTitle:NSLocalizedString(@"Find Shoots", @"")];
    
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFollowing == NO && isCameraCrew == NO"];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 30;
    NSError *error = nil;
    
    NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error == nil && results != nil) {
        self.shootArray = [NSMutableArray arrayWithArray:results];
    } else {
        self.shootArray = [NSMutableArray array];
    }
    
    // Footer
    // Hide footer for load more
    [self.loadMoreLabel setText:NSLocalizedString(@"Create More!", @"")];
    [self.loadMoreButton setEnabled:NO];
    [self.eventsTableView setTableFooterView:self.findEventsFooterView];
    
    // Set the background for any states you plan to use
    [self.createShootButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.createShootButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
    // No Events button
    [self.noEventsFoundCreateShootButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.noEventsFoundCreateShootButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
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
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)locationButtonAction:(id)sender {
    // Resign first responder if up
    [self.eventSearchTextField resignFirstResponder];
    
    // Clear text field
    [self.eventSearchTextField setText:@""];
    
    // Fire off request for events near user
    [self findEventsWithLocation:YES];
}

- (IBAction)findYourEventButtonAction:(id)sender {
    [self.eventSearchTextField resignFirstResponder];
    [self findEventsWithLocation:NO];
}

- (IBAction)createShootButtonAction:(id)sender {
    CreateEventViewController *viewController = [[CreateEventViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)loadMoreButtonAction:(id)sender {
    // Adding a check since we don't hide the button
    if ([self.shootPaginator isLoaded] && [self.shootPaginator hasNextPage]) {
        // Load next page, disable button until call complete
        [self.loadMoreButton setEnabled:NO];
        [self.loadMoreLabel setText:NSLocalizedString(@"Loading...", @"")];
        [self.activityIndicatorView startAnimating];
        [self.shootPaginator loadNextPage];
    }
}

#pragma mark - Network Calls

- (void)findEventsWithLocation:(BOOL)usingLocation {
    NSString *path = [NSString stringWithFormat:@"mission?page=:currentPage"];
    
    // Check if we have search text
    if (self.eventSearchTextField.text != nil && ![self.eventSearchTextField.text isEqualToString:@""]) {
        NSString *unescapedString = self.eventSearchTextField.text;
        NSString *escapedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                        NULL,
                                                                                                        (__bridge CFStringRef) unescapedString,
                                                                                                        NULL,
                                                                                                        CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                                        kCFStringEncodingUTF8));
        
        path = [path stringByAppendingFormat:@"&terms=%@", escapedString];
    }
    
    // Location
    if (usingLocation) {
        CLLocationCoordinate2D coordinate = [[SPLocationManager sharedInstance] currentLocation].coordinate;
        // Build Coords String
        NSString *lonString = [NSString stringWithFormat:@"%f", coordinate.longitude];
        NSString *latString = [NSString stringWithFormat:@"%f", coordinate.latitude];
        
        path = [path stringByAppendingFormat:@"&lat=%@&lon=%@", latString, lonString];
        
        [self.eventSearchTextField setPlaceholder:NSLocalizedString(@"Near Current Location", @"")];
    } else {
        [self.eventSearchTextField setPlaceholder:NSLocalizedString(@"Enter event code or search", @"")];
    }
    
    
    // Completion Blocks
    void (^findEventsSuccessBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
    void (^findEventsFailureBlock)(RKPaginator *paginator, NSError *error);
    
    findEventsSuccessBlock = ^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        // Re-enable Load More button
        [self.loadMoreButton setEnabled:YES];
        
        if (page == 1) {
            // New list
            self.shootArray = [NSMutableArray arrayWithArray:objects];
        } else {
            // Add objects to list
            [self.shootArray addObjectsFromArray:objects];
        }
        
        // Show correct view depending on video count
        if ([self.shootArray count] == 0) {
            [self.noEventsFoundView setHidden:NO];
            [self.eventsTableView setHidden:YES];
        } else {
            [self.noEventsFoundView setHidden:YES];
            [self.eventsTableView setHidden:NO];
        }
        
        // Save row height data
        NSError *error = nil;
        if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        // Reset load more view
        [self.loadMoreLabel setText:NSLocalizedString(@"Load More", @"")];
        [self.activityIndicatorView stopAnimating];
        
        // Check if we can load more
        if ([paginator hasNextPage]) {
            // Set footer for load more
            [self.loadMoreLabel setText:NSLocalizedString(@"Load More", @"")];
            [self.loadMoreButton setEnabled:YES];
        } else {
            // Hide footer for load more
            [self.loadMoreLabel setText:NSLocalizedString(@"Create More!", @"")];
            [self.loadMoreButton setEnabled:NO];
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventsTableView reloadData];
    };
    
    findEventsFailureBlock = ^(RKPaginator *paginator, NSError *error) {
        // Re-enable Load More button
        [self.loadMoreButton setEnabled:YES];
        
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
    };
    
    // Load the object model via RestKit
    self.shootPaginator = [[RKObjectManager sharedManager] paginatorWithPathPattern:path];
    [self.shootPaginator setCompletionBlockWithSuccess:findEventsSuccessBlock failure:findEventsFailureBlock];
    [self.shootPaginator loadPage:1];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    Mission *mission = [self.shootArray objectAtIndex:indexPath.row];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d. MMMM YYYY"];
    NSString *startEventTimeString = [dateFormatter stringFromDate:[mission startDatetime]];
    
    NSString *detailString = [NSString stringWithFormat:@"%@ %@", [mission venue].city, startEventTimeString];
    
    FindEventCell *findEventCell = (FindEventCell *)cell;
    [findEventCell.locationLabel setText:[mission title]];
    [findEventCell.detailLabel setText:detailString];
    [findEventCell setTag:indexPath.row];
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    return kFindEventCellRowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [self.shootArray count];
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
        
        [findEventCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Mission *mission = [self.shootArray objectAtIndex:indexPath.row];
    
    // Load Event View Controller
    EventViewController *viewController = [[EventViewController alloc] initWithMission:mission];
    
    SPNavigationController *navController = [[SPNavigationController alloc] initWithRootViewController:viewController];
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        
        CGRect frame = appDelegate.slidingViewController.topViewController.view.frame;
        appDelegate.slidingViewController.topViewController = navController;
        appDelegate.slidingViewController.topViewController.view.frame = frame;
        [appDelegate.slidingViewController resetTopView];
    }];
}

#pragma mark - UITextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.eventSearchTextField setPlaceholder:NSLocalizedString(@"Enter event code or search", @"")];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.eventSearchTextField) {
        [self findEventsWithLocation:NO];
    }
    
    return YES;
}

@end
