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
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "MyEventCell.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "SPConstants.h"
#import "Event.h"

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
    [self.myEventsTableView setTableFooterView:[[UIView alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged:) name:SCSessionStateChangedNotification object:nil];
    
    // Set debug logging level. Set to 'RKLogLevelTrace' to see JSON payload
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDatetime" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
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
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

#pragma mark - Network Calls

- (void)getMyEvents {
    // Load the object model via RestKit
    [[RKObjectManager sharedManager] getObjectsAtPath:@"mission/" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
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
    Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d. MMMM YYYY"];
    NSString *startEventTimeString = [dateFormatter stringFromDate:[event startDatetime]];

    MyEventCell *myEventCell = (MyEventCell *)cell;
    
    
    [myEventCell.eventNameLabel setText:[event title]];
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
}

#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.myEventsTableView reloadData];
}

#pragma mark - Observer Methods

- (void)stateChanged:(NSNotification*)notification {
    FBSession *session = (FBSession *) [notification object];
    
    switch (session.state) {
        case FBSessionStateOpen: {
            [self getMyEvents];
        }
            break;
        case FBSessionStateClosed: {
        }
            break;
        case FBSessionStateClosedLoginFailed: {
        }
            break;
        default:
            break;
    }
}

@end
