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
#import "Note.h"

// Calculated with label height
#define kNoteBottomMargin 75
#define kNoteTopMargin 30

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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mission == %@", self.selectedMission];
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
        likedActivity.iLiked = [NSNumber numberWithBool:YES];
        
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
        //TODO insert comment
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
            return 0;
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
                return 0;
            }
        } else {
            return 0;
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
        [appDelegate.slidingViewController presentViewController:viewController animated:YES completion:nil];
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
            indexPathsToShowAndHide = [NSArray arrayWithObjects:indexPath, [NSIndexPath indexPathForRow:postCommentRow inSection:0], nil];
            oldActivityCell.commentButton.selected = NO;
            
            [activityCell.commentButton setSelected:YES];
        
            // Set row for height adjustment
            postCommentRow = indexPath.row;
            
            animationType = UITableViewRowAnimationMiddle;
        } else {
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
        indexPathsToShowAndHide = [NSArray arrayWithObject:indexPath];
        
        [activityCell.commentButton setSelected:YES];
        
        // Set row for height adjustment
        postCommentRow = indexPath.row;
        animationType = UITableViewRowAnimationMiddle;
    }
     
    // Show Post Comment / Hide previous post comment if open
    [self.eventActivityTableView reloadRowsAtIndexPaths:indexPathsToShowAndHide withRowAnimation:animationType];
    
    // Refresh other data
    [self.eventActivityTableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
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
