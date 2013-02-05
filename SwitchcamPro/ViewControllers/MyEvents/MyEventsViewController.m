//
//  MyEventsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <QuartzCore/QuartzCore.h>
#import <FacebookSDK/FacebookSDK.h>
#import "MyEventsViewController.h"
#import "EventViewController.h"
#import "FindEventsViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "MyEventCell.h"
#import "AppDelegate.h"
#import "SPConstants.h"
#import "Mission.h"
#import "Artist.h"
#import "Venue.h"

@interface MyEventsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) RKPaginator *shootPaginator;
@property (nonatomic, strong) NSMutableArray *shootArray;

@end

@implementation MyEventsViewController

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
    
    // Add title
    [self.navigationItem setTitle:NSLocalizedString(@"My Events", @"")];
    
    [self.myEventsTableView setTableFooterView:[[UIView alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChangedFromNotification) name:SCAPINetworkRequestCanStartNotification object:nil];
    
    // Set Fonts / Colors
    [self.noEventsFoundHeaderLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.noEventsFoundHeaderLabel setTextColor:[UIColor whiteColor]];
    [self.noEventsFoundHeaderLabel setShadowColor:[UIColor blackColor]];
    [self.noEventsFoundHeaderLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.noEventsFoundDetailLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.noEventsFoundDetailLabel setTextColor:[UIColor whiteColor]];
    [self.noEventsFoundDetailLabel setShadowColor:[UIColor blackColor]];
    [self.noEventsFoundDetailLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // Set debug logging level. Set to 'RKLogLevelTrace' to see JSON payload
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Mission"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDatetime" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFollowing == YES || isCameraCrew == YES"];
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
    
    // Add Menu button
    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setFrame:CGRectMake(0, 0, 30, 30)];
    
    [menuButton setImage:[UIImage imageNamed:@"btn-sidemenu"] forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(menuButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    [self.navigationItem setLeftBarButtonItem:menuBarButtonItem];
    
    // Add Plus button
    UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [plusButton setFrame:CGRectMake(0, 0, 30, 30)];
    
    [plusButton setImage:[UIImage imageNamed:@"btn-add"] forState:UIControlStateNormal];
    [plusButton addTarget:self action:@selector(plusButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *plusBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:plusButton];
    [self.navigationItem setRightBarButtonItem:plusBarButtonItem];
    
    if ([FBSession.activeSession isOpen]) {
        [self getMyEvents];
    }
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)plusButtonAction:(id)sender {
    // Load Find Event View Controller
    FindEventsViewController *viewController = [[FindEventsViewController alloc] init];
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        
        CGRect frame = appDelegate.slidingViewController.topViewController.view.frame;
        appDelegate.slidingViewController.topViewController = viewController;
        appDelegate.slidingViewController.topViewController.view.frame = frame;
        [appDelegate.slidingViewController resetTopView];
    }];
}

- (IBAction)loadMoreButtonAction:(id)sender {
    // Load next page, disable button until call complete
    [self.loadMoreButton setEnabled:NO];
    [self.loadMoreLabel setText:NSLocalizedString(@"Loading...", @"")];
    [self.activityIndicatorView startAnimating];
    [self.shootPaginator loadNextPage];
}

#pragma mark - Network Calls

- (void)getMyEvents {
    NSString *path = [NSString stringWithFormat:@"mission?page=:currentPage&followed_or_camera_crew_only=true"];
    
    // Completion Blocks
    void (^getMyEventsSuccessBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
    void (^getMyEventsFailureBlock)(RKPaginator *paginator, NSError *error);
    
    getMyEventsSuccessBlock = ^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        // Re-enable Load More button
        [self.loadMoreButton setEnabled:YES];
        
        // Add objects to list
        [self.shootArray addObjectsFromArray:objects];
        
        // Show correct view depending on video count
        if ([self.shootArray count] == 0) {
            [self.noEventsFoundView setHidden:NO];
            [self.myEventsTableView setHidden:YES];
        } else {
            [self.noEventsFoundView setHidden:YES];
            [self.myEventsTableView setHidden:NO];
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
            [self.myEventsTableView setTableFooterView:self.loadMoreView];
        } else {
            // Hide footer for load more
            [self.myEventsTableView setTableFooterView:nil];
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.myEventsTableView reloadData];
    };
    
    getMyEventsFailureBlock = ^(RKPaginator *paginator, NSError *error) {
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
    [self.shootPaginator setCompletionBlockWithSuccess:getMyEventsSuccessBlock failure:getMyEventsFailureBlock];
    [self.shootPaginator loadPage:1];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    Mission *mission = [self.shootArray objectAtIndex:indexPath.row];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d. YYYY @ ha"];
    NSString *startEventTimeString = [dateFormatter stringFromDate:[mission startDatetime]];

    MyEventCell *myEventCell = (MyEventCell *)cell;
    
    NSString *locationString = [NSString stringWithFormat:@"%@, %@", [mission venue].venueName, [mission venue].city];
    
    [myEventCell.eventNameLabel setText:[mission artist].artistName];
    [myEventCell.eventLocationLabel setText:locationString];
    [myEventCell.eventDateLabel setText:startEventTimeString];
    if ([mission picURL] != nil) {
        [myEventCell.eventImageView setImageWithURL:[NSURL URLWithString:[mission picURL]]];
    }
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    return kMyEventCellRowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [self.shootArray count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMyEventCellIdentifier];
    
    if (cell == nil) {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"MyEventCell" owner:self options:nil];
        cell = [nibArray objectAtIndex:0];
        
        // Set Custom Font
        MyEventCell *myEventCell = (MyEventCell *)cell;
        [myEventCell.eventNameLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:22]];
        [myEventCell.eventLocationLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:14]];
        [myEventCell.eventDateLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:12]];
        
        [myEventCell.eventNameLabel setShadowColor:[UIColor blackColor]];
        [myEventCell.eventLocationLabel setShadowColor:[UIColor blackColor]];
        [myEventCell.eventDateLabel setShadowColor:[UIColor blackColor]];
        
        [myEventCell.eventNameLabel setShadowOffset:CGSizeMake(0, 1)];
        [myEventCell.eventLocationLabel setShadowOffset:CGSizeMake(0, 1)];
        [myEventCell.eventDateLabel setShadowOffset:CGSizeMake(0, 1)];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Mission *mission = [self.shootArray objectAtIndex:indexPath.row];
    
    EventViewController *viewController = [[EventViewController alloc] initWithMission:mission];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Observer Methods

- (void)stateChangedFromNotification {
    // Notification told us we have an open connection
    [self getMyEvents];
}

@end
