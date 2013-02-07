//
//  AppDelegate.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "AppDelegate.h"

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <FacebookSDK/FacebookSDK.h>
#import <TestFlightSDK/TestFlight.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "UserVideo.h"
#import "Mission.h"
#import "UAirship.h"
#import "UAPush.h"
#import "SPLocationManager.h"
#import "EventViewController.h"
#import "MyEventsViewController.h"
#import "ECSlidingViewController.h"
#import "LoginViewController.h"
#import "TermsViewController.h"
#import "SPConstants.h"
#import "StatusBarToastAndProgressView.h"
#import "SCS3Uploader.h"
#import "UIImage+H568.h"
#import "NSObject+PerformBlockAfterDelay.h"
#import "SPNavigationController.h"
#import "SCCamViewController.h"
#import "SCCamCaptureManager.h"
#import "SCCamRecorder.h"

NSString *const SCSessionStateChangedNotification = @"com.switchcam.switchcampro:SCSessionStateChangedNotification";
NSString *const SCAPINetworkRequestCanStartNotification = @"com.switchcam.switchcampro:SCAPINetworkRequestCanStartNotification";

#define kUpgradeRequiredMessage 1000
#define kUpgradeOptionalMessage 1001
#define kAlertMessage 1002
#define kAlertWithURLMessage 1003

@interface AppDelegate () {
    CTCallCenter *callCenter;
    NSURL *checkAppLinkURL;
}

@property (strong, nonatomic) SPNavigationController* loginViewController;
@property (strong, nonatomic) StatusBarToastAndProgressView* statusBarToastAndProgressView;

@property (nonatomic) BOOL isUserOnPhoneCall;
@property (nonatomic) BOOL isUserUploading;

- (void)showLoginView;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize Push
    [self initAirship:launchOptions];
    
    // Initialize Custom Navigation Bar
    [self initializeNavigationBarAppearance];
    
    // Show Activity Indicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // Initialize RestKit
    [self initializeRestKit];
    
    // Check for any messages from Switchcam
    [self checkAppMessage];
    
    // Initialize TestFlight
    [TestFlight takeOff:@"2acb3bce-2531-4584-b080-013af6bd4993"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    Mission *mission = [self getDefaultMission];
    
    UIViewController *viewController = nil;
    
    if (mission == nil) {
        viewController = [[MyEventsViewController alloc] initWithNibName:@"MyEventsViewController" bundle:nil];
    } else {
        viewController = [[EventViewController alloc] initWithMission:mission];
    }

    SPNavigationController *navController = [[SPNavigationController alloc] initWithRootViewController:viewController];
    self.slidingViewController = [[ECSlidingViewController alloc] init];
    self.slidingViewController.topViewController = navController;
    self.window.rootViewController = self.slidingViewController;

    [self.window makeKeyAndVisible];
    
    // Initialize Toast and Progress
    [self initalizeStatusBarToastAndProgressView];
    
    // See if we have a valid token for the current state.
    if (![self openReadSessionWithAllowLoginUI:NO]) {
        // No? Display the login page.
        [self showLoginView];
    } else if(![[NSUserDefaults standardUserDefaults] boolForKey:kSPUserAcceptedTermsKey]) {
        // No? show terms page
        [self showTermsView];
    } else {
        // Start location if we haven't yet
        NSTimeInterval secondsSinceManagerStarted = [[NSDate date] timeIntervalSinceDate:[[SPLocationManager sharedInstance] locationManagerStartDate]];
        if (secondsSinceManagerStarted > 120) {
            [[SPLocationManager sharedInstance] start];
        }
        
        // Save Facebook id and token for API access
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *user,
           NSError *error) {
             if (!error) {
                 NSString *facebookId = user.id;
                 NSString *facebookToken = [FBSession activeSession].accessToken;
                 
                 // Force basic auth with credentials
                 [[RKObjectManager sharedManager].HTTPClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
                 
                 [[NSUserDefaults standardUserDefaults] setObject:facebookId forKey:kSPUserFacebookIdKey];
                 [[NSUserDefaults standardUserDefaults] setObject:facebookToken forKey:kSPUserFacebookTokenKey];
                 
                 // Facebook id and token captured, we can start making network requests
                 [[NSNotificationCenter defaultCenter] postNotificationName:SCAPINetworkRequestCanStartNotification
                                                                     object:[FBSession activeSession]];
             } else {
                 // No? Display the login page.
                 [self showLoginView];
             }
         }];
    }
    
    // Fade out splash screen
    UIImageView *splashScreen = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    [splashScreen setFrame:CGRectMake(splashScreen.frame.origin.x, 20, splashScreen.frame.size.width, splashScreen.frame.size.height)];
    [self.window addSubview:splashScreen];
    
    [UIView animateWithDuration:1.0 animations:^{splashScreen.alpha = 0.0;}
                     completion:(void (^)(BOOL)) ^{
                         [splashScreen removeFromSuperview];
                         [[NSNotificationCenter defaultCenter] postNotificationName:kAppFadeInCompleteNotification object:nil];
                     }
     ];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    // Stop any recording
    if ([self.recordingViewController.captureManager.recorder isRecording]) {
        [self.recordingViewController toggleRecording:nil];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // if the app is going away, we close the session object; this is a good idea because
    // things may be hanging off the session, that need releasing (completion block, etc.) and
    // other components in the app may be awaiting close notification in order to do cleanup
    

    [FBSession.activeSession close];
}

