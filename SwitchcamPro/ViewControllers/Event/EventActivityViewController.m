//
//  EventActivityViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EventActivityViewController.h"
#import "ECSlidingViewController.h"
#import "SPConstants.h"
#import "AppDelegate.h"
#import "ActivityVideoCell.h"
#import "ActivityPhotoCell.h"
#import "ActivityNoteCell.h"
#import "ActivityActionCell.h"
#import "ActivityCommentCell.h"
#import "ActivityPostCommentCell.h"
#import "Mission.h"
#import "Activity.h"
#import "User.h"
#import "UserVideo.h"
#import "Comment.h"

@interface EventActivityViewController () <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate> {
    int postCommentRow;
}
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation EventActivityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        postCommentRow = 0;
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
            if (activity.actionObjectContentTypeName == nil || [activity.actionObjectContentTypeName isEqualToString:@""]) {
                activity.rowHeight = [NSNumber numberWithInt:kActivityActionCellRowHeight];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.recordingsession"]) {
                activity.rowHeight = [NSNumber numberWithInt:kActivityVideoCellRowHeight];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionphoto"]) {
                activity.rowHeight = [NSNumber numberWithInt:kActivityPhotoCellRowHeight];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionnote"]) {
                CGSize labelSize = [activity.text sizeWithFont:[UIFont fontWithName:@"" size:17.0] constrainedToSize:CGSizeMake(264, 600) lineBreakMode:NSLineBreakByWordWrapping];
                int rowHeight = labelSize.height + 65 + 20; // Label size, fixed bottom, fixed top
                activity.rowHeight = [NSNumber numberWithInt:rowHeight];
            }
            
            for (Comment *comment in activity.latestComments) {
                CGSize labelSize = [activity.text sizeWithFont:[UIFont fontWithName:@"" size:17.0] constrainedToSize:CGSizeMake(264, 600) lineBreakMode:NSLineBreakByWordWrapping];
                int rowHeight = labelSize.height + 65 + 20; // Label size, fixed bottom, fixed top
                comment.rowHeight = [NSNumber numberWithInt:rowHeight];
            }
        }
        
        // Save row height data
        NSError *error = nil;
        if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
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

- (void)likeActivity:(Activity*)likedActivity {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^likeActivitySuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^likeActivityFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    likeActivitySuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
    };
    
    likeActivityFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    };
    
    // Setup Parameters
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:@"actstream.action" forKey:@"content_type"];
    [parameters setObject:likedActivity.activityId forKey:@"object_id"];
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"like/"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:likeActivitySuccessBlock failure:likeActivityFailureBlock];
    
    [operation start];
}

- (void)unlikeActivity:(Activity*)unlikedActivity {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^unlikeActivitySuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^unlikeActivityFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    unlikeActivitySuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
    };
    
    unlikeActivityFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    };
    
    // Setup Parameters
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:@"actstream.action" forKey:@"content_type"];
    [parameters setObject:unlikedActivity.activityId forKey:@"object_id"];
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"like/"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"DELETE" path:path parameters:parameters];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:unlikeActivitySuccessBlock failure:unlikeActivityFailureBlock];
    
    [operation start];
}

