//
//  EventVideosViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EventVideosViewController.h"
#import "ECSlidingViewController.h"
#import "UploadVideoViewController.h"
#import "AppDelegate.h"
#import "Mission.h"
#import "UserVideo.h"
#import "Reachability.h"
#import "SPConstants.h"


@interface EventVideosViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) RKPaginator *videoPaginator;
@property (nonatomic, strong) NSMutableArray *videoArray;

@end

@implementation EventVideosViewController 

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
    self.videoArray = [NSMutableArray array];
    [self.eventVideosTableView setTableFooterView:[[UIView alloc] init]];
    
    // Set Fonts / Colors
    [self.noVideosFoundHeaderLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.noVideosFoundHeaderLabel setTextColor:[UIColor whiteColor]];
    [self.noVideosFoundHeaderLabel setShadowColor:[UIColor blackColor]];
    [self.noVideosFoundHeaderLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.noVideosFoundDetailLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.noVideosFoundDetailLabel setTextColor:[UIColor whiteColor]];
    [self.noVideosFoundDetailLabel setShadowColor:[UIColor blackColor]];
    [self.noVideosFoundDetailLabel setShadowOffset:CGSizeMake(0, -1)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshFeed];
}

#pragma mark - Network Calls

- (void)getEventVideos {
    NSString *path = [NSString stringWithFormat:@"uservideo?page=:currentPage&mission_id=%@", [self.selectedMission.missionId stringValue]];
    
    // Completion Blocks
    void (^getVideosSuccessBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
    void (^getVideosFailureBlock)(RKPaginator *paginator, NSError *error);
    
    getVideosSuccessBlock = ^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        // Re-enable Load More button
        [self.loadMoreButton setEnabled:YES];
        
        // Mark the mission id
        for (UserVideo *userVideo in objects) {
            if (userVideo.mission == nil) {
                userVideo.mission = self.selectedMission;
            }
        }
        
        // Add objects to list
        [self.videoArray addObjectsFromArray:objects];
        
        // Show correct view depending on video count
        if ([self.videoArray count] == 0) {
            [self.noVideosFoundView setHidden:NO];
            [self.eventVideosTableView setHidden:YES];
        } else {
            [self.noVideosFoundView setHidden:YES];
            [self.eventVideosTableView setHidden:NO];
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
            [self.eventVideosTableView setTableFooterView:self.loadMoreView];
        } else {
            // Hide footer for load more
            [self.eventVideosTableView setTableFooterView:nil];
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventVideosTableView reloadData];
    };
    
    getVideosFailureBlock = ^(RKPaginator *paginator, NSError *error) {
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
    self.videoPaginator = [[RKObjectManager sharedManager] paginatorWithPathPattern:path];
    [self.videoPaginator setCompletionBlockWithSuccess:getVideosSuccessBlock failure:getVideosFailureBlock];
    [self.videoPaginator loadPage:1];
}

#pragma mark - IBActions

- (IBAction)loadMoreButtonAction:(id)sender {
    // Load next page, disable button until call complete
    [self.loadMoreButton setEnabled:NO];
    [self.loadMoreLabel setText:NSLocalizedString(@"Loading...", @"")];
    [self.activityIndicatorView startAnimating];
    [self.videoPaginator loadNextPage];
}

#pragma mark - Helper Methods

- (void)refreshFeed {
    NSMutableArray *refreshArray = [NSMutableArray array];
    
    // Grab any pending uploads first so they are at the top
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserVideo"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"recordStart" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mission == %@ && state < 10", self.selectedMission];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 10;
    
    NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSError *error = nil;
    NSArray *pendingUploadResults = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error == nil && pendingUploadResults != nil) {
        [refreshArray addObjectsFromArray:pendingUploadResults];
    }
    
    // Set Array
    self.videoArray = refreshArray;
    
    // Show any new pending videos right away
    [self.eventVideosTableView reloadData];
    
    [self getEventVideos];
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    UserVideo *userVideo = [self.videoArray objectAtIndex:indexPath.row];
    
    PendingUploadCell *pendingUploadCell = (PendingUploadCell*)cell;
    
    if (indexPath.row == 0) {
        NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"UserVideo" inManagedObjectContext:managedObjectContext]];
        
        [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"state < 10 && localVideoAssetURL != nil && mission == %@", self.selectedMission];
        [request setPredicate:predicate];
        
        NSError *err;
        NSUInteger count = [managedObjectContext countForFetchRequest:request error:&err];
        if(count == NSNotFound) {
            //Handle error
        }
        
        // Set the pending uploads
        if (count == 0) {
            [pendingUploadCell.pendingUploadCountBadge setHidden:YES];
        } else {
            [pendingUploadCell.pendingUploadCountBadge setHidden:NO];
            [pendingUploadCell.pendingUploadCountBadge setText:[NSString stringWithFormat:@"%d", count]];
        }
        
        request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"UserVideo" inManagedObjectContext:managedObjectContext]];
        
        predicate = [NSPredicate predicateWithFormat:@"uploadedBy.userId == %@ && mission == %@", [[NSUserDefaults standardUserDefaults] stringForKey:kSPUserIdKey], self.selectedMission];
        [request setPredicate:predicate];
        
        [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
        count = [managedObjectContext countForFetchRequest:request error:&err];
        if(count == NSNotFound) {
            //Handle error
        }
        
        // Set the your videos
        pendingUploadCell.yourVideosCountLabel.text = [NSString stringWithFormat:@"%d", count];
    }
    
    // Save row
    [pendingUploadCell setTag:indexPath.row];
    
    // Set Delegate
    [pendingUploadCell setDelegate:self];
    
    // Load thumbnail image
    UIImage *thumbnailImage = nil;
    
    if ([userVideo thumbnailSDURL] != nil) {
        // Set Thumbnail
        [pendingUploadCell.videoThumbnailImageView setImageWithURL:[NSURL URLWithString:[userVideo thumbnailSDURL]]];
    } else {
        thumbnailImage = [UIImage imageWithContentsOfFile:[userVideo thumbnailLocalURL]];
        
        // Set Thumbnail
        [pendingUploadCell.videoThumbnailImageView setImage:thumbnailImage];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a"];
    NSString *startRecordingTimeString = [dateFormatter stringFromDate:[userVideo recordStart]];
    
    [pendingUploadCell.pendingUploadTimeLabel setText:startRecordingTimeString];
    
    // Size to fit labels and set their origins
    [pendingUploadCell.pendingUploadTimeLabel sizeToFit];
    [pendingUploadCell.pendingUploadLengthLabel setFrame:CGRectMake(pendingUploadCell.pendingUploadTimeLabel.frame.origin.x + pendingUploadCell.pendingUploadTimeLabel.frame.size.width + kBufferBetweenThumbnailLabels, pendingUploadCell.pendingUploadLengthLabel.frame.origin.y, pendingUploadCell.pendingUploadLengthLabel.frame.size.width, pendingUploadCell.pendingUploadLengthLabel.frame.size.height)];
    
    // Setup Length String
    int durationSeconds = [[userVideo durationSeconds] intValue];
    int seconds = (durationSeconds) % 60;
    int minutes = (durationSeconds - seconds) / 60;
    NSString *durationString = [NSString stringWithFormat:@"%d:%.2d", minutes, seconds];
    
    [pendingUploadCell.pendingUploadLengthLabel setText:durationString];
    [pendingUploadCell.pendingUploadLengthLabel sizeToFit];
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    UserVideo *userVideo = [self.videoArray objectAtIndex:indexPath.row];

    if (indexPath.row == 0) {
        if ([[userVideo state] intValue] > 10) {
            return kHostedEventVideoCellTopRowHeight;
        } else {
            return kPendingUploadCellEventVideoTopRowHeight;
        }
        
    } else {
        if ([[userVideo state] intValue] > 10) {
            return kHostedEventVideoCellRowHeight;
        } else {
            return kPendingUploadCellEventVideoRowHeight;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [self.videoArray count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserVideo *userVideo = [self.videoArray objectAtIndex:indexPath.row];
    
    NSString *identifier = nil;
    
    if (indexPath.row == 0) {
        if ([[userVideo state] intValue] > 10) {
            identifier = kHostedEventVideoTopCellIdentifier;
        } else {
            identifier = kPendingUploadCellEventVideoTopIdentifier;
        }
    } else {
        if ([[userVideo state] intValue] > 10) {
            identifier = kHostedEventVideoCellIdentifier;
        } else {
            identifier = kPendingUploadCellEventVideoIdentifier;
        }
    }
    
    PendingUploadCell *cell = (PendingUploadCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        NSArray *nibArray = nil;
        if (indexPath.row == 0) {
            if ([[userVideo state] intValue] > 10) {
                nibArray = [[NSBundle mainBundle] loadNibNamed:@"HostedEventVideoTopCell" owner:self options:nil];
            } else {
                nibArray = [[NSBundle mainBundle] loadNibNamed:@"PendingUploadCellEventVideoTop" owner:self options:nil];
            }
        } else {
            if ([[userVideo state] intValue] > 10) {
                nibArray = [[NSBundle mainBundle] loadNibNamed:@"HostedEventVideoCell" owner:self options:nil];
            } else {
                nibArray = [[NSBundle mainBundle] loadNibNamed:@"PendingUploadCellEventVideo" owner:self options:nil];
            }
        }
        
        cell = [nibArray objectAtIndex:0];
        
        [cell.yourVideosLabel sizeToFit];
        [cell.yourVideosCountLabel setFrame:CGRectMake(cell.yourVideosLabel.frame.origin.x + cell.yourVideosLabel.frame.size.width + 3, cell.yourVideosCountLabel.frame.origin.y, cell.yourVideosCountLabel.frame.size.width, cell.yourVideosCountLabel.frame.size.height)];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - PendingUploadCellDelegate

- (void)previewButtonPressed:(PendingUploadCell*)pendingUploadCell {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *userVideo = [self.videoArray objectAtIndex:indexPath.row];
    
    NSURL *previewRecordingURL = nil;
    if ([userVideo localVideoAssetURL] != nil) {
        //TODO Verify asset url is good 
        previewRecordingURL = [NSURL URLWithString:[userVideo localVideoAssetURL]];
    } else {
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        
        NetworkStatus status = [reachability currentReachabilityStatus];
        
        if(status == NotReachable) {
            // No internet
            // Error
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alertView show];
            return;
        } else if (status == ReachableViaWiFi) {
            // WiFi
            previewRecordingURL = [NSURL URLWithString:[userVideo videoHDURL]];
        } else if (status == ReachableViaWWAN) {
            // 3G
            previewRecordingURL = [NSURL URLWithString:[userVideo videoSDURL]];
        }
    }
    
    // Preview
    MPMoviePlayerViewController *viewController = [[MPMoviePlayerViewController alloc] initWithContentURL: previewRecordingURL];
    [appDelegate.slidingViewController presentViewController:viewController animated:YES completion:nil];
}

- (void)uploadButtonPressed:(PendingUploadCell*)pendingUploadCell {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *userVideo = [self.videoArray objectAtIndex:indexPath.row];
    
    // Upload
    UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
    [viewController setUserVideoToUpload:userVideo];
    [appDelegate.slidingViewController presentViewController:viewController animated:YES completion:nil];
    
    // Reset Top view
    [appDelegate.slidingViewController resetTopView];
}

- (void)deleteButtonPressed:(PendingUploadCell*)pendingUploadCell {
    NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *userVideo = [self.videoArray objectAtIndex:indexPath.row];
    [self.videoArray removeObject:userVideo];
    [context deleteObject:userVideo];
    [context processPendingChanges];
    
    // This delete should trigger the results controller in a change and delete automagically
    NSError *error = nil;
    if (![context saveToPersistentStore:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    [self.eventVideosTableView reloadData];
}

@end