#pragma mark - Facebook

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [FBSession.activeSession handleOpenURL:url];
}

#pragma mark - AirShip

- (void)initAirship:(NSDictionary*)launchOptions {
    //Init Airship launch options
    NSMutableDictionary *takeOffOptions = [[NSMutableDictionary alloc] init];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please replace these with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];

    
    [[UAPush shared] resetBadge];//zero badge on startup
    
    // Register for notifications through UAPush for notification type tracking
    [[UAPush shared] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeSound |
                                                         UIRemoteNotificationTypeAlert)];
}

#pragma mark - Push Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Updates the device token and registers the token with UA
    [[UAPush shared] registerDeviceToken:deviceToken];
}

#pragma mark - Helper Methods

- (Mission*)getNearestMissionToNow:(NSArray *)missions {
    long minDiff = -1;
    long currentTime = [[NSDate date] timeIntervalSince1970];
    Mission *returnMission = nil;
    for (Mission *mission in missions) {
        long diff = abs(currentTime - [mission.startDatetime timeIntervalSince1970]);
        if ((minDiff == -1) || (diff < minDiff)) {
            minDiff = diff;
            returnMission = mission;
        }
    }
    
    return returnMission;
}

- (Mission*)getDefaultMission {
    Mission *mission = nil;
    
    // Get the mission closest to now
    NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Mission" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFollowing == YES || isCameraCrew == YES"];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if ([results count] > 0) {
        mission = [self getNearestMissionToNow:results];
    }
    
    return mission;
}

#pragma mark - View Control Helper Methods

- (void)successfulLoginViewControllerChange {
    if (self.loginViewController != nil) {
        UIViewController *topViewController = [self.slidingViewController topViewController];
        [topViewController dismissViewControllerAnimated:YES completion:nil];
        self.loginViewController = nil;
        
        // Start location if we haven't yet
        NSTimeInterval secondsSinceManagerStarted = [[NSDate date] timeIntervalSinceDate:[[SPLocationManager sharedInstance] locationManagerStartDate]];
        if (secondsSinceManagerStarted > 120) {
            [[SPLocationManager sharedInstance] start];
        }
    }
}

#pragma mark - Facebook Login Code

- (void)createAndPresentLoginView {
    if (self.loginViewController == nil) {
        LoginViewController *loginRootViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        self.loginViewController = [[SPNavigationController alloc] initWithRootViewController:loginRootViewController];
        UIViewController *topViewController = [self.slidingViewController topViewController];
        [topViewController presentViewController:self.loginViewController animated:NO completion:nil];
    } else {
        [self.loginViewController popToRootViewControllerAnimated:YES];
        UIViewController *topViewController = [self.slidingViewController topViewController];
        [topViewController presentViewController:self.loginViewController animated:NO completion:nil];
    }
}

- (void)createAndPresentTermsView {
    if (self.loginViewController == nil) {
        LoginViewController *loginRootViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        self.loginViewController = [[SPNavigationController alloc] initWithRootViewController:loginRootViewController];
        
        TermsViewController *termsViewController = [[TermsViewController alloc] initWithNibName:@"TermsViewController" bundle:nil];
        [self.loginViewController pushViewController:termsViewController animated:NO];
        UIViewController *topViewController = [self.slidingViewController topViewController];
        [topViewController presentViewController:self.loginViewController animated:NO completion:nil];
    } else {
        [self.loginViewController popToRootViewControllerAnimated:YES];

        TermsViewController *termsViewController = [[TermsViewController alloc] initWithNibName:@"TermsViewController" bundle:nil];
        [self.loginViewController pushViewController:termsViewController animated:NO];
        UIViewController *topViewController = [self.slidingViewController topViewController];
        [topViewController presentViewController:self.loginViewController animated:NO completion:nil];
    }
}

