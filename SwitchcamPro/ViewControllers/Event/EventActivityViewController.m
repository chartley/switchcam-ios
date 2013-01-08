//
//  EventActivityViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <QuartzCore/QuartzCore.h>
#import "EventActivityViewController.h"
#import "ActivityVideoCell.h"
#import "ActivityPhotoCell.h"
#import "ActivityNoteCell.h"
#import "ActivityActionCell.h"
#import "Mission.h"
#import "Activity.h"
#import "User.h"

@interface EventActivityViewController () <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation EventActivityViewController

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
    
    [self.eventActivityTableView setTableFooterView:[[UIView alloc] init]];
    
    // Load up any cached events
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Activity"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
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
    
    [self getActivity];
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

- (void)getActivity {
    NSMutableDictionary *parameters = nil;
    NSString *path = [NSString stringWithFormat:@"mission/%@/activity/", [self.selectedMission.missionId stringValue]];
    
    // Load the object model via RestKit
    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:parameters success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        // Set the row height for each activity
        for (Activity *activity in [mappingResult array]) {
            if ([activity.activityType isEqualToString:@"note"]) {
                CGSize labelSize = [activity.text sizeWithFont:[UIFont fontWithName:@"" size:17.0] constrainedToSize:CGSizeMake(264, 600) lineBreakMode:NSLineBreakByWordWrapping];
                int rowHeight = labelSize.height + 65 + 20; // Label size, fixed bottom, fixed top
                activity.rowHeight = [NSNumber numberWithInt:rowHeight];
            } else if ([activity.activityType isEqualToString:@"action"]) {
                if ([activity.targetContentType isEqualToString:@"director.mission"]) {
                    if (activity.actionObjectContentType == nil || [activity.actionObjectContentType isEqualToString:@""]) {
                        activity.rowHeight = [NSNumber numberWithInt:kActivityActionCellRowHeight];
                    } else if ([activity.actionObjectContentType isEqualToString:@"video"]) {
                        activity.rowHeight = [NSNumber numberWithInt:kActivityVideoCellRowHeight];
                    } else if ([activity.actionObjectContentType isEqualToString:@"photo"]) {
                        activity.rowHeight = [NSNumber numberWithInt:kActivityPhotoCellRowHeight];
                    }
                }
            }
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventActivityTableView reloadData];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
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
    }];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    Activity *activity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    ActivityCell *activityCell = (ActivityCell*)cell;
    
    if ([activity.activityType isEqualToString:@"note"]) {
        ActivityNoteCell *activityNoteCell = (ActivityNoteCell *)cell;
        [activityNoteCell.verbLabel setText:NSLocalizedString(@"added a note", @"")];
        
    } else if ([activity.activityType isEqualToString:@"action"]) {
        if ([activity.targetContentType isEqualToString:@"director.mission"]) {
            if (activity.actionObjectContentType == nil || [activity.actionObjectContentType isEqualToString:@""]) {
                
            } else if ([activity.actionObjectContentType isEqualToString:@"video"]) {
                
            } else if ([activity.actionObjectContentType isEqualToString:@"photo"]) {
                
            }
        }
        
        [activityCell.verbLabel setText:activity.verb];
    }
    
    
    // Set Contributer
    [activityCell.contributorLabel setText:activity.person.name];

    if ([activity.likeCount intValue] > 0) {
        [activityCell.likeCountLabel setHidden:NO];
        [activityCell.likeCountLabel setText:[NSString stringWithFormat:@"%d", [activity.likeCount intValue]]];
    } else {
        [activityCell.likeCountLabel setHidden:YES];
    }
    
    if ([activity.commentCount intValue] > 0) {
        [activityCell.commentCountLabel setHidden:NO];
        [activityCell.commentCountLabel setText:[NSString stringWithFormat:@"%d", [activity.commentCount intValue]]];
    } else {
        [activityCell.commentCountLabel setHidden:YES];
    }
    
    [activityCell.contributorImageView setImageWithURL:[NSURL URLWithString:[activity.person pictureURL]] placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
    
    // Set delegate and tag
    [activityCell setTag:indexPath.row];
    [activityCell setDelegate:self];
    
    // Adjust verb / time layout
    [activityCell.verbLabel sizeToFit];
    [activityCell.timeLabel sizeToFit];
    
    int timeLabelOffset = activityCell.verbLabel.frame.size.width + activityCell.verbLabel.frame.origin.x + 5;
    int timeLabelWidth = 220 - timeLabelOffset;  // Like Button Origin, set as number here to offset button frame buffer
    [activityCell.timeLabel setFrame:CGRectMake(timeLabelOffset, activityCell.timeLabel.frame.origin.y, timeLabelWidth, activityCell.timeLabel.frame.size.height)];
}

