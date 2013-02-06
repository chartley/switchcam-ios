//
//  EventPeopleViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <QuartzCore/QuartzCore.h>
#import "EventPeopleViewController.h"
#import "Mission.h"
#import "User.h"
#import "PeopleCell.h"

@interface EventPeopleViewController ()

@property (nonatomic, strong) RKPaginator *crewPaginator;
@property (nonatomic, strong) RKPaginator *followerPaginator;
@property (nonatomic, strong) NSMutableArray *peopleArray;

@end

@implementation EventPeopleViewController

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
    
    self.peopleArray = [NSMutableArray array];
    [self.eventPeopleTableView setTableFooterView:[[UIView alloc] init]];
    
    // Set Fonts / Colors
    [self.noPeopleFoundHeaderLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.noPeopleFoundHeaderLabel setTextColor:[UIColor whiteColor]];
    [self.noPeopleFoundHeaderLabel setShadowColor:[UIColor blackColor]];
    [self.noPeopleFoundHeaderLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.noPeopleFoundDetailLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.noPeopleFoundDetailLabel setTextColor:[UIColor whiteColor]];
    [self.noPeopleFoundDetailLabel setShadowColor:[UIColor blackColor]];
    [self.noPeopleFoundDetailLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // 20 px header for spacing
    [self.eventPeopleTableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)]];
    
    [self refreshFeed];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helper Methods

- (void)refreshFeed {
    // Get crew and followers
    NSMutableArray *refreshArray = [NSMutableArray arrayWithArray:[[self.selectedMission cameraCrew] allObjects]];
    [refreshArray addObjectsFromArray:[[self.selectedMission followers] allObjects]];
    
    // Set Array
    self.peopleArray = refreshArray;
    
    // Show any new pending videos right away
    [self.eventPeopleTableView reloadData];
    
    [self getEventCrewPeople];
}

#pragma mark - Network Calls

- (void)getEventCrewPeople {
    NSString *path = [NSString stringWithFormat:@"mission/%@/camera_crew?page=:currentPage", [self.selectedMission.missionId stringValue]];
    
    // Completion Blocks
    void (^getPeopleSuccessBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
    void (^getPeopleFailureBlock)(RKPaginator *paginator, NSError *error);
    
    getPeopleSuccessBlock = ^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        // Re-enable Load More button
        [self.loadMoreButton setEnabled:YES];
        
        // Mark the mission id
        for (User *user in objects) {
            if (user.attendedMission == nil) {
                [user addAttendedMissionObject:self.selectedMission];
            }
        }
        
        // Reset array in case people have somehow left the event
        if (page == 1) {
            self.peopleArray = [NSMutableArray arrayWithArray:objects];
        } else {
            // Add objects to list
            [self.peopleArray addObjectsFromArray:objects];
        }
        
        // Show correct view depending on video count
        if ([self.peopleArray count] == 0) {
            [self getEventFollowerPeople];
        } else {
            [self.noPeopleFoundView setHidden:YES];
            [self.eventPeopleTableView setHidden:NO];
        }
        
        // Save row height data
        NSError *error = nil;
        if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        // Reset load more view
        [self.loadMoreLabel setText:NSLocalizedString(@"Load More", @"")];
        [self.activityIndicatorView stopAnimating];
        
        // We haven't loaded followers, assume we can try to load more
        [self.eventPeopleTableView setTableFooterView:self.loadMoreView];
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventPeopleTableView reloadData];
    };
    
    getPeopleFailureBlock = ^(RKPaginator *paginator, NSError *error) {
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
    self.crewPaginator = [[RKObjectManager sharedManager] paginatorWithPathPattern:path];
    [self.crewPaginator setCompletionBlockWithSuccess:getPeopleSuccessBlock failure:getPeopleFailureBlock];
    [self.crewPaginator loadPage:1];
}