- (void)showLoginView {
    if (self.loginViewController == nil) {
        [self createAndPresentLoginView];
    } else {
        // State being observed at LoginViewController
    }
}

- (void)showTermsView {
    [self createAndPresentTermsView];
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState)state
                      error:(NSError *)error
{
    // FBSample logic
    // Any time the session is closed, we want to display the login controller (the user
    // cannot use the application unless they are logged in to Facebook). When the session
    // is opened successfully, hide the login controller and show the main UI.
    switch (state) {
        case FBSessionStateOpen: {
            //[self.mainViewController startLocationManager];
            
            // FBSample logic
            // Pre-fetch and cache the friends for the friend picker as soon as possible to improve
            // responsiveness when the user tags their friends.
            FBCacheDescriptor *cacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
            [cacheDescriptor prefetchAndCacheForSession:session];
            
            // Save Facebook id and token for API access
            [[FBRequest requestForMe] startWithCompletionHandler:
             ^(FBRequestConnection *connection,
               NSDictionary<FBGraphUser> *user,
               NSError *error) {
                 if (!error) {
                     NSString *facebookId = user.id;
                     NSString *facebookToken = [FBSession activeSession].accessToken;
                     
                     // Force basic auth with credentials
                     [[RKObjectManager sharedManager].HTTPClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
                     
                     [[NSUserDefaults standardUserDefaults] setObject:facebookId forKey:kSPUserFacebookIdKey];
                     [[NSUserDefaults standardUserDefaults] setObject:facebookToken forKey:kSPUserFacebookTokenKey];
                     [[NSUserDefaults standardUserDefaults] synchronize];
                     
                     // Facebook id and token captured, we can start making network requests
                     [[NSNotificationCenter defaultCenter] postNotificationName:SCAPINetworkRequestCanStartNotification
                                                                         object:[FBSession activeSession]];
                 } else {
                     // No? Display the login page.
                     [self showLoginView];
                 }
             }];
        }
            break;
        case FBSessionStateClosed: {
            // FBSample logic
            // Once the user has logged out, we want them to be looking at the root view.
            UIViewController *topViewController = [self.slidingViewController topViewController];
            UIViewController *modalViewController = [topViewController presentedViewController];
            if (modalViewController != nil) {
                [topViewController dismissViewControllerAnimated:NO completion:nil];
            }
            [self.slidingViewController resetTopView];
            
            [FBSession.activeSession closeAndClearTokenInformation];
            
            [self performSelector:@selector(showLoginView)
                       withObject:nil
                       afterDelay:0.5f];
        }
            break;
        case FBSessionStateClosedLoginFailed: {
            // if the token goes invalid we want to switch right back to
            // the login view, however we do it with a slight delay in order to
            // account for a race between this and the login view dissappearing
            // a moment before
            [self performSelector:@selector(showLoginView)
                       withObject:nil
                       afterDelay:0.5f];
        }
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SCSessionStateChangedNotification
                                                        object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error: %@",
                                                                     [AppDelegate FBErrorCodeDescription:error.code]]
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (BOOL)openReadSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    NSArray *permissionsArray = [NSArray arrayWithObjects:@"email", nil];
    
    return [FBSession openActiveSessionWithReadPermissions:permissionsArray
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                             [self sessionStateChanged:session state:state error:error];
                                         }];
}

- (BOOL)openWriteSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    NSArray *permissionsArray = [NSArray arrayWithObjects:@"publish_actions", nil];
    
    return [FBSession openActiveSessionWithPublishPermissions:permissionsArray
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                             [self sessionStateChanged:session state:state error:error];
                                         }];
}

+ (NSString *)FBErrorCodeDescription:(FBErrorCode) code {
    switch(code){
        case FBErrorInvalid :{
            return @"FBErrorInvalid";
        }
        case FBErrorOperationCancelled:{
            return @"FBErrorOperationCancelled";
        }
        case FBErrorLoginFailedOrCancelled:{
            return @"FBErrorLoginFailedOrCancelled";
        }
        case FBErrorRequestConnectionApi:{
            return @"FBErrorRequestConnectionApi";
        }case FBErrorProtocolMismatch:{
            return @"FBErrorProtocolMismatch";
        }
        case FBErrorHTTPError:{
            return @"FBErrorHTTPError";
        }
        case FBErrorNonTextMimeTypeReturned:{
            return @"FBErrorNonTextMimeTypeReturned";
        }
        case FBErrorNativeDialog:{
            return @"FBErrorNativeDialog";
        }
        default:
            return @"[Unknown]";
    }
}

