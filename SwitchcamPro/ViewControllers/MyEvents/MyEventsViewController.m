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

@interface MyEventsViewController () <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

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
    
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    [self.fetchedResultsController performFetch:&error];
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

#pragma mark - Network Calls

- (void)getMyEvents {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"true", @"followed_or_camera_crew_only", nil];
    
    // Load the object model via RestKit
    [[RKObjectManager sharedManager] getObjectsAtPath:@"mission/" parameters:parameters success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        // Show correct view depending on result count
        if ([[mappingResult array] count] == 0) {
            [self.noEventsFoundView setHidden:NO];
            [self.myEventsTableView setHidden:YES];
        } else {
            [self.noEventsFoundView setHidden:YES];
            [self.myEventsTableView setHidden:NO];
        }
        
        // Mark these missions as following or camera crew
        for (Mission *mission in [mappingResult array]) {
            mission.isFollowing = [NSNumber numberWithBool:YES];
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.myEventsTableView reloadData];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Load failed with error: %@", error);
        //TODO Error message
    }];
}

#pragma mark - RKDelegate
/*
- (void)objectLoader:(RKObjectLoader*)loader willMapData:(id)mappableData {
    // Get the paging data here
    
    NSString *total = [mappableData objectForKey:@"total"];
    NSString *itemsPerPage = [mappableData objectForKey:@"items_per_page"];
    NSString *currentPage = [mappableData objectForKey:@"current_page"];
}
 */

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    Mission *mission
    = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d. MMMM YYYY"];
    NSString *startEventTimeString = [dateFormatter stringFromDate:[mission startDatetime]];

    MyEventCell *myEventCell = (MyEventCell *)cell;
    
    
    [myEventCell.eventNameLabel setText:[mission title]];
    [myEventCell.eventLocationLabel setText:@"Magik"];
    [myEventCell.eventDateLabel setText:startEventTimeString];
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    return kMyEventCellRowHeight;
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMyEventCellIdentifier];
    
    if (cell == nil) {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"MyEventCell" owner:self options:nil];
        cell = [nibArray objectAtIndex:0];
        
        // Set Custom Font
        MyEventCell *myEventCell = (MyEventCell *)cell;
        [myEventCell.eventNameLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:18]];
        [myEventCell.eventLocationLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:16]];
        [myEventCell.eventDateLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:14]];
        
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
    Mission *mission = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    EventViewController *viewController = [[EventViewController alloc] initWithMission:mission];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.myEventsTableView reloadData];
}

#pragma mark - Observer Methods

- (void)stateChangedFromNotification {
    // Notification told us we have an open connection
    [self getMyEvents];
}

@end