- (void)addComment:(NSString *)comment toActivity:(Activity *)selectedActivity {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^commentActivitySuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^commentActivityFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    commentActivitySuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        NSIndexPath *postCommentRowIndexPath = [NSIndexPath indexPathForRow:postCommentRow inSection:0];
        
        // Set row for height adjustment
        postCommentRow = 0;
        
        // Hide Post Comment
        [self.eventActivityTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:postCommentRowIndexPath] withRowAnimation:UITableViewRowAnimationTop];
    };
    
    commentActivityFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    };
    
    // Setup Parameters
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:@"actstream.action" forKey:@"content_type"];
    [parameters setObject:comment forKey:@"comment"];
    [parameters setObject:selectedActivity.activityId forKey:@"object_id"];
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"comment/"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:commentActivitySuccessBlock failure:commentActivityFailureBlock];
    
    [operation start];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    // We add rows for comments ahead of time, divide and floor to get the correct row for our fetched results
    int row = floor(indexPath.row / 5.0);
    NSIndexPath *fetchedResultsIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    Activity *activity = [self.fetchedResultsController objectAtIndexPath:fetchedResultsIndexPath];

    ActivityCell *activityCell = (ActivityCell*)cell;
    
    if (indexPath.row % 5 == 0) {
        // Post row

        if (activity.actionObjectContentTypeName == nil || [activity.actionObjectContentTypeName isEqualToString:@""]) {
            
        } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.recordingsession"]) {
            // Set thumbnail from API
            ActivityVideoCell *activityVideoCell = (ActivityVideoCell*) cell;
            if (activity.userVideo.thumbnailHDURL != nil) {
                [activityVideoCell.videoThumbnailImageView setImageWithURL:[NSURL URLWithString:activity.userVideo.thumbnailHDURL]];
            }
        } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionphoto"]) {
            // Set thumbnail from API
            ActivityPhotoCell *activityPhotoCell = (ActivityPhotoCell*) cell;
            if (activity.photoThumbnailURL != nil) {
                [activityPhotoCell.photoThumbnailImageView setImageWithURL:[NSURL URLWithString:activity.photoThumbnailURL]];
            }
        } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionnote"]) {
            ActivityNoteCell *activityNoteCell = (ActivityNoteCell *)cell;
            [activityNoteCell.verbLabel setText:NSLocalizedString(@"added a note", @"")];
        }
        
        [activityCell.verbLabel setText:activity.verb];
        
        // Like and Comment counts
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
        
        // Adjust verb / time layout
        [activityCell.verbLabel sizeToFit];
        [activityCell.timeLabel sizeToFit];
        
        int timeLabelOffset = activityCell.verbLabel.frame.size.width + activityCell.verbLabel.frame.origin.x + 5;
        int timeLabelWidth = 220 - timeLabelOffset;  // Like Button Origin, set as number here to offset button frame buffer
        [activityCell.timeLabel setFrame:CGRectMake(timeLabelOffset, activityCell.timeLabel.frame.origin.y, timeLabelWidth, activityCell.timeLabel.frame.size.height)];
        
        // Set Contributer
        [activityCell.contributorLabel setText:activity.person.name];
        [activityCell.contributorImageView setImageWithURL:[NSURL URLWithString:[activity.person pictureURL]] placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
    } else if (indexPath.row % 5 == 4) {
        // Post Comment Row
    } else {
        // Comment Row
        ActivityCommentCell *activityCommentCell = (ActivityCommentCell*)cell;
        
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"submitDate" ascending:NO];
        NSArray *commentArray = [activity.latestComments sortedArrayUsingDescriptors:@[descriptor]];
        
        if ([commentArray count] >= (indexPath.row % 5)) {
            Comment *comment = [commentArray objectAtIndex:(indexPath.row % 5) - 1];
            
            // Set Commenter and comment
            [activityCommentCell.commentLabel setText:comment.comment];
            
            [activityCell.contributorLabel setText:comment.person.name];
            [activityCell.contributorImageView setImageWithURL:[NSURL URLWithString:[comment.person pictureURL]] placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
            
            // Adjust verb / time layout
            [activityCell.contributorLabel sizeToFit];
            [activityCell.timeLabel sizeToFit];
            
            int timeLabelOffset = activityCell.contributorLabel.frame.size.width + activityCell.contributorLabel.frame.origin.x + 5;
            int timeLabelWidth = 220 - timeLabelOffset;  // Like Button Origin, set as number here to offset button frame buffer
            [activityCell.timeLabel setFrame:CGRectMake(timeLabelOffset, activityCell.timeLabel.frame.origin.y, timeLabelWidth, activityCell.timeLabel.frame.size.height)];
        }
    }
    
    

    [activityCell.timeLabel setText:activity.timesince];
    
    // Set delegate and tag
    [activityCell setTag:(indexPath.row / 5)];
    [activityCell setDelegate:self];
}