- (void)logoutUser {
    [FBSession.activeSession closeAndClearTokenInformation];
    [self showLoginView];
    
    [self performBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kAppFadeInCompleteNotification object:nil];
    } afterDelay:0.5];
}

#pragma mark - RestKit

- (void)initializeRestKit {
    // Initialize RestKit
    NSURL *baseURL = [NSURL URLWithString:kAPIHost];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:baseURL];
    
    // Initialize managed object store
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    objectManager.managedObjectStore = managedObjectStore;
    
    // Setup our object mappings
    /**
     Mapping by entity. Here we are configuring a mapping by targetting a Core Data entity with a specific
     name. This allows us to map back Event/User objects directly onto NSManagedObject instances --
     there is no backing model class!
     */
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:managedObjectStore];
    userMapping.identificationAttributes = @[ @"userId" ];
    
    [userMapping addAttributeMappingsFromDictionary:@{
     @"id": @"userId",
     @"mobile_legal_terms_accept_date": @"legalTermsAcceptDate",
     @"pic_link": @"pictureURL",
     }];
    // If source and destination key path are the same, we can simply add a string to the array
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    
    RKEntityMapping *linkMapping = [RKEntityMapping mappingForEntityForName:@"Link" inManagedObjectStore:managedObjectStore];
    linkMapping.identificationAttributes = @[ @"linkURL" ];
    
    [linkMapping addAttributeMappingsFromDictionary:@{
     @"id": @"linkId",
     @"display_name": @"linkName",
     @"url": @"linkURL",
     }];
    
    RKEntityMapping *missionMapping = [RKEntityMapping mappingForEntityForName:@"Mission" inManagedObjectStore:managedObjectStore];
    missionMapping.identificationAttributes = @[ @"missionId" ];
    [missionMapping addAttributeMappingsFromDictionary:@{
     @"id": @"missionId",
     @"lat": @"latitude",
     @"lon": @"longitude",
     @"start_datetime": @"startDatetime",
     @"end_datetime": @"endDatetime",
     @"submission_deadline": @"submissionDeadline",
     @"pic_url": @"picURL",
     @"description": @"missionDescription",
     @"mission_detail_url": @"missionPageURL",
     @"is_follower": @"isFollowing",
     @"is_crew": @"isCameraCrew",
     }];
    // If source and destination key path are the same, we can simply add a string to the array
    [missionMapping addAttributeMappingsFromArray:@[ @"title" ]];
    
    RKEntityMapping *artistMapping = [RKEntityMapping mappingForEntityForName:@"Artist" inManagedObjectStore:managedObjectStore];
    artistMapping.identificationAttributes = @[ @"artistId" ];
    
    [artistMapping addAttributeMappingsFromDictionary:@{
     @"id": @"artistId",
     @"name": @"artistName",
     @"pic_link": @"pictureURL",
     }];
    
    RKEntityMapping *venueMapping = [RKEntityMapping mappingForEntityForName:@"Venue" inManagedObjectStore:managedObjectStore];
    venueMapping.identificationAttributes = @[ @"venueId" ];
    
    [venueMapping addAttributeMappingsFromDictionary:@{
     @"foursquare_id": @"foursquareId",
     @"name": @"venueName",
     @"id": @"venueId",
     }];
    // If source and destination key path are the same, we can simply add a string to the array
    [venueMapping addAttributeMappingsFromArray:@[ @"street" ]];
    [venueMapping addAttributeMappingsFromArray:@[ @"city" ]];
    [venueMapping addAttributeMappingsFromArray:@[ @"state" ]];
    [venueMapping addAttributeMappingsFromArray:@[ @"country" ]];
    
    // Relationships
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"camera_crew" toKeyPath:@"cameraCrew" withMapping:userMapping]];
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"created_by" toKeyPath:@"createdBy" withMapping:userMapping]];    
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"followers" toKeyPath:@"followers" withMapping:userMapping]];
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"venue" toKeyPath:@"venue" withMapping:venueMapping]];
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"artist" toKeyPath:@"artist" withMapping:artistMapping]];
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"links" toKeyPath:@"links" withMapping:linkMapping]];
    
    // User Video Object Mapping
    RKEntityMapping *userVideoMapping = [RKEntityMapping mappingForEntityForName:@"UserVideo" inManagedObjectStore:managedObjectStore];
    userVideoMapping.identificationAttributes = @[ @"videoId" ];
    [userVideoMapping addAttributeMappingsFromDictionary:@{
     @"upload_date": @"uploadDate",
     @"video_id": @"videoId",
     @"input_title": @"inputTitle",
     @"thumbnail_sd": @"thumbnailSDURL",
     @"thumbnail_hd": @"thumbnailHDURL",
     @"duration_seconds": @"durationSeconds",
     @"lon": @"longitude",
     @"lat": @"latitude",
     @"record_date": @"recordStart",
     @"upload_destination": @"uploadDestination",
     @"upload_s3_bucket": @"uploadS3Bucket",
     @"upload_path": @"uploadPath",
     @"size_mb": @"sizeMegaBytes",
     @"video_hd": @"videoHDURL",
     @"video_sd": @"videoSDURL",
     }];
    [userVideoMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"uploaded_by" toKeyPath:@"uploadedBy" withMapping:userMapping]];
    // If source and destination key path are the same, we can simply add a string to the array
    [userVideoMapping addAttributeMappingsFromArray:@[ @"filename" ]];
    [userVideoMapping addAttributeMappingsFromArray:@[ @"mimetype" ]];
    [userVideoMapping addAttributeMappingsFromArray:@[ @"state" ]];
    
    // User Video Object Mapping
    RKEntityMapping *createUserVideoMapping = [RKEntityMapping mappingForEntityForName:@"UserVideo" inManagedObjectStore:managedObjectStore];
    createUserVideoMapping.identificationAttributes = @[ @"uploadPath" ];
    [createUserVideoMapping addAttributeMappingsFromDictionary:@{
     @"upload_date": @"uploadDate",
     @"video_id": @"videoId",
     @"input_title": @"inputTitle",
     @"thumbnail_sd": @"thumbnailSDURL",
     @"thumbnail_hd": @"thumbnailHDURL",
     @"duration_seconds": @"durationSeconds",
     @"lon": @"longitude",
     @"lat": @"latitude",
     @"record_date": @"recordStart",
     @"upload_destination": @"uploadDestination",
     @"upload_s3_bucket": @"uploadS3Bucket",
     @"upload_path": @"uploadPath",
     @"size_mb": @"sizeMegaBytes",
     }];
    [createUserVideoMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"uploaded_by" toKeyPath:@"uploadedBy" withMapping:userMapping]];
    // If source and destination key path are the same, we can simply add a string to the array
    [createUserVideoMapping addAttributeMappingsFromArray:@[ @"filename" ]];
    [createUserVideoMapping addAttributeMappingsFromArray:@[ @"mimetype" ]];
    [createUserVideoMapping addAttributeMappingsFromArray:@[ @"state" ]];
    
    RKEntityMapping *commentMapping = [RKEntityMapping mappingForEntityForName:@"Comment" inManagedObjectStore:managedObjectStore];
    commentMapping.identificationAttributes = @[ @"commentId" ];
    
    [commentMapping addAttributeMappingsFromDictionary:@{
     @"id": @"commentId",
     @"submit_date": @"submitDate",
     }];
    [commentMapping addAttributeMappingsFromArray:@[ @"comment" ]];
    [commentMapping addAttributeMappingsFromArray:@[ @"timesince" ]];
    
    // Relationships
    [commentMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"person" toKeyPath:@"person" withMapping:userMapping]];

    RKEntityMapping *noteMapping = [RKEntityMapping mappingForEntityForName:@"Note" inManagedObjectStore:managedObjectStore];
    noteMapping.identificationAttributes = @[ @"noteId" ];
    
    [noteMapping addAttributeMappingsFromDictionary:@{
     @"id": @"noteId",
     @"text": @"text",
     @"create_datetime": @"createDate",
     }];
    
    RKEntityMapping *activityMapping = [RKEntityMapping mappingForEntityForName:@"Activity" inManagedObjectStore:managedObjectStore];
    activityMapping.identificationAttributes = @[ @"activityId" ];
    
    [activityMapping addAttributeMappingsFromDictionary:@{
     @"id": @"activityId",
     @"action_object_content_type_name": @"actionObjectContentTypeName",
     @"action_object_object_id": @"actionObjectId",
     @"like_count": @"likeCount",
     @"comment_count": @"commentCount",
     @"url": @"photoThumbnailURL",
     @"i_liked": @"iLiked",
     @"i_commented": @"iCommented",
     }];
    // If source and destination key path are the same, we can simply add a string to the array
    [activityMapping addAttributeMappingsFromArray:@[ @"text" ]];
    [activityMapping addAttributeMappingsFromArray:@[ @"verb" ]];
    [activityMapping addAttributeMappingsFromArray:@[ @"timestamp" ]];
    [activityMapping addAttributeMappingsFromArray:@[ @"timesince" ]];
    [activityMapping addAttributeMappingsFromArray:@[ @"deletable" ]];
    
    // Relationships
    [activityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"person" toKeyPath:@"person" withMapping:userMapping]];
    [activityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"action_object.uservideo" toKeyPath:@"userVideo" withMapping:userVideoMapping]];
    [activityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"latest_3_comments" toKeyPath:@"latestComments" withMapping:commentMapping]];
    [activityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"action_object" toKeyPath:@"actionObject" withMapping:noteMapping]];
    
    RKObjectMapping *userVideoRequestMapping = [RKObjectMapping requestMapping]; // objectClass == NSMutableDictionary
    [userVideoRequestMapping addAttributeMappingsFromDictionary:@{
     @"uploadDestination": @"upload_destination",
     @"uploadS3Bucket": @"upload_s3_bucket",
     @"uploadPath": @"upload_path",
     @"sizeMegaBytes": @"size_mb",
     @"recordStart": @"record_date",
     @"durationSeconds": @"duration_seconds",
     @"mission.missionId": @"mission_id",
     @"latitude": @"lat",
     @"longitude": @"lon",
     @"state": @"state",
     }];
    
    // Pagination
    RKObjectMapping *paginationMapping = [RKObjectMapping mappingForClass:[RKPaginator class]];
    [paginationMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"current_page" toKeyPath:@"currentPage"]];
    [paginationMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"items_per_page" toKeyPath:@"perPage"]];
    [paginationMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"total" toKeyPath:@"objectCount"]];
    [[RKObjectManager sharedManager] setPaginationMapping:paginationMapping];
    
    // Register our mappings with the provider
    RKRequestDescriptor *userVideoRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:userVideoRequestMapping objectClass:[UserVideo class] rootKeyPath:@"uservideo"];
    
    RKResponseDescriptor *userVideoResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userVideoMapping pathPattern:@"uservideo" keyPath:@"data" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    RKResponseDescriptor *cameraCrewResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"mission/:missionId/camera_crew" keyPath:@"data" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    RKResponseDescriptor *followerResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"mission/:missionId/follower" keyPath:@"data" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    RKResponseDescriptor *createUserVideoResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:createUserVideoMapping pathPattern:@"uservideo/" keyPath:@"" statusCodes:[NSIndexSet indexSetWithIndex:201]];
    
    RKResponseDescriptor *commentResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:commentMapping pathPattern:@"comment/" keyPath:@"" statusCodes:[NSIndexSet indexSetWithIndex:201]];
    
    RKResponseDescriptor *missionResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:missionMapping
                                                                                            pathPattern:@"mission/"
                                                                                                keyPath:@"data"
                                                                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *missionNoSlashResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:missionMapping
                                                                                              pathPattern:@"mission"
                                                                                                  keyPath:@"data"
                                                                                              statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKResponseDescriptor *activityResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:activityMapping
                                                                                              pathPattern:@"mission/:missionId/activity"
                                                                                                  keyPath:@"data"
                                                                                              statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addRequestDescriptor:userVideoRequestDescriptor];
    [objectManager addResponseDescriptor:userVideoResponseDescriptor];
    [objectManager addResponseDescriptor:cameraCrewResponseDescriptor];
    [objectManager addResponseDescriptor:followerResponseDescriptor];
    [objectManager addResponseDescriptor:createUserVideoResponseDescriptor];
    [objectManager addResponseDescriptor:commentResponseDescriptor];
    [objectManager addResponseDescriptor:missionResponseDescriptor];
    [objectManager addResponseDescriptor:missionNoSlashResponseDescriptor];
    [objectManager addResponseDescriptor:activityResponseDescriptor];
    
    // Register json serialization
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"application/json"];
    [objectManager setRequestSerializationMIMEType:RKMIMETypeJSON];
    
    
    
    /**
     Complete Core Data stack initialization
     */
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SPDirector.sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
}

