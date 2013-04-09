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
#import "ActionObject.h"
#import "Reachability.h"

// Calculated with label height
#define kNoteBottomMargin 75
#define kNoteTopMargin 30

@interface EventActivityViewController () <UITableViewDelegate, UITableViewDataSource> {
    int postCommentRow;
    UITextField *activeTextField;
}

@property (nonatomic, strong) RKPaginator *activityPaginator;
@property (nonatomic, strong) NSMutableArray *activities;
@property (nonatomic, strong) UITextField *postCommentTextField;

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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mission == %@", self.selectedMission];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[descriptor];
    fetchRequest.fetchLimit = 10;
    
    // Setup fetched results
    NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error == nil && results != nil) {
        self.activities = [NSMutableArray arrayWithArray:results];
    }
    
    [self getActivity];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Observe keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Network Calls

- (void)getActivity {
    NSString *path = [NSString stringWithFormat:@"mission/%@/activity?page=:currentPage", [self.selectedMission.missionId stringValue]];
    
    // Completion Blocks
    void (^getActivitySuccessBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
    void (^getActivityFailureBlock)(RKPaginator *paginator, NSError *error);
    
    getActivitySuccessBlock = ^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        // Re-enable Load More button
        [self.loadMoreButton setEnabled:YES];
        
        // Set the row height for each activity
        for (Activity *activity in objects) {
            if (activity.actionObjectContentTypeName == nil || [activity.actionObjectContentTypeName isEqualToString:@""]) {
                activity.rowHeight = [NSNumber numberWithInt:kActivityActionCellRowHeight];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.recordingsession"]) {
                activity.rowHeight = [NSNumber numberWithInt:kActivityVideoCellRowHeight];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionphoto"]) {
                activity.rowHeight = [NSNumber numberWithInt:kActivityPhotoCellRowHeight];
            } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionnote"]) {
                CGSize labelSize = [activity.actionObject.text sizeWithFont:[UIFont fontWithName:@"SourceSansPro-It" size:13.0] constrainedToSize:CGSizeMake(260, 600) lineBreakMode:NSLineBreakByWordWrapping];
                int rowHeight = labelSize.height + kNoteBottomMargin + kNoteTopMargin; // Label size, fixed bottom, fixed top
                activity.rowHeight = [NSNumber numberWithInt:rowHeight];
            }
            
            for (Comment *comment in activity.latestComments) {
                CGSize labelSize = [comment.comment sizeWithFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:13.0] constrainedToSize:CGSizeMake(264, 600) lineBreakMode:NSLineBreakByWordWrapping];
                int rowHeight = labelSize.height + 28 + 15; // Label size, fixed bottom, fixed top
                comment.rowHeight = [NSNumber numberWithInt:rowHeight];
            }
            
            activity.mission = self.selectedMission;
        }
        
        if ([paginator currentPage] == 1) {
            self.activities = [NSMutableArray arrayWithArray:objects];
        } else {
            [self.activities addObjectsFromArray:objects];
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
            [self.eventActivityTableView setTableFooterView:self.loadMoreView];
        } else {
            // Hide footer for load more
            [self.eventActivityTableView setTableFooterView:nil];
        }
        
        RKLogInfo(@"Load complete: Table should refresh...");
        [self.eventActivityTableView reloadData];
    };
    
    getActivityFailureBlock = ^(RKPaginator *paginator, NSError *error) {
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
    self.activityPaginator = [[RKObjectManager sharedManager] paginatorWithPathPattern:path];
    [self.activityPaginator setCompletionBlockWithSuccess:getActivitySuccessBlock failure:getActivityFailureBlock];
    [self.activityPaginator loadPage:1];
}

