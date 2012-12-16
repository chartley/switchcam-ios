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
#import "UAirship.h"
#import "UAPush.h"
#import "AFNetworking.h"
#import "MyEventsViewController.h"
#import "ECSlidingViewController.h"
#import "LoginViewController.h"
#import "SPConstants.h"
#import "StatusBarToastAndProgressView.h"
#import "SCS3Uploader.h"

NSString *const SCSessionStateChangedNotification = @"com.switchcam.switchcampro:SCSessionStateChangedNotification";
NSString *const SCAPINetworkRequestCanStartNotification = @"com.switchcam.switchcampro:SCAPINetworkRequestCanStartNotification";

@interface AppDelegate ()

@property (strong, nonatomic) ECSlidingViewController *slidingViewController;
@property (strong, nonatomic) UINavigationController* loginViewController;
@property (strong, nonatomic) StatusBarToastAndProgressView* statusBarToastAndProgressView;

- (void)showLoginView;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize Push
    //[self initAirship:launchOptions];
    
    // Initialize Toast and Progress
    //TODO find the right place for this, since statusbar will get us rejected, disabled for now
    //[self initalizeStatusBarToastAndProgressView];
    
    // Initialize Custom Navigation Bar
    [self initializeNavigationBarAppearance];
    
    // Show Activity Indicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // Initialize RestKit
    [self initializeRestKit];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Fade out splash screen
    UIImageView *splashScreen = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
    [self.window addSubview:splashScreen];
    [self.window makeKeyAndVisible];
    
    [UIView animateWithDuration:0.3 animations:^{splashScreen.alpha = 0.0;}
                     completion:(void (^)(BOOL)) ^{
                         [splashScreen removeFromSuperview];
                         [[NSNotificationCenter defaultCenter] postNotificationName:kAppFadeInCompleteNotification object:nil];
                     }
     ];
    
    MyEventsViewController *myEventsViewController = [[MyEventsViewController alloc] initWithNibName:@"MyEventsViewController" bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:myEventsViewController];
    self.slidingViewController = [[ECSlidingViewController alloc] init];
    self.slidingViewController.topViewController = navController;
    self.window.rootViewController = self.slidingViewController;

    [self.window makeKeyAndVisible];
    
    // See if we have a valid token for the current state.
    if (![self openReadSessionWithAllowLoginUI:NO]) {
        // No? Display the login page.
        [self showLoginView];
    } else {
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
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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

#pragma mark - View Control Helper Methods

- (void)successfulLoginViewControllerChange {
    if (self.loginViewController != nil) {
        UIViewController *topViewController = [self.slidingViewController topViewController];
        [topViewController dismissModalViewControllerAnimated:YES];
        self.loginViewController = nil;
    }
}

#pragma mark Facebook Login Code

- (void)createAndPresentLoginView {
    if (self.loginViewController == nil) {
        LoginViewController *loginRootViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        self.loginViewController = [[UINavigationController alloc] initWithRootViewController:loginRootViewController];
        UIViewController *topViewController = [self.slidingViewController topViewController];
        [topViewController presentModalViewController:self.loginViewController animated:NO];
    }
}

- (void)showLoginView {
    if (self.loginViewController == nil) {
        [self createAndPresentLoginView];
    } else {
        // State being observed at LoginViewController
    }
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
        }
            break;
        case FBSessionStateClosed: {
            // FBSample logic
            // Once the user has logged out, we want them to be looking at the root view.
            UIViewController *topViewController = [self.slidingViewController topViewController];
            UIViewController *modalViewController = [topViewController modalViewController];
            if (modalViewController != nil) {
                [topViewController dismissModalViewControllerAnimated:NO];
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
     @"legal_terms_accept_date": @"legalTermsAcceptDate",
     @"pic_link": @"pictureURL",
     }];
    // If source and destination key path are the same, we can simply add a string to the array
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    
    RKEntityMapping *missionMapping = [RKEntityMapping mappingForEntityForName:@"Mission" inManagedObjectStore:managedObjectStore];
    missionMapping.identificationAttributes = @[ @"missionId" ];
    [missionMapping addAttributeMappingsFromDictionary:@{
     @"id": @"missionId",
     @"lat": @"latitude",
     @"lon": @"longitude",
     @"start_datetime": @"startDatetime",
     @"end_datetime": @"endDatetime",
     @"submission_deadline": @"submissionDeadline",
     }];
    // If source and destination key path are the same, we can simply add a string to the array
    [missionMapping addAttributeMappingsFromArray:@[ @"title" ]];
    
    // Relationships
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"camera_crew" toKeyPath:@"cameraCrew" withMapping:userMapping]];
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"created_by" toKeyPath:@"createdBy" withMapping:userMapping]];    
    [missionMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"followers" toKeyPath:@"followers" withMapping:userMapping]];
    
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"attendedMissions" toKeyPath:@"cameraCrew" withMapping:missionMapping]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"createdMissions" toKeyPath:@"createdBy" withMapping:missionMapping]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"followedMissions" toKeyPath:@"followers" withMapping:missionMapping]];
    
    // Recording Object Mapping
    RKEntityMapping *recordingMapping = [RKEntityMapping mappingForEntityForName:@"Recording" inManagedObjectStore:managedObjectStore];
    recordingMapping.identificationAttributes = @[ @"uploadedVideoId" ];
    [recordingMapping addAttributeMappingsFromDictionary:@{
     @"upload_destination": @"uploadDestination",
     @"upload_s3_bucket": @"uploadS3Bucket",
     @"upload_path": @"uploadPath",
     @"size_mb": @"sizeMegaBytes",
     }];
    // If source and destination key path are the same, we can simply add a string to the array
    [recordingMapping addAttributeMappingsFromArray:@[ @"filename" ]];
    [recordingMapping addAttributeMappingsFromArray:@[ @"mimetype" ]];
    
    
    // Register json serialization
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"application/json"];
    
    // Register our mappings with the provider
    RKResponseDescriptor *missionResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:missionMapping
                                                                                            pathPattern:@"mission/"
                                                                                                keyPath:@"data"
                                                                                            statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:missionResponseDescriptor];
    
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
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
}