#pragma mark - NavigationBar

- (void)initializeNavigationBarAppearance {
    id navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[SPNavigationController class], nil];
    
    // Set Title bar font
    NSMutableDictionary *titleBarAttributes = [NSMutableDictionary dictionaryWithDictionary: [navigationBarAppearance titleTextAttributes]];
    [titleBarAttributes setValue:[UIFont fontWithName:@"SourceSansPro-Regular" size:18] forKey:UITextAttributeFont];
    [navigationBarAppearance setTitleTextAttributes:titleBarAttributes];
    
    [navigationBarAppearance setBackgroundImage:[UIImage imageNamed:@"bg-appheader"] forBarMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"bg-appheader"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
}

#pragma mark - Status Bar Overlay

- (void)initalizeStatusBarToastAndProgressView {
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    // Create View
    self.statusBarToastAndProgressView = [[StatusBarToastAndProgressView alloc] initWithFrame:statusBarFrame];
    [self.statusBarToastAndProgressView makeKeyAndVisible];
    
    // Keep all input coming to Main Window
    [self.window makeKeyWindow];
    
    // Setup listeners
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStarted:) name:kSCS3UploadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadCompleted:) name:kSCS3UploadCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadProgress:) name:kSCS3UploadPercentCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFailed:) name:kSCS3UploadFailedNotification object:nil];
    
    
    __weak AppDelegate *weakSelf = self;
    // Call handling
    callCenter = [[CTCallCenter alloc] init];
    callCenter.callEventHandler=^(CTCall* call)
    {
        
        if(call.callState == CTCallStateDialing)
        {
            // The call state, before connection is established, when the user initiates the call.
        }
        if(call.callState == CTCallStateIncoming)
        {
            // The call state, before connection is established, when a call is incoming but not yet answered by the user.
        }
        if(call.callState == CTCallStateConnected)
        {
            // The call state when the call is fully established for all parties involved.
            weakSelf.isUserOnPhoneCall = YES;
            
            // Hide progress
            if (weakSelf.isUserUploading) {
                [weakSelf.statusBarToastAndProgressView hideProgressView];
            }
        }
        if(call.callState == CTCallStateDisconnected)
        {
            // The call state Ended.
            weakSelf.isUserOnPhoneCall = NO;
            
            // Show progress if uploading
            if (weakSelf.isUserUploading) {
                [weakSelf.statusBarToastAndProgressView showProgressView];
            }
        }
        
    };
}

