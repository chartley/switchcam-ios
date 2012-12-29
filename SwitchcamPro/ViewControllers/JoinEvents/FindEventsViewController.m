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
#import "MenuViewController.h"
#import "FindEventCell.h"
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
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
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
    
    [self.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    [self.titleLabel setShadowColor:[UIColor blackColor]];
    [self.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
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
    
    [self findEvents];
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
    // Fire off request for events near user
    //TODO
}

- (IBAction)findYourEventButtonAction:(id)sender {
    [self findEvents];
}

#pragma mark - Network Calls

- (void)findEvents {
    // Load the object model via RestKit
    [[RKObjectManager sharedManager] getObjectsAtPath:@"mission/" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
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
        //TODO Error message
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
        
        [findEventCell.joinButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:18]];
        
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

@end
