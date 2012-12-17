//
//  MenuPendingUploadDSD.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/16/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "MenuPendingUploadDSD.h"
#import "PendingUploadCell.h"
#import "Recording.h"
#import "MenuViewController.h"

#define kBufferBetweenThumbnailLabels 10

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
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Recording"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"recordStart" ascending:NO];
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isUploaded == NO"];
    //fetchRequest.predicate = predicate;
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
    Recording *recording = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    PendingUploadCell *pendingUploadCell = (PendingUploadCell*)cell;
    
    if (indexPath.row == 0) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
        
        // Set the pending uploads
        pendingUploadCell.pendingUploadCountLabel.text = [NSString stringWithFormat:@"%d", [sectionInfo numberOfObjects]];

    }
    // Load thumbnail image
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[recording thumbnailURL]];
    
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
        
        // Set Custom Font
        [cell.pendingUploadCountLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:18]];
        [cell.pendingUploadCountLabel setShadowColor:[UIColor blackColor]];
        [cell.pendingUploadCountLabel setShadowOffset:CGSizeMake(0, 1)];
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self.menuViewController pendingUploadTableView] reloadData];
}

@end