#pragma mark - UITableViewDataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Activity *activity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    return [activity.rowHeight floatValue];
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
    Activity *activity = [self.fetchedResultsController objectAtIndexPath:indexPath];

    UITableViewCell *cell = nil;
    
    if ([activity.activityType isEqualToString:@"note"]) {
        cell = [tableView dequeueReusableCellWithIdentifier:kActivityNoteCellIdentifier];
    } else if ([activity.activityType isEqualToString:@"action"]) {
        if ([activity.targetContentType isEqualToString:@"director.mission"]) {
            if (activity.actionObjectContentType == nil || [activity.actionObjectContentType isEqualToString:@""]) {
                cell = [tableView dequeueReusableCellWithIdentifier:kActivityActionCellIdentifier];
            } else if ([activity.actionObjectContentType isEqualToString:@"video"]) {
                cell = [tableView dequeueReusableCellWithIdentifier:kActivityVideoCellIdentifier];
            } else if ([activity.actionObjectContentType isEqualToString:@"photo"]) {
                cell = [tableView dequeueReusableCellWithIdentifier:kActivityPhotoCellIdentifier];
            }
        }
    }
    
    if (cell == nil) {
        if ([activity.activityType isEqualToString:@"note"]) {
            NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityNoteCell" owner:self options:nil];
            cell = [nibArray objectAtIndex:0];
            
        } else if ([activity.activityType isEqualToString:@"action"]) {
            if ([activity.targetContentType isEqualToString:@"director.mission"]) {
                if (activity.actionObjectContentType == nil || [activity.actionObjectContentType isEqualToString:@""]) {
                    NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityActionCell" owner:self options:nil];
                    cell = [nibArray objectAtIndex:0];
                } else if ([activity.actionObjectContentType isEqualToString:@"video"]) {
                    NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityVideoCell" owner:self options:nil];
                    cell = [nibArray objectAtIndex:0];
                } else if ([activity.actionObjectContentType isEqualToString:@"photo"]) {
                    NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityPhotoCell" owner:self options:nil];
                    cell = [nibArray objectAtIndex:0];
                }
            }
        }
        
        // Set Custom Font
        ActivityCell *activityCell = (ActivityCell *)cell;
        [activityCell.contributorLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
        [activityCell.verbLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        [activityCell.timeLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        [activityCell.likeCountLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        [activityCell.commentCountLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        
        [activityCell.contributorLabel setTextColor:[UIColor whiteColor]];
        [activityCell.verbLabel setTextColor:[UIColor whiteColor]];
        [activityCell.timeLabel setTextColor:[UIColor whiteColor]];
        [activityCell.likeCountLabel setTextColor:[UIColor whiteColor]];
        [activityCell.commentCountLabel setTextColor:[UIColor whiteColor]];
        
        [activityCell.contributorLabel setShadowColor:[UIColor blackColor]];
        [activityCell.verbLabel setShadowColor:[UIColor blackColor]];
        [activityCell.timeLabel setShadowColor:[UIColor blackColor]];
        [activityCell.likeCountLabel setShadowColor:[UIColor blackColor]];
        [activityCell.commentCountLabel setShadowColor:[UIColor blackColor]];
        
        
        [activityCell.contributorLabel setShadowOffset:CGSizeMake(0, 1)];
        [activityCell.verbLabel setShadowOffset:CGSizeMake(0, 1)];
        [activityCell.timeLabel setShadowOffset:CGSizeMake(0, 1)];
        [activityCell.likeCountLabel setShadowOffset:CGSizeMake(0, 1)];
        [activityCell.commentCountLabel setShadowOffset:CGSizeMake(0, 1)];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.eventActivityTableView reloadData];
}

#pragma mark - Activity Cell Delegate Methods

- (void)previewButtonPressed:(ActivityCell*)activityCell {
    
}

- (void)likeButtonPressed:(ActivityCell*)activityCell {
    
}

- (void)commentButtonPressed:(ActivityCell*)activityCell {
    
}

@end