- (void)getEventFollowerPeople {
    NSString *path = [NSString stringWithFormat:@"mission/%@/follower?page=:currentPage", [self.selectedMission.missionId stringValue]];
    
    // Completion Blocks
    void (^getPeopleSuccessBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
    void (^getPeopleFailureBlock)(RKPaginator *paginator, NSError *error);
    
    getPeopleSuccessBlock = ^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        // Re-enable Load More button
        [self.loadMoreButton setEnabled:YES];
        
        // Mark the mission id
        for (User *user in objects) {
            if (user.attendedMission == nil) {
                [user addAttendedMissionObject:self.selectedMission];
            }
        }
        
        // Add objects to list
        [self.peopleArray addObjectsFromArray:objects];
        
        // Show correct view depending on video count
        if ([self.peopleArray count] == 0) {
            [self.noPeopleFoundView setHidden:NO];
            [self.eventPeopleTableView setHidden:YES];
        } else {
            [self.noPeopleFoundView setHidden:YES];
            [self.eventPeopleTableView setHidden:NO];
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
            [self.eventPeopleTableView setTableFooterView:self.loadMoreView];
        } else {
            // Hide footer for load more
            [self.eventPeopleTableView setTableFooterView:nil];
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventPeopleTableView reloadData];
    };
    
    getPeopleFailureBlock = ^(RKPaginator *paginator, NSError *error) {
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
    self.followerPaginator = [[RKObjectManager sharedManager] paginatorWithPathPattern:path];
    [self.followerPaginator setCompletionBlockWithSuccess:getPeopleSuccessBlock failure:getPeopleFailureBlock];
    [self.followerPaginator loadPage:1];
}

#pragma mark - IBActions

- (IBAction)loadMoreButtonAction:(id)sender {
    // Load next page, disable button until call complete
    [self.loadMoreButton setEnabled:NO];
    [self.loadMoreLabel setText:NSLocalizedString(@"Loading...", @"")];
    [self.activityIndicatorView startAnimating];
    if ([self.crewPaginator hasNextPage]) {
        [self.crewPaginator loadNextPage];
    } else {
        if (self.followerPaginator == nil) {
            [self getEventFollowerPeople];
        } else {
            [self.followerPaginator loadNextPage];
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {    
    PeopleCell *peopleCell = (PeopleCell*)cell;
    
    // Make sure we don't go past the end of the array
    int numberOfUsersInRow = 0;
    if (floor((float)[self.peopleArray count] / 5) == indexPath.row) {
        numberOfUsersInRow = ((indexPath.row * 5) + ([self.peopleArray count] % 5));
    } else {
        numberOfUsersInRow = ((indexPath.row * 5) + 5);
    }
    
    // Hide Images that aren't showing anything
    if ((numberOfUsersInRow % 5) != 0) {
        int actualNumberOfUsersInRow = (numberOfUsersInRow % 5);
        
        for (int i = 5; i > actualNumberOfUsersInRow; i--) {
            switch (i - 1) {
                case 0:
                    [peopleCell.person1ImageView setHidden:YES];
                    break;
                case 1:
                    [peopleCell.person2ImageView setHidden:YES];
                    break;
                case 2:
                    [peopleCell.person3ImageView setHidden:YES];
                    break;
                case 3:
                    [peopleCell.person4ImageView setHidden:YES];
                    break;
                case 4:
                    [peopleCell.person5ImageView setHidden:YES];
                    break;
                    
                default:
                    break;
            }
        }
    }
    
    for (int i = indexPath.row * 5; i < numberOfUsersInRow; i++) {
        User *user = [self.peopleArray objectAtIndex:i];
        NSURL *userImage = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", [user.userId stringValue]]];
        
        switch (i % 5) {
            case 0:
                [peopleCell.person1ImageView setImageWithURL:userImage placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
                [peopleCell.person1ImageView setHidden:NO];
                break;
            case 1:
                [peopleCell.person2ImageView setImageWithURL:userImage placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
                [peopleCell.person2ImageView setHidden:NO];
                break;
            case 2:
                [peopleCell.person3ImageView setImageWithURL:userImage placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
                [peopleCell.person3ImageView setHidden:NO];
                break;
            case 3:
                [peopleCell.person4ImageView setImageWithURL:userImage placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
                [peopleCell.person4ImageView setHidden:NO];
                break;
            case 4:
                [peopleCell.person5ImageView setImageWithURL:userImage placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
                [peopleCell.person5ImageView setHidden:NO];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    return kPeopleCellRowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    int numberOfRows = ceil((float)[self.peopleArray count]/5);
    return numberOfRows;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PeopleCell *cell = (PeopleCell *)[tableView dequeueReusableCellWithIdentifier:kPeopleCellIdentifier];
    
    if (cell == nil) {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"PeopleCell" owner:self options:nil];
        cell = [nibArray objectAtIndex:0];
        
        [cell.person1ImageView.layer setBorderColor:[UIColor blackColor].CGColor];
        [cell.person1ImageView.layer setBorderWidth:1.0f];
        [cell.person2ImageView.layer setBorderColor:[UIColor blackColor].CGColor];
        [cell.person2ImageView.layer setBorderWidth:1.0f];
        [cell.person3ImageView.layer setBorderColor:[UIColor blackColor].CGColor];
        [cell.person3ImageView.layer setBorderWidth:1.0f];
        [cell.person4ImageView.layer setBorderColor:[UIColor blackColor].CGColor];
        [cell.person4ImageView.layer setBorderWidth:1.0f];
        [cell.person5ImageView.layer setBorderColor:[UIColor blackColor].CGColor];
        [cell.person5ImageView.layer setBorderWidth:1.0f];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

@end
