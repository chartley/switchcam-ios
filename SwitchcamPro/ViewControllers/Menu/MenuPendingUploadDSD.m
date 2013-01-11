//
//  MenuPendingUploadDSD.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/16/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UploadVideoViewController.h"
#import "MenuPendingUploadDSD.h"
#import "UserVideo.h"
#import "MenuViewController.h"

@interface MenuPendingUploadDSD () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end


@implementation MenuPendingUploadDSD

- (id)init {
    if (self = [super init]) {
        [self refreshUploads];
    }
    return self;
}

#pragma mark - Helper Methods

- (void)refreshUploads {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserVideo"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"recordStart" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isUploaded == NO"];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[descriptor];
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

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    UserVideo *recording = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    PendingUploadCell *pendingUploadCell = (PendingUploadCell*)cell;
    
    if (indexPath.row == 0) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
        
        // Set the pending uploads
        pendingUploadCell.pendingUploadCountLabel.text = [NSString stringWithFormat:@"%d", [sectionInfo numberOfObjects]];

    }
    
    // Save row
    [pendingUploadCell setTag:indexPath.row];
    
    // Set Delegate
    [pendingUploadCell setDelegate:self];
    
    // Load thumbnail image
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[recording thumbnailLocalURL]];
    
    // Set Thumbnail
    [pendingUploadCell.videoThumbnailImageView setImage:thumbnailImage];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a"];
    NSString *startRecordingTimeString = [dateFormatter stringFromDate:[recording recordStart]];
    
    [pendingUploadCell.pendingUploadTimeLabel setText:startRecordingTimeString];
    
    // Size to fit labels and set their origins
    [pendingUploadCell.pendingUploadTimeLabel sizeToFit];
    [pendingUploadCell.pendingUploadLengthLabel setFrame:CGRectMake(pendingUploadCell.pendingUploadTimeLabel.frame.origin.x + pendingUploadCell.pendingUploadTimeLabel.frame.size.width + kBufferBetweenThumbnailLabels, pendingUploadCell.pendingUploadLengthLabel.frame.origin.y, pendingUploadCell.pendingUploadLengthLabel.frame.size.width, pendingUploadCell.pendingUploadLengthLabel.frame.size.height)];
    
    [pendingUploadCell.pendingUploadLengthLabel sizeToFit];
    
}

#pragma mark UITableView DataSource / Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = nil;
    
    if (indexPath.row == 0) {
        identifier = kPendingUploadCellTopIdentifier;
    } else {
        identifier = kPendingUploadCellIdentifier;
    }
    
    PendingUploadCell *cell = (PendingUploadCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        NSArray *nibArray = nil;
        if (indexPath.row == 0) {
            nibArray = [[NSBundle mainBundle] loadNibNamed:@"PendingUploadCellTop" owner:self options:nil];
        } else {
            nibArray = [[NSBundle mainBundle] loadNibNamed:@"PendingUploadCell" owner:self options:nil];
        }
        
        cell = [nibArray objectAtIndex:0];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    if (indexPath.row == 0) {
        return kPendingUploadCellTopRowHeight;
    } else {
        return kPendingUploadCellRowHeight;
    }
}

#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeDelete:
            [self.menuViewController.pendingUploadTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            [[self.menuViewController pendingUploadTableView] reloadData];
            break;
    }
}

#pragma mark - PendingUploadCellDelegate

- (void)previewButtonPressed:(PendingUploadCell*)pendingUploadCell {
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *recording = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSURL *previewRecordingURL = [NSURL URLWithString:[recording localVideoAssetURL]];
    
    // Preview
    MPMoviePlayerViewController *viewController = [[MPMoviePlayerViewController alloc] initWithContentURL: previewRecordingURL];
    [self.menuViewController presentModalViewController:viewController animated:YES];
}

- (void)uploadButtonPressed:(PendingUploadCell*)pendingUploadCell {
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *userVideo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Upload
    UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
    [viewController setUserVideoToUpload:userVideo];
    [self.menuViewController presentModalViewController:viewController animated:YES];
    
    // Reset Top view
    [self.menuViewController.slidingViewController resetTopView];
}

- (void)deleteButtonPressed:(PendingUploadCell*)pendingUploadCell {
    NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    int row = [pendingUploadCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    UserVideo *recording = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [context deleteObject:recording];
    [context processPendingChanges];
    
    // This delete should trigger the results controller in a change and delete automagically
    NSError *error = nil;
    if (![context saveToPersistentStore:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

@end