- (void)likeActivity:(Activity*)likedActivity {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^likeActivitySuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^likeActivityFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    likeActivitySuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        likedActivity.iLiked = [NSNumber numberWithBool:YES];
        likedActivity.likeCount = [NSNumber numberWithInt:([[likedActivity likeCount] intValue] + 1)];
        
        NSError *error = nil;
        if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        [self.eventActivityTableView reloadData];
    };
    
    likeActivityFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else if ([[operation response] statusCode] == 401) {
            // Session expired
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate logoutUser];
            
            NSString *title = NSLocalizedString(@"Session expired", @"");
            NSString *message = NSLocalizedString(@"Your session has expired, please login and try again.", @"");
            
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
        unlikedActivity.iLiked = [NSNumber numberWithBool:NO];
        unlikedActivity.likeCount = [NSNumber numberWithInt:([[unlikedActivity likeCount] intValue] - 1)];
        
        NSError *error = nil;
        if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        [self.eventActivityTableView reloadData];
    };
    
    unlikeActivityFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSString *title = NSLocalizedString(@"No Network Connection", @"");
            NSString *message = NSLocalizedString(@"Please check your internet connection and try again.", @"");
            
            // Show alert
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else if ([[operation response] statusCode] == 401) {
            // Session expired
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate logoutUser];
            
            NSString *title = NSLocalizedString(@"Session expired", @"");
            NSString *message = NSLocalizedString(@"Your session has expired, please login and try again.", @"");
            
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
    void (^commentActivitySuccessBlock)(RKObjectRequestOperation *operation, RKMappingResult *responseObject);
    void (^commentActivityFailureBlock)(RKObjectRequestOperation *operation, NSError *error);
    
    commentActivitySuccessBlock = ^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        // Insert comment
        Comment *comment = [[result array] objectAtIndex:0];
        
        // Get Object off main queue
        NSError *error = nil;
        comment = (Comment*)[[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext existingObjectWithID:[comment objectID] error:&error];
        
        if (error != nil) {
            //TODO logging
            return;
        }
        
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"submitDate" ascending:YES];
        NSArray *commentArray = [selectedActivity.latestComments sortedArrayUsingDescriptors:@[descriptor]];
        
        // Remove oldest if count == 3
        if ([commentArray count] == 3) {
            [selectedActivity removeLatestCommentsObject:[commentArray objectAtIndex:0]];
        }
        
        // Increase comment count
        [selectedActivity setCommentCount:[NSNumber numberWithInt:([selectedActivity.commentCount intValue] + 1)]];
        
        // Calculate row height
        CGSize labelSize = [comment.comment sizeWithFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:13.0] constrainedToSize:CGSizeMake(264, 600) lineBreakMode:NSLineBreakByWordWrapping];
        int rowHeight = labelSize.height + 28 + 15; // Label size, fixed bottom, fixed top
        comment.rowHeight = [NSNumber numberWithInt:rowHeight];
        
        // Add comment
        [comment setActivity:selectedActivity];
        [selectedActivity addLatestCommentsObject:comment];
        
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        // Reload all rows pertaining to this post
        for (int i = postCommentRow; i > postCommentRow - 5; i--) {
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        // Set row for height adjustment
        postCommentRow = 0;
        
        // Hide Post Comment
        [self.eventActivityTableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationTop];
    };
    
    commentActivityFailureBlock = ^(RKObjectRequestOperation *operation, NSError *error) {
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
    
    // Use private queue otherwise we could deadlock
    NSManagedObjectContext *context = [[RKManagedObjectStore defaultStore] newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
    RKManagedObjectRequestOperation *operation = [[RKObjectManager sharedManager] managedObjectRequestOperationWithRequest:request managedObjectContext:context success:commentActivitySuccessBlock failure:commentActivityFailureBlock];
    
    // Start Upload in background
    [self performSelectorInBackground:@selector(startCommentPost:) withObject:operation];
    

}

- (void)startCommentPost:(RKManagedObjectRequestOperation*) operation {
    [operation start];
}

#pragma mark - IBActions

- (IBAction)loadMoreButtonAction:(id)sender {
    // Load next page, disable button until call complete
    [self.loadMoreButton setEnabled:NO];
    [self.loadMoreLabel setText:NSLocalizedString(@"Loading...", @"")];
    [self.activityIndicatorView startAnimating];
    [self.activityPaginator loadNextPage];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    // We add rows for comments ahead of time, divide and floor to get the correct row for our fetched results
    int row = floor(indexPath.row / 5.0);
    
    Activity *activity = [self.activities objectAtIndex:row];

    ActivityCell *activityCell = (ActivityCell*)cell;
    
    // Hide separator if top row
    if (indexPath.row == 0) {
        [activityCell.activityTopSeparatorView setHidden:YES];
    } else {
        [activityCell.activityTopSeparatorView setHidden:NO];
    }
    
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
            if (activity.actionObject.thumbURL != nil) {
                [activityPhotoCell.photoThumbnailImageView setImageWithURL:[NSURL URLWithString:activity.actionObject.thumbURL]];
            }
        } else if ([activity.actionObjectContentTypeName isEqualToString:@"director.missionnote"]) {
            ActivityNoteCell *activityNoteCell = (ActivityNoteCell *)cell;
            [activityNoteCell.verbLabel setText:NSLocalizedString(@"added a note", @"")];
            
            int labelHeight = [activity.rowHeight intValue] - kNoteBottomMargin - kNoteTopMargin;
            [activityNoteCell.noteLabel setFrame:CGRectMake(30, 30, 260, labelHeight)];
            [activityNoteCell.noteLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:13.0]];
            [activityNoteCell.noteLabel setText:activity.actionObject.text];
            [activityNoteCell.noteLabel setTextColor:RGBA(184, 196, 200, 1.0)];
            
            // Set background with rounded corners
            [activityNoteCell.noteBackground setFrame:CGRectMake(20, 20, 280, labelHeight + 20)];
            [activityNoteCell.noteBackground setBackgroundColor:RGBA(47, 50, 51, 1.0)];
            [activityNoteCell.noteBackground.layer setCornerRadius:5.0f];
            [activityNoteCell.noteBackground.layer setBorderColor:RGBA(58, 60, 61, 1).CGColor];
            [activityNoteCell.noteBackground.layer setBorderWidth:1.5f];
            [activityNoteCell.noteBackground.layer setMasksToBounds:YES];
            
            // Move rest of the label down
            [activityNoteCell setFrame:CGRectMake(0, 0, 320, [activity.rowHeight intValue])];
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
        
        if ([activity.iLiked boolValue]) {
            [activityCell.likeButton setSelected:YES];
        } else if ([activity.likeCount intValue]) {
            [activityCell.likeButton setSelected:NO];
            [activityCell.likeButton setImage:[UIImage imageNamed:@"icn-like-haslikes"] forState:UIControlStateNormal];
        } else {
            [activityCell.likeButton setSelected:NO];
            [activityCell.likeButton setImage:[UIImage imageNamed:@"icn-link-inactive"] forState:UIControlStateNormal];
        }
        
        if ([activity.iCommented boolValue]) {
            [activityCell.commentButton setImage:[UIImage imageNamed:@"icn-comment-commented"] forState:UIControlStateNormal];
        } else {
            [activityCell.commentButton setImage:[UIImage imageNamed:@"icn-comment-inactive"] forState:UIControlStateNormal];
        }
        
        // Adjust verb / time layout
        [activityCell.verbLabel sizeToFit];
        [activityCell.timeLabel sizeToFit];
        
        int timeLabelOffset = activityCell.verbLabel.frame.size.width + activityCell.verbLabel.frame.origin.x + 5;
        int timeLabelWidth = 220 - timeLabelOffset;  // Like Button Origin, set as number here to offset button frame buffer
        [activityCell.timeLabel setFrame:CGRectMake(timeLabelOffset, activityCell.timeLabel.frame.origin.y, timeLabelWidth, activityCell.timeLabel.frame.size.height)];
        
        // Set Contributer
        [activityCell.contributorLabel setText:activity.person.name];
        if ([activity.person pictureURL]) {
            [activityCell.contributorImageView setImageWithURL:[NSURL URLWithString:[activity.person pictureURL]] placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
        } else {
            [activityCell.contributorImageView setImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
        }
        
        [activityCell.timeLabel setText:activity.timesince];
    } else if (indexPath.row % 5 == 4) {
        // Post Comment Row
        ActivityPostCommentCell *activityPostCommentCell = (ActivityPostCommentCell*)cell;
        
        // Hide if we aren't showing post comment so we can have a small buffer at the bottom
        if (postCommentRow == indexPath.row) {
            activityPostCommentCell.hidden = NO;
            
            self.postCommentTextField = activityPostCommentCell.commentTextField;
        } else {
            activityPostCommentCell.hidden = YES;
        }
    } else {
        // Comment Row
        ActivityCommentCell *activityCommentCell = (ActivityCommentCell*)cell;
        
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"submitDate" ascending:YES];
        NSArray *commentArray = [activity.latestComments sortedArrayUsingDescriptors:@[descriptor]];
        
        if ([commentArray count] >= (indexPath.row % 5)) {
            Comment *comment = [commentArray objectAtIndex:(indexPath.row % 5) - 1];
            
            // Set Commenter and comment
            [activityCommentCell.commentLabel setText:comment.comment];
            
            [activityCell.contributorLabel setText:comment.person.name];
            if ([comment.person pictureURL]) {
                [activityCell.contributorImageView setImageWithURL:[NSURL URLWithString:[comment.person pictureURL]] placeholderImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
            } else {
                [activityCell.contributorImageView setImage:[UIImage imageNamed:@"img-shoot-thumb-placeholder"]];
            }
            
            [activityCell.timeLabel setText:comment.timesince];
            
            // Adjust verb / time layout
            [activityCell.contributorLabel sizeToFit];
            [activityCell.timeLabel sizeToFit];
            
            int timeLabelOffset = activityCell.contributorLabel.frame.size.width + activityCell.contributorLabel.frame.origin.x + 5;
            int timeLabelWidth = 220 - timeLabelOffset;  // Like Button Origin, set as number here to offset button frame buffer
            [activityCell.timeLabel setFrame:CGRectMake(timeLabelOffset, activityCell.timeLabel.frame.origin.y, timeLabelWidth, activityCell.timeLabel.frame.size.height)];
            
            // Cell auto shrinks when its reused, re-expand here
            [activityCommentCell.commentBubbleBackground setFrame:CGRectMake(activityCommentCell.commentBubbleBackground.frame.origin.x, activityCommentCell.commentBubbleBackground.frame.origin.y, activityCommentCell.commentBubbleBackground.frame.size.width, [comment.rowHeight floatValue])];
        }
        
        BOOL isPostCommentShowing = ((activityCell.tag*5)+4) == postCommentRow;

        // Check if we should do any corner rounding
        if (indexPath.row % 5 == 1 && indexPath.row % 5 == activity.latestComments.count && !isPostCommentShowing) {
            // Only one cell, round everything
            UIBezierPath *maskPath;
            maskPath = [UIBezierPath bezierPathWithRoundedRect:activityCommentCell.commentBubbleBackground.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(5.0, 5.0)];
            
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = activityCommentCell.bounds;
            maskLayer.path = maskPath.CGPath;
            activityCommentCell.commentBubbleBackground.layer.mask = maskLayer;
            [activityCommentCell.commentBubbleBackground setBackgroundColor:RGBA(62, 62, 62, 1.0)];
            activityCommentCell.commentDivider.hidden = YES;
        } else if (indexPath.row % 5 == 1) {
            // This is the top comment cell, round the top
            UIBezierPath *maskPath;
            maskPath = [UIBezierPath bezierPathWithRoundedRect:activityCommentCell.commentBubbleBackground.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(5.0, 5.0)];
            
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = activityCommentCell.bounds;
            maskLayer.path = maskPath.CGPath;
            activityCommentCell.commentBubbleBackground.layer.mask = maskLayer;
            [activityCommentCell.commentBubbleBackground setBackgroundColor:RGBA(62, 62, 62, 1.0)];
            activityCommentCell.commentDivider.hidden = NO;
        } else if (indexPath.row % 5 == activity.latestComments.count && !isPostCommentShowing) {
            // This is the bottom comment cell, round the bottom if postComment row isn't showing
            UIBezierPath *maskPath;
            maskPath = [UIBezierPath bezierPathWithRoundedRect:activityCommentCell.commentBubbleBackground.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(5.0, 5.0)];
            
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = activityCommentCell.bounds;
            maskLayer.path = maskPath.CGPath;
            activityCommentCell.commentBubbleBackground.layer.mask = maskLayer;
            [activityCommentCell.commentBubbleBackground setBackgroundColor:RGBA(62, 62, 62, 1.0)];
            activityCommentCell.commentDivider.hidden = YES;
        } else {
            // No rounding, this is a middle cell
            // Create a path and add the rectangle in it.
            CGMutablePathRef maskPath = CGPathCreateMutable();
            CGPathAddRect(maskPath, nil, activityCommentCell.commentBubbleBackground.bounds);
            
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = activityCommentCell.bounds;
            maskLayer.path = maskPath;
            activityCommentCell.commentBubbleBackground.layer.mask = maskLayer;
            activityCommentCell.commentDivider.hidden = NO;
            CGPathRelease(maskPath);
        }
    }
    

    // Set delegate and tag
    [activityCell setTag:(indexPath.row / 5)];
    [activityCell setDelegate:self];
}

- (void)scrollPostCommentToBeVisible {
    // Check to see if we are the last row, if so scroll to the middle,
    // otherwise scroll the next row to the bottom so we can keep context
    if (postCommentRow == (([self.activities count] * 5) - 1)) {
        [self.eventActivityTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:postCommentRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    } else {
        [self.eventActivityTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:postCommentRow+1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - UITableViewDataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // We add rows for comments ahead of time, divide and floor to get the correct row for our fetched results
    int row = floor(indexPath.row / 5.0);
    
    Activity *activity = [self.activities objectAtIndex:row];
    
    if (indexPath.row % 5 == 0) {
        // Main Post
        return [activity.rowHeight floatValue];
    } else if (indexPath.row % 5 == 4) {
        // Post Comment Row
        if (postCommentRow == indexPath.row) {
            return kActivityPostCommentCellRowHeight;
        } else {
            if ([[activity commentCount] intValue] > 0) {
                // Buffer
                return 20;
            } else {
                return 0;
            }

        }
    } else {
        // Comment Row
        // Sort set
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"submitDate" ascending:YES];
        NSArray *commentArray = [activity.latestComments sortedArrayUsingDescriptors:@[descriptor]];
        
        if ([commentArray count] >= (indexPath.row % 5)) {
            Comment *comment = [commentArray objectAtIndex:(indexPath.row % 5) - 1];
            if (comment.rowHeight > 0) {
                return [comment.rowHeight floatValue];
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    // We will multiple the number of objects by 5 to get
    // 1 Row Main Post
    // 3 Rows Comments
    // 1 Row Post Comment
    
    return [self.activities count] * 5;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // We add rows for comments ahead of time, divide and floor to get the correct row for our fetched results
    int row = floor(indexPath.row / 5.0);
    
    Activity *activity = [self.activities objectAtIndex:row];

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
            
            [activityPostCommentCell.commentTextField setDelegate:self];
        } else {
            // Comment Row
            NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ActivityCommentCell" owner:self options:nil];
            cell = [nibArray objectAtIndex:0];
            ActivityCommentCell *activityCommentCell = (ActivityCommentCell*)cell;
            
            // Set Custom Font
            [activityCommentCell.commentLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:13]];
            [activityCommentCell.commentLabel setTextColor:[UIColor whiteColor]];
            [activityCommentCell.commentLabel setShadowColor:[UIColor blackColor]];
            [activityCommentCell.commentLabel setShadowOffset:CGSizeMake(0, 1)];
        }
    
        // Set Custom Font
        ActivityCell *activityCell = (ActivityCell *)cell;
        [activityCell.contributorLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
        [activityCell.verbLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        [activityCell.timeLabel setFont:[UIFont fontWithName:@"SourceSansPro-LightIt" size:12]];
        [activityCell.likeCountLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        [activityCell.commentCountLabel setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:12]];
        
        [activityCell.contributorLabel setTextColor:[UIColor whiteColor]];
        [activityCell.verbLabel setTextColor:[UIColor whiteColor]];
        [activityCell.timeLabel setTextColor:RGBA(105, 105, 105, 1)];
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

#pragma mark - Activity Cell Delegate Methods

- (void)previewButtonPressed:(ActivityCell*)activityCell {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    int row = [activityCell tag];
    
    Activity *activity = [self.activities objectAtIndex:row];
    
    UserVideo *userVideo = activity.userVideo;
    
    if (userVideo != nil) {
        // Video
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
    } else {
        // Photo
    }

}

- (void)likeButtonPressed:(ActivityCell*)activityCell {
    int row = [activityCell tag];
    Activity *selectedActivity = [self.activities objectAtIndex:row];
    
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
    

    UITableViewRowAnimation animationType;
    NSArray *indexPathsToShowAndHide = nil;
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    
    // Is post comment currently showing somewhere?
    if (postCommentRow != 0) {
        // Reload all rows pertaining to this post
        for (int i = postCommentRow - 1; i > postCommentRow - 5; i--) {
            [indexPathsToReload addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        // De-select the comment button and reload row we are removing
        ActivityPostCommentCell *oldActivityCell = (ActivityPostCommentCell*) [self tableView:self.eventActivityTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(postCommentRow-4) inSection:0]];
        
        NSIndexPath *indexPathForHiding = [NSIndexPath indexPathForRow:postCommentRow inSection:0];
        
        // Check if we are hiding the current row
        if (![indexPathForHiding isEqual:indexPath]) {
            // Add post comment row for this post and hide other post comment row
            
            // Give ourselves additional space by moving tabs to top
            [self.eventViewController moveTabsToTop];
            
            indexPathsToShowAndHide = [NSArray arrayWithObjects:indexPath, [NSIndexPath indexPathForRow:postCommentRow inSection:0], nil];
            oldActivityCell.commentButton.selected = NO;
            
            [activityCell.commentButton setSelected:YES];
        
            // Set row for height adjustment
            postCommentRow = indexPath.row;
            
            animationType = UITableViewRowAnimationMiddle;
            
            [self scrollPostCommentToBeVisible];
        } else {
            // Hide other post comment row
            indexPathsToShowAndHide = [NSArray arrayWithObject:indexPath];
            
            // Remove keyboard if showing
            ActivityPostCommentCell *activityPostCommentCell = (ActivityPostCommentCell*) [self tableView:self.eventActivityTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:postCommentRow inSection:0]];
            [activityPostCommentCell.commentTextField resignFirstResponder];
            
            [activityCell.commentButton setSelected:NO];
            
            // Set row for height adjustment
            postCommentRow = 0;
            
            animationType = UITableViewRowAnimationMiddle;
        }
    } else {
        // Add post comment row
        // Give ourselves additional space by moving tabs to top
        [self.eventViewController moveTabsToTop];
        
        indexPathsToShowAndHide = [NSArray arrayWithObject:indexPath];
        
        [activityCell.commentButton setSelected:YES];
        
        // Set row for height adjustment
        postCommentRow = indexPath.row;
        animationType = UITableViewRowAnimationMiddle;
        
        [self scrollPostCommentToBeVisible];
    }
    
    // Show Post Comment / Hide previous post comment if open
    [self.eventActivityTableView reloadRowsAtIndexPaths:indexPathsToShowAndHide withRowAnimation:animationType];
    
    // Refresh other data
    [self.eventActivityTableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
    
    // Show keyboard
    [self.postCommentTextField becomeFirstResponder];
}

- (void)postCommentButtonPressed:(ActivityPostCommentCell*)activityPostCommentCell {
    int row = activityPostCommentCell.tag;
    Activity *selectedActivity = [self.activities objectAtIndex:row];
    
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
    [activityPostCommentCell.commentTextField setText:@""];
}

#pragma mark - Observers

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.eventActivityTableView.contentInset = contentInsets;
    self.eventActivityTableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect rc = [activeTextField bounds];
    rc = [activeTextField convertRect:rc toView:self.eventActivityTableView];
    [self.eventActivityTableView scrollRectToVisible:rc animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.25 animations:^{
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        self.eventActivityTableView.contentInset = contentInsets;
        self.eventActivityTableView.scrollIndicatorInsets = contentInsets;
    }
                     completion:(void (^)(BOOL)) ^{
                     }
     ];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