#pragma mark - Observer Methods

- (void)uploadStarted:(NSNotification*)notification {
    self.isUserUploading = YES;
    if (!self.isUserOnPhoneCall) {
        [self.statusBarToastAndProgressView showProgressView];
    }
    
    // Don't let screen fall asleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)uploadProgress:(NSNotification*)notification {
    NSNumber *progress = (NSNumber*)[notification object];
    [self.statusBarToastAndProgressView updateProgressLabelWithAmount:[progress floatValue]];
}

- (void)uploadCompleted:(NSNotification*)notification {
    self.isUserUploading = NO;
    NSString *videoKey = (NSString*)[notification object];
    [self createUserVideo:videoKey];
    
    // Let screen fall asleep
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)uploadFailed:(NSNotification*)notification {
    self.isUserUploading = NO;
    [self.statusBarToastAndProgressView showToastWithMessage:NSLocalizedString(@"Upload Failed!", @"")];
    [self.statusBarToastAndProgressView hideProgressView];
    
    // Let screen fall asleep
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

#pragma mark - Network Requests

- (void)checkAppMessage {
    // Completion Blocks
    void (^checkAppMessageSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^checkAppMessageFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    checkAppMessageSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        // Check for messages
        if ([[responseObject objectForKey:@"data"] count] > 0) {
            NSDictionary *messageObject = [[responseObject objectForKey:@"data"] objectAtIndex:0];
            NSString *status = [messageObject objectForKey:@"status"];
            NSString *title = [messageObject objectForKey:@"title"];
            NSString *message = [messageObject objectForKey:@"body"];
            NSString *linkURL = [messageObject objectForKey:@"link_url"];
            
            UIAlertView *alertView = nil; 
            if ([status isEqualToString:@"upgrade_required"]) {
                // Show message
                alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Upgrade Now", @"") otherButtonTitles: nil];
                [alertView setTag:kUpgradeRequiredMessage];
                
                checkAppLinkURL = [NSURL URLWithString:linkURL];
            } else if ([status isEqualToString:@"upgrade_optional"]) {
                // Show message
                alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Later", @"") otherButtonTitles:NSLocalizedString(@"Upgrade Now", @""), nil];
                [alertView setTag:kUpgradeOptionalMessage];
                
                checkAppLinkURL = [NSURL URLWithString:linkURL];
            } else if (linkURL == nil || [linkURL isEqualToString:@""]){
                // Show message without link
                alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
                [alertView setTag:kAlertMessage];
            } else {
                // Show message
                alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Later", @"") otherButtonTitles:NSLocalizedString(@"Safari", @""), nil];
                [alertView setTag:kAlertWithURLMessage];
                
                checkAppLinkURL = [NSURL URLWithString:linkURL];
            }
            [alertView setDelegate:self];
            [alertView show];
        }
    };
    
    checkAppMessageFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        // Fail silently
    };
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appMessageVersionString = [NSString stringWithFormat:@"ios-%@", appVersion];
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:appMessageVersionString, @"version_id", nil];
    
    NSString *path = [NSString stringWithFormat:@"appmessage"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:path parameters:parameters];
    
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:checkAppMessageSuccessBlock failure:checkAppMessageFailureBlock];
    
    [operation start];
}