#pragma mark - NavigationBar

- (void)initializeNavigationBarAppearance {
    // Set Title bar font
    NSMutableDictionary *titleBarAttributes = [NSMutableDictionary dictionaryWithDictionary: [[UINavigationBar appearance] titleTextAttributes]];
    [titleBarAttributes setValue:[UIFont fontWithName:@"SourceSansPro-Regular" size:18] forKey:UITextAttributeFont];
    [[UINavigationBar appearance] setTitleTextAttributes:titleBarAttributes];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"bg-appheader"] forBarMetrics:UIBarMetricsDefault];
}

#pragma mark - Status Bar Overlay

- (void)initalizeStatusBarToastAndProgressView {
    // Create View
    self.statusBarToastAndProgressView = [[StatusBarToastAndProgressView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    [self.window addSubview:self.statusBarToastAndProgressView];
    
    // Setup listeners
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStarted) name:kSCS3UploadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadCompleted) name:kSCS3UploadCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStarted) name:kSCS3UploadPercentCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFailed) name:kSCS3UploadFailedNotification object:nil];
}

#pragma mark - Observer Methods

- (void)uploadStarted {
    [self.statusBarToastAndProgressView showProgressView];
}

- (void)uploadProgress:(NSNotification*)notification {
    NSNumber *progress = (NSNumber*)[notification object];
    [self.statusBarToastAndProgressView updateProgressLabelWithAmount:[progress floatValue]];
}

- (void)uploadCompleted {
    [self.statusBarToastAndProgressView showToastWithMessage:NSLocalizedString(@"Upload Complete!", @"")];
    [self.statusBarToastAndProgressView hideProgressView];
}

- (void)uploadFailed {
    [self.statusBarToastAndProgressView showToastWithMessage:NSLocalizedString(@"Upload Failed!", @"")];
    [self.statusBarToastAndProgressView hideProgressView];
}

@end