#pragma mark - UITableViewDataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // We add rows for comments ahead of time, divide and floor to get the correct row for our fetched results
    int row = floor(indexPath.row / 5.0);
    NSIndexPath *fetchedResultsIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    Activity *activity = [self.fetchedResultsController objectAtIndexPath:fetchedResultsIndexPath];
    
    if (indexPath.row % 5 == 0) {
        // Main Post
        return [activity.rowHeight floatValue];
    } else if (indexPath.row % 5 == 4) {
        // Post Comment Row
        if (postCommentRow == indexPath.row) {
            return kActivityPostCommentCellRowHeight;
        } else {
            return 1;
        }
    } else {
        // Comment Row
        // Sort set
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"submitDate" ascending:NO];
        NSArray *commentArray = [activity.latestComments sortedArrayUsingDescriptors:@[descriptor]];
        
        if ([commentArray count] >= (indexPath.row % 5)) {
            Comment *comment = [commentArray objectAtIndex:(indexPath.row % 5) - 1];
            if (comment.rowHeight > 0) {
                return [comment.rowHeight floatValue];
            } else {
                return 1;
            }
        } else {
            return 1;
        }
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    // We will multiple the number of objects by 5 to get
    // 1 Row Main Post
    // 3 Rows Comments
    // 1 Row Post Comment
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects] * 5;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // We add rows for comments ahead of time, divide and floor to get the correct row for our fetched results
    int row = floor(indexPath.row / 5.0);
    NSIndexPath *fetchedResultsIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    Activity *activity = [self.fetchedResultsController objectAtIndexPath:fetchedResultsIndexPath];

    UITableViewCell *cell = nil;

    if (indexPath.row % 5 == 0) {
        // Post row        
        if (activity.actionObjectContentTypeName == nil || [activity.actionObjectContentTypeName isEqualToString:@""]) {
            cell = [tableView dequeueReusableCellWithIdentifier:kActivityActionCellIdentifier];
        } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.recordingsession"]) {
            cell = [tableView dequeueReusableCellWithIdentifier:kActivityVideoCellIdentifier];
        } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionphoto"]) {
            cell = [tableView dequeueReusableCellWithIdentifier:kActivityPhotoCellIdentifier];
        } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionnote"]) {
            cell = [tableView dequeueReusableCellWithIdentifier:kActivityNoteCellIdentifier];
        }
    } else if (indexPath.row % 5 == 4) {
        // Post Comment Row
        cell = [tableView dequeueReusableCellWithIdentifier:kActivityPostCommentCellIdentifier];
    } else {
        // Comment Row
        cell = [tableView dequeueReusableCellWithIdentifier:kActivityCommentCellIdentifier];
    }
    
    if (cell == nil) {
        if (indexPath.row % 5 == 0) {
            if (activity.actionObjectContentTypeName == nil || [activity.actionObjectContentTypeName isEqualToString:@""]) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityActionCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.recordingsession"]) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityVideoCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionphoto"]) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityPhotoCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionnote"]) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityNoteCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            }
        } else if (indexPath.row % 5 == 4) {
            // Post Comment Row
            NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityPostCommentCell" owner:self options:nil];
            cell = [nibArray objectAtIndex:0];
            ActivityPostCommentCell *activityPostCommentCell = (ActivityPostCommentCell*)cell;
            
            // Set Button Image
            UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
            
            // Set Button Image
            UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                             resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
            
            // Set the background for any states you plan to use
            [activityPostCommentCell.postCommentButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
            [activityPostCommentCell.postCommentButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
            [activityPostCommentCell.postCommentButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:17]];
            

        } else {
            // Comment Row
            NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityCommentCell" owner:self options:nil];
            cell = [nibArray objectAtIndex:0];
            ActivityCommentCell *activityCommentCell = (ActivityCommentCell*)cell;
            
            // Set Custom Font
            [activityCommentCell.commentLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
            [activityCommentCell.commentLabel setTextColor:[UIColor whiteColor]];
            [activityCommentCell.commentLabel setShadowColor:[UIColor blackColor]];
            [activityCommentCell.commentLabel setShadowOffset:CGSizeMake(0, 1)];
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
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    int row = [activityCell tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    Activity *activity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UserVideo *userVideo = activity.userVideo;
    
    if (userVideo != nil) {
        // Video
        NSURL *previewRecordingURL = nil;
        if ([userVideo localVideoAssetURL] != nil) {
            //TODO Verify asset url is good
            previewRecordingURL = [NSURL URLWithString:[userVideo localVideoAssetURL]];
        } else {
            previewRecordingURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/%@/%@", [userVideo uploadS3Bucket], [userVideo uploadPath]]];
        }
        
        // Preview
        MPMoviePlayerViewController *viewController = [[MPMoviePlayerViewController alloc] initWithContentURL: previewRecordingURL];
        [appDelegate.slidingViewController presentModalViewController:viewController animated:YES];
    } else {
        // Photo
    }

}

- (void)likeButtonPressed:(ActivityCell*)activityCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:activityCell.tag inSection:0];
    Activity *selectedActivity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Send Network Request
    if (activityCell.likeButton.selected) {
        [self unlikeActivity:selectedActivity];
    } else {
        [self likeActivity:selectedActivity];
    }
    
    // Set the button
    [activityCell.likeButton setSelected:!activityCell.likeButton.selected];
}

- (void)commentButtonPressed:(ActivityCell*)activityCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:((activityCell.tag*5)+4) inSection:0];
    
    // Send Network Request
    if (activityCell.commentButton.selected && postCommentRow != 0) {
        // Remove keyboard if showing
        ActivityPostCommentCell *activityPostCommentCell = (ActivityPostCommentCell*) [self tableView:self.eventActivityTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:postCommentRow inSection:0]];
        [activityPostCommentCell.commentTextField resignFirstResponder];
        
        // Set row for height adjustment
        postCommentRow = 0;
        
        // Hide Post Comment
        [self.eventActivityTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
    } else {
        NSArray *indexPathsToReload = nil;
        if (postCommentRow != 0) {
            // De-select the comment button and reload row we are removing
            ActivityPostCommentCell *activityCell = (ActivityPostCommentCell*) [self tableView:self.eventActivityTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(postCommentRow-4) inSection:0]];
            activityCell.commentButton.selected = NO;
            
            indexPathsToReload = [NSArray arrayWithObjects:indexPath, [NSIndexPath indexPathForRow:postCommentRow inSection:0], nil];
        } else {
            indexPathsToReload = [NSArray arrayWithObject:indexPath];
        }
        
        // Set row for height adjustment
        postCommentRow = indexPath.row;
        
        // Show Post Comment / Hide previous post comment if open
        [self.eventActivityTableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationBottom];
    }
    
    // Set the button
    [activityCell.commentButton setSelected:!activityCell.commentButton.selected];
}

- (void)postCommentButtonPressed:(ActivityPostCommentCell*)activityPostCommentCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:activityPostCommentCell.tag inSection:0];
    Activity *selectedActivity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *commentToPost = activityPostCommentCell.commentTextField.text;
    
    // Remove keyboard
    [activityPostCommentCell.commentTextField resignFirstResponder];
    
    // Validation
    if (commentToPost == nil || [commentToPost isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"You must add a comment before you can post it.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    [self addComment:commentToPost toActivity:selectedActivity];
}

@end