- (void)createUserVideo:(NSString*)videoKey {
    // Get UserVideo with videoKey
    UserVideo *userVideoToUpload = nil;
    NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"UserVideo" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uploadPath == %@", videoKey];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error == nil && [results count] > 0) {
        userVideoToUpload = [results objectAtIndex:0];
    } else {
        [self.statusBarToastAndProgressView showToastWithMessage:NSLocalizedString(@"Upload Failed!", @"")];
        [self.statusBarToastAndProgressView hideProgressView];
        return;
    }
    
    // Set S3 Info
    userVideoToUpload.uploadDestination = @"S3";
    userVideoToUpload.uploadS3Bucket = @"upload-switchcam-ios";
    userVideoToUpload.uploadPath = videoKey;
    userVideoToUpload.state = [NSNumber numberWithInt:kUserVideoStateUSER_UPLOADING];  // State should be 10 on server
    
    // Save
    NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    [context processPendingChanges];
    if (![context saveToPersistentStore:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    // Completion Blocks
    void (^createUserVideoSuccessBlock)(RKObjectRequestOperation *operation, RKMappingResult *responseObject);
    void (^createUserVideoFailureBlock)(RKObjectRequestOperation *operation, NSError *error);
    
    
    createUserVideoSuccessBlock = ^(RKObjectRequestOperation *operation, RKMappingResult *responseObject) {
        [self.statusBarToastAndProgressView showToastWithMessage:NSLocalizedString(@"Upload Complete!", @"")];
        [self.statusBarToastAndProgressView hideProgressView];
        
        // Video uploaded
        userVideoToUpload.state = [NSNumber numberWithInt:kUserVideoStateSTORAGE_TRANSFER];
        
        NSError *error = nil;
        
        // Save
        NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        [context processPendingChanges];
        if (![context saveToPersistentStore:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    };
    
    createUserVideoFailureBlock = ^(RKObjectRequestOperation *operation, NSError *error) {
        [self.statusBarToastAndProgressView showToastWithMessage:NSLocalizedString(@"Upload Failed!", @"")];
        [self.statusBarToastAndProgressView hideProgressView];
    };
    
    [[RKObjectManager sharedManager] postObject:userVideoToUpload path:@"uservideo/" parameters:nil success:createUserVideoSuccessBlock failure:createUserVideoFailureBlock];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kUpgradeRequiredMessage) {
        // Force user to upgrade
        [[UIApplication sharedApplication] openURL:checkAppLinkURL];
    } else if (alertView.tag == kUpgradeOptionalMessage) {
        if (buttonIndex == 0) {
            // Canceled
        } else {
            // Open Safari
            [[UIApplication sharedApplication] openURL:checkAppLinkURL];
        }
    } else if (alertView.tag == kAlertWithURLMessage) {
        if (buttonIndex == 0) {
            // Canceled
        } else {
            // Open Safari
            [[UIApplication sharedApplication] openURL:checkAppLinkURL];
        }
    } else if (alertView.tag == kAlertMessage) {
        // Nothing
    }
}



@end
