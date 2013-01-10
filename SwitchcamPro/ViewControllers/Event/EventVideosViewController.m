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


@interface EventVideosViewController () <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

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
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
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
    
    // Set debug logging level. Set to 'RKLogLevelTrace' to see JSON payload
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserVideo"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"recordStart" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mission == %@", self.selectedMission];
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
    
    [self getEventVideos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Network Calls

- (void)getEventVideos {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:[self.selectedMission missionId], @"mission_id", nil];
    
    // Load the object model via RestKit
    [[RKObjectManager sharedManager] getObjectsAtPath:@"uservideo/" parameters:parameters success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        
        // Show correct view depending on result count
        if ([[mappingResult array] count] == 0) {
            [self.noVideosFoundView setHidden:NO];
            [self.eventVideosTableView setHidden:YES];
        } else {
            [self.noVideosFoundView setHidden:YES];
            [self.eventVideosTableView setHidden:NO];
        }
        
        // Mark the mission id
        for (UserVideo *userVideo in [mappingResult array]) {
            if (userVideo.mission == nil) {
                userVideo.mission = self.selectedMission;
            }
            
            // Check state to see if we've uploaded
            if ([[userVideo state] intValue] > kUserVideoStateUSER_UPLOADING) {
                [userVideo setIsUploaded:[NSNumber numberWithBool:YES]];
            }
        }
        
        [context processPendingChanges];
        
        // This delete should trigger the results controller in a change and delete automagically
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventVideosTableView reloadData];
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
    UserVideo *userVideo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    PendingUploadCell *pendingUploadCell = (PendingUploadCell*)cell;
    
    if (indexPath.row == 0) {
        NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"UserVideo" inManagedObjectContext:managedObjectContext]];
        
        [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"state < 11 && localVideoAssetURL != nil"];
        [request setPredicate:predicate];
        
        NSError *err;
        NSUInteger count = [managedObjectContext countForFetchRequest:request error:&err];
        if(count == NSNotFound) {
            //Handle error
        }
        
        // Set the pending uploads
        pendingUploadCell.pendingUploadCountLabel.text = [NSString stringWithFormat:@"%d", count];
        
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
    
    [pendingUploadCell.pendingUploadLengthLabel sizeToFit];
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    if (indexPath.row == 0) {
        return kPendingUploadCellEventVideoTopRowHeight;
    } else {
        return kPendingUploadCellEventVideoRowHeight;
    }
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
    
    NSString *identifier = nil;
    
    if (indexPath.row == 0) {
        identifier = kPendingUploadCellEventVideoTopIdentifier;
    } else {
        identifier = kPendingUploadCellEventVideoIdentifier;
    }
    
    PendingUploadCell *cell = (PendingUploadCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        NSArray *nibArray = nil;
        if (indexPath.row == 0) {
            nibArray = [[NSBundle mainBundle] loadNibNamed:@"PendingUploadCellEventVideoTop" owner:self options:nil];
        } else {
            nibArray = [[NSBundle mainBundle] loadNibNamed:@"PendingUploadCellEventVideo" owner:self options:nil];
        }
        
        cell = [nibArray objectAtIndex:0];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.eventVideosTableView reloadData];
}

#pragma mark - PendingUploadCellDelegate

- (void)previewButtonPressed:(PendingUploadCell*)pendingUploadCell {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *recording = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSURL *previewRecordingURL = nil;
    if ([recording localVideoAssetURL] != nil) {
        previewRecordingURL = [NSURL URLWithString:[recording localVideoAssetURL]];
    } else {
        previewRecordingURL = [NSURL URLWithString:[recording localVideoAssetURL]];
    }
    
    // Preview
    MPMoviePlayerViewController *viewController = [[MPMoviePlayerViewController alloc] initWithContentURL: previewRecordingURL];
    [appDelegate.slidingViewController presentModalViewController:viewController animated:YES];
}

- (void)uploadButtonPressed:(PendingUploadCell*)pendingUploadCell {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *userVideo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Upload
    UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
    [viewController setUserVideoToUpload:userVideo];
    [appDelegate.slidingViewController presentModalViewController:viewController animated:YES];
    
    // Reset Top view
    [appDelegate.slidingViewController resetTopView];
}

- (void)deleteButtonPressed:(PendingUploadCell*)pendingUploadCell {
    NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].persistentStoreManagedObjectContext;
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *recording = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [context deleteObject:recording];
    [context processPendingChanges];
    
    // This delete should trigger the results controller in a change and delete automagically
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

@end
