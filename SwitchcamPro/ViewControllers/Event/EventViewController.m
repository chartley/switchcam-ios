#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import <Social/Social.h>
#import "EventViewController.h"
#import "SPTabStyle.h"
#import "SPTabsView.h"
#import "SPConstants.h"
#import "Mission.h"
#import "Artist.h"
#import "Venue.h"
#import "UserVideo.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "EventInfoViewController.h"
#import "EventActivityViewController.h"
#import "EventPeopleViewController.h"
#import "EventVideosViewController.h"
#import "UploadVideoViewController.h"
#import "SPImageHelper.h"
#import "SPInviteFriendsViewController.h"
#import "UIPlaceholderTextView.h"
#import "AppDelegate.h"

enum { kTagTabBase = 100 };

#define kNoteDrawerHeight 121
#define kBottomBarHeight 44

@interface EventViewController () {
    int topPictureHeight;
    BOOL isShareDrawerOpen;
    BOOL isToolbarDrawerOpen;
    EventActivityViewController *activityViewController;
}

@property (nonatomic, retain) NSArray *viewControllers;
@property (nonatomic, assign, readwrite) UIScrollView *currentView;
@property (nonatomic, assign, readwrite) UIScrollView *currentTabScrollView;
@property (nonatomic, retain) SPTabsView *tabsContainerView;
@property (strong, nonatomic) MBProgressHUD *loadingIndicator;

@end

@implementation EventViewController

@synthesize style, viewControllers, currentView, currentTabScrollView,
  tabsContainerView;

- (id)initWithViewControllers:(NSArray *)theViewControllers
                        style:(SPTabStyle *)theStyle {
    
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.viewControllers = theViewControllers;
        self.style = theStyle;
    }
    
    return self;
}

- (id)initWithMission:(Mission*)mission {
    // Tabs
    EventInfoViewController *eventInfoViewController = [[EventInfoViewController alloc] init];
    [eventInfoViewController setSelectedMission:mission];
    
    EventActivityViewController *eventActivityViewController = [[EventActivityViewController alloc] init];
    [eventActivityViewController setSelectedMission:mission];
    activityViewController = eventActivityViewController;
    
    EventPeopleViewController *eventPeopleViewController = [[EventPeopleViewController alloc] init];
    [eventPeopleViewController setSelectedMission:mission];
    
    EventVideosViewController *eventVideosViewController = [[EventVideosViewController alloc] init];
    [eventVideosViewController setSelectedMission:mission];
    
    NSArray *viewController = [NSArray arrayWithObjects:eventInfoViewController, eventActivityViewController, eventPeopleViewController, eventVideosViewController, nil];
    
    self = [self initWithViewControllers:viewController style:[SPTabStyle defaultStyle]];
    
    if (self) {
        // Custom initialization
        self.mission = mission;
        self.navigationItem.title = self.mission.artist.artistName;
        

    }
    return self;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationMaskPortrait);
}

#pragma mark - Tabs Code

- (void)_reconfigureTabs {
    NSUInteger thisIndex = 0;
    
    for (SPTabView *aTabView in self.tabsContainerView.tabViews) {
        aTabView.style = self.style;
        
        if (thisIndex == currentTabIndex) {
            aTabView.selected = YES;
            [self.tabsContainerView bringSubviewToFront:aTabView];
        } else {
            aTabView.selected = NO;
            [self.tabsContainerView sendSubviewToBack:aTabView];
        }
        
        aTabView.autoresizingMask = UIViewAutoresizingNone;
        
        [aTabView setNeedsDisplay];
        
        ++thisIndex;
    }
}

- (void)_makeTabViewCurrent:(SPTabView *)tabView {
    if (!tabView) return;
    
    currentTabIndex = tabView.tag - kTagTabBase;
    
    EventTabViewController *viewController = [self.viewControllers objectAtIndex:currentTabIndex];
    
    [self.currentView removeFromSuperview];
    self.currentView = (UIScrollView*)viewController.view;
    self.currentTabScrollView = (UIScrollView*)viewController.tabScrollView;
    
    self.currentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.currentView.frame = CGRectMake(0, topPictureHeight + self.tabsContainerView.bounds.size.height, self.view.bounds.size.width, self.eventScrollView.bounds.size.height - self.tabsContainerView.bounds.size.height);
    
    [self.eventScrollView addSubview:self.currentView];
    
    [self _reconfigureTabs];
}

- (void)didTapTabView:(SPTabView *)tappedView {
    NSUInteger index = tappedView.tag - kTagTabBase;
    NSAssert(index < [self.viewControllers count], @"invalid tapped view");
    
    [self _makeTabViewCurrent:tappedView];
    
    // Make sure drawer is still present
    [self.view bringSubviewToFront:self.toolbarDrawer];
}

- (void)viewDidLoad {
    //TODO Switchcam movie
    if (true) {
        topPictureHeight = 156;
        [self.eventLocationLabel setFrame:CGRectMake(20, 109, 280, 21)];
        [self.eventDateLabel setFrame:CGRectMake(20, 129, 280, 21)];
    } else {
        topPictureHeight = 169;
        [self.eventLocationLabel setFrame:CGRectMake(20, 122, 280, 21)];
        [self.eventDateLabel setFrame:CGRectMake(20, 142, 280, 21)];
    }
    
    [self.eventImageView setFrame:CGRectMake(self.eventImageView.frame.origin.x, self.eventImageView.frame.origin.y, 320, topPictureHeight)];
    [self.eventImageView setClipsToBounds:YES];
    
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // The view that contains the tab views is located across the top.
    
    CGRect tabsViewFrame = CGRectMake(0, topPictureHeight, self.view.frame.size.width, self.style.tabsViewHeight);
    self.tabsContainerView = [[SPTabsView alloc] initWithFrame:tabsViewFrame];
    self.tabsContainerView.backgroundColor = [UIColor clearColor];
    self.tabsContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tabsContainerView.style = self.style;
    [self.eventScrollView addSubview:tabsContainerView];
    
    // Tabs are resized such that all fit in the view's width.
    // We position the tab views from left to right, with some overlapping after the first one.
    
    CGFloat tabWidth = self.view.frame.size.width / [self.viewControllers count];
    tabWidth = (self.view.frame.size.width + ([self.viewControllers count] - 1)) / [self.viewControllers count];
    
    NSMutableArray *allTabViews = [NSMutableArray arrayWithCapacity:[self.viewControllers count]];
    
    for (UIViewController *viewController in self.viewControllers) {
        NSUInteger tabIndex = [allTabViews count];
        
        // The selected tab's bottom-most edge should overlap the top shadow of the tab bar under it.
        
        CGRect tabFrame = CGRectMake(tabIndex * tabWidth,
                                     self.style.tabsViewHeight - self.style.tabHeight - self.style.tabBarHeight,
                                     tabWidth,
                                     self.style.tabHeight);
        
        if (tabIndex > 0)
            tabFrame.origin.x -= tabIndex;
        
        SPTabView *tabView = [[SPTabView alloc] initWithFrame:tabFrame title:viewController.title];
        tabView.tag = kTagTabBase + tabIndex;
        [tabView.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:17]];
        [tabView.titleLabel setTextColor:[UIColor whiteColor]];
        [tabView.titleLabel setShadowColor:[UIColor blackColor]];
        [tabView.titleLabel setShadowOffset:CGSizeMake(0, -1)];
        tabView.delegate = self;
        
        if ([viewController isKindOfClass:[EventInfoViewController class]]) {
            [tabView.titleLabel setText:NSLocalizedString(@"Info", @"")];
        } else if ([viewController isKindOfClass:[EventActivityViewController class]]) {
            [tabView.titleLabel setText:NSLocalizedString(@"Activity", @"")];
        } else if ([viewController isKindOfClass:[EventPeopleViewController class]]) {
            [tabView.titleLabel setText:NSLocalizedString(@"People", @"")];
        } else if ([viewController isKindOfClass:[EventVideosViewController class]]) {
            [tabView.titleLabel setText:NSLocalizedString(@"Videos", @"")];
        }
        
        [self.tabsContainerView addSubview:tabView];
        [allTabViews addObject:tabView];
    }
    
    self.tabsContainerView.tabViews = allTabViews;
    
    [self _makeTabViewCurrent:[self.tabsContainerView.tabViews objectAtIndex:0]];
    
    // Add Menu button
    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setFrame:CGRectMake(0, 0, 30, 30)];
    [menuButton setImage:[UIImage imageNamed:@"btn-sidemenu"] forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(menuButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    [self.navigationItem setLeftBarButtonItem:menuBarButtonItem];
    [self.navigationItem setHidesBackButton:YES];
    
    // Add Event Image
    if ([self.mission picURL] != nil) {
        [self.eventImageView setImageWithURL:[NSURL URLWithString:[self.mission picURL]]];
    }
    
    // Set Event Info
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d. YYYY @ ha"];
    NSString *startEventTimeString = [dateFormatter stringFromDate:[self.mission startDatetime]];
    
    NSString *locationString = [NSString stringWithFormat:@"@ %@", [self.mission venue].venueName];
    
    [self.eventLocationLabel setText:locationString];
    [self.eventDateLabel setText:startEventTimeString];
    
    [self.shareNoteTextView setPlaceholder:NSLocalizedString(@"Type your note...", @"")];
    
    // Set Font / Color
    [self.shareNoteLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:11]];
    [self.shareNoteLabel setTextColor:RGBA(185, 196, 200, 1.0)];
    [self.shareNoteLabel setShadowColor:[UIColor blackColor]];
    [self.shareNoteLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.sharePhotoLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:11]];
    [self.sharePhotoLabel setTextColor:RGBA(185, 196, 200, 1.0)];
    [self.sharePhotoLabel setShadowColor:[UIColor blackColor]];
    [self.sharePhotoLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.eventLocationLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:14]];
    [self.eventLocationLabel setTextColor:[UIColor whiteColor]];
    [self.eventLocationLabel setShadowColor:[UIColor blackColor]];
    [self.eventLocationLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.eventDateLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:12]];
    [self.eventDateLabel setTextColor:[UIColor whiteColor]];
    [self.eventDateLabel setShadowColor:[UIColor blackColor]];
    [self.eventDateLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // Adjust drawer toolbar to be set to the correct origin depending on screen size
    [self.toolbarDrawer setFrame:CGRectMake(0, self.view.frame.size.height - self.toolbarDrawer.frame.size.height + kNoteDrawerHeight, self.toolbarDrawer.frame.size.width, self.toolbarDrawer.frame.size.height)];
    [self.view bringSubviewToFront:self.toolbarDrawer];
    
    // Adjust content size of scrollview for ez scrolling between event scrollview and tabs scrollview
    [self.eventScrollView setContentSize:CGSizeMake(320, self.eventScrollView.frame.size.height + self.eventImageView.frame.size.height)];
    
    // Share Drawer Buttons
    
    // Set Button Image
    UIImage *inviteFriendsButtonImage = [[UIImage imageNamed:@"btn-invitefbfirends"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.inviteFacebookFriendsButton setBackgroundImage:inviteFriendsButtonImage forState:UIControlStateNormal];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-ltgrey"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-ltgrey-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.shareEmailButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.shareEmailButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
    
    // Set Button Image
    UIImage *twitterButtonImage = [[UIImage imageNamed:@"btn-twitter-lg"]
                                   resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *twitterHighlightButtonImage = [[UIImage imageNamed:@"btn-twitter-lg-pressed"]
                                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.shareTwitterButton setBackgroundImage:twitterButtonImage forState:UIControlStateNormal];
    [self.shareTwitterButton setBackgroundImage:twitterHighlightButtonImage forState:UIControlStateSelected];
    
    // Set Button Image
    UIImage *facebookButtonImage = [[UIImage imageNamed:@"btn-fb-lg"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *facebookHighlightButtonImage = [[UIImage imageNamed:@"btn-fb-lg-pressed"]
                                             resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.shareFacebookButton setBackgroundImage:facebookButtonImage forState:UIControlStateNormal];
    [self.shareFacebookButton setBackgroundImage:facebookHighlightButtonImage forState:UIControlStateSelected];
    
    // Set Font / Color
    [self.shareEmailButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
    [self.shareEmailButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.shareEmailButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.shareEmailButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.shareTwitterButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
    [self.shareTwitterButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.shareTwitterButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.shareTwitterButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.shareFacebookButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
    [self.shareFacebookButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.shareFacebookButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.shareFacebookButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // Toolbar drawer button
    // Set Button Image
    UIImage *postNoteButtonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *postNoteHighlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.postNoteButton setBackgroundImage:postNoteButtonImage forState:UIControlStateNormal];
    [self.postNoteButton setBackgroundImage:postNoteHighlightButtonImage forState:UIControlStateSelected];
    
    [self.postNoteButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:13]];
    [self.postNoteButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.postNoteButton.titleLabel setShadowColor:[UIColor blackColor]];
    [self.postNoteButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];

    // Add loading indicator
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.loadingIndicator = [[MBProgressHUD alloc] initWithWindow:appDelegate.window];
    [appDelegate.window addSubview:self.loadingIndicator];
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    // Remove Loading Indicator
    [self.loadingIndicator removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // shadowPath, shadowOffset, and rotation is handled by ECSlidingViewController.
    // You just need to set the opacity, radius, and color.
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    // Observe keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Add Share button
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareButton setFrame:CGRectMake(0, 0, 30, 30)];
    
    [shareButton setImage:[UIImage imageNamed:@"btn-invite"] forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    [self.navigationItem setRightBarButtonItem:shareBarButtonItem];
}

#pragma mark - Network Requests

- (void)postNote:(NSString *)note {
    [self.loadingIndicator show:YES];
    
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^postNoteSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^postNoteFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    postNoteSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.loadingIndicator hide:YES];
        
        // Close drawer
        [self noteButtonAction:nil];
        
        // Refresh activity view
        [activityViewController getActivity];
    };
    
    postNoteFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.loadingIndicator hide:YES];
        
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
    
    [parameters setObject:note forKey:@"text"];
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    
    NSString *path = [NSString stringWithFormat:@"mission/%@/note/", [self.mission.missionId stringValue]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:parameters];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:postNoteSuccessBlock failure:postNoteFailureBlock];
    
    [operation start];
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)photoButtonAction:(id)sender {
}

- (IBAction)recordButtonAction:(id)sender {
    SCCamViewController *viewController = [[SCCamViewController alloc] init];
    [viewController setSelectedMission:self.mission];
    [viewController setDelegate:self];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)noteButtonAction:(id)sender {
    // Open/Close drawer
    if (isToolbarDrawerOpen) {
        // Close Drawer
        [UIView animateWithDuration:0.4 animations:^{
            [self.toolbarDrawer setFrame:CGRectMake(self.toolbarDrawer.frame.origin.x, self.toolbarDrawer.frame.origin.y + kNoteDrawerHeight, self.toolbarDrawer.frame.size.width, self.toolbarDrawer.frame.size.height)];}
                         completion:^(BOOL finished){
                             // Re-enable touches on scroll view
                             self.eventScrollView.userInteractionEnabled = YES;
                         }
         ];
        
        // Hide button highlight
        self.shareNoteButtonBackground.hidden = YES;
        
        isToolbarDrawerOpen = NO;
    } else {
        // Disable touches on scroll view
        self.eventScrollView.userInteractionEnabled = NO;
        
        // Open Drawer
        [UIView animateWithDuration:0.4 animations:^{
            [self.toolbarDrawer setFrame:CGRectMake(self.toolbarDrawer.frame.origin.x, self.toolbarDrawer.frame.origin.y - kNoteDrawerHeight, self.toolbarDrawer.frame.size.width, self.toolbarDrawer.frame.size.height)];}
                         completion:nil
         ];
        
        // Show button highlight
        self.shareNoteButtonBackground.hidden = NO;
        
        isToolbarDrawerOpen = YES;
    }
}

- (IBAction)postNoteButtonAction:(id)sender {
    // Remove keyboard
    [self.shareNoteTextView resignFirstResponder];
    
    // Validation
    if (self.shareNoteTextView.text != nil && ![self.shareNoteTextView.text isEqualToString:@""]) {
        [self postNote:self.shareNoteTextView.text];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"Please enter a note before attempting to post!", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
        [alertView show];
    }
}

- (IBAction)chooseFromLibrary:(id)sender {
    // Pick from library, only videos
    UIImagePickerController *viewController = [[UIImagePickerController alloc] init];
    viewController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    viewController.delegate = self;
    viewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    viewController.allowsEditing = NO;
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)shareButtonAction:(id)sender {
    if (isShareDrawerOpen) {
        // Close Drawer
        [UIView animateWithDuration:0.4 animations:^{
            [self.shareDrawer setFrame:CGRectMake(self.shareDrawer.frame.origin.x, self.shareDrawer.frame.origin.y - self.shareDrawer.frame.size.height, self.shareDrawer.frame.size.width, self.shareDrawer.frame.size.height)];
            [self.eventScrollView setFrame:CGRectMake(self.eventScrollView.frame.origin.x, self.eventScrollView.frame.origin.y - self.shareDrawer.frame.size.height, self.eventScrollView.frame.size.width, self.eventScrollView.frame.size.height)];}
                         completion:^(BOOL finished){
                             // Re-enable touches on scroll view
                             self.eventScrollView.userInteractionEnabled = YES;
                         }
         ];
        
        // Change Share button
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [shareButton setFrame:CGRectMake(0, 0, 30, 30)];
        
        [shareButton setImage:[UIImage imageNamed:@"btn-invite"] forState:UIControlStateNormal];
        [shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
        [self.navigationItem setRightBarButtonItem:shareBarButtonItem];
        
        isShareDrawerOpen = NO;
    } else {
        // Disable touches on scroll view
        self.eventScrollView.userInteractionEnabled = NO;
        
        // Open Drawer
        [UIView animateWithDuration:0.4 animations:^{
            [self.shareDrawer setFrame:CGRectMake(self.shareDrawer.frame.origin.x, self.shareDrawer.frame.origin.y + self.shareDrawer.frame.size.height, self.shareDrawer.frame.size.width, self.shareDrawer.frame.size.height)];
            [self.eventScrollView setFrame:CGRectMake(self.eventScrollView.frame.origin.x, self.eventScrollView.frame.origin.y + self.shareDrawer.frame.size.height, self.eventScrollView.frame.size.width, self.eventScrollView.frame.size.height)];}
                         completion:nil
         ];
        
        // Change Share button
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [shareButton setFrame:CGRectMake(0, 0, 30, 30)];
        
        [shareButton setImage:[UIImage imageNamed:@"btn-invite-active"] forState:UIControlStateNormal];
        [shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
        [self.navigationItem setRightBarButtonItem:shareBarButtonItem];
        
        isShareDrawerOpen = YES;
    }
}

- (IBAction)shareFacebookButtonAction:(id)sender {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *facebookSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        NSString *initialText = [NSString stringWithFormat:NSLocalizedString(@"Join the camera crew for %@ at %@!", @""), self.mission.artist.artistName, self.mission.venue.venueName];
        [facebookSheet setInitialText:initialText];
        [facebookSheet addURL:[NSURL URLWithString:self.mission.missionPageURL]];
        
        [self presentViewController:facebookSheet animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Facebook Not Configured", @"") message:NSLocalizedString(@"You don't have a Facebook account setup on this device.  Add one in your Settings app to share via Facebook!", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
        [alertView show];
    }
}

- (IBAction)shareTwitterButtonAction:(id)sender {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        NSString *initialText = [NSString stringWithFormat:NSLocalizedString(@"Join the camera crew for %@ at %@!", @""), self.mission.artist.artistName, self.mission.venue.venueName];
        [tweetSheet setInitialText:initialText];
        [tweetSheet addURL:[NSURL URLWithString:self.mission.missionPageURL]];
        
        [self presentViewController:tweetSheet animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Twitter Not Configured", @"") message:NSLocalizedString(@"You don't have a Twitter account setup on this device.  Add one in your Settings app to share via Twitter!", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
        [alertView show];
    }
}

- (IBAction)shareEmailButtonAction:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        NSMutableString *body = [NSMutableString string];
        // add HTML before the link here with line breaks (\n)
        [body appendFormat:NSLocalizedString(@"<h4>Join the camera crew for %@ at %@!</h4>\n", @""), self.mission.artist.artistName, self.mission.venue.venueName];
        [body appendFormat:NSLocalizedString(@"<a href=\"%@\">View the event!</a>\n", @""), self.mission.missionPageURL];
        [body appendString:NSLocalizedString(@"<div>Hope to see you there!</div>\n", @"")];
        
        MFMailComposeViewController *viewController = [[MFMailComposeViewController alloc] init];
        [viewController setSubject:NSLocalizedString(@"Check out this Switchcam Event!", @"")];
        [viewController setMessageBody:body isHTML:YES];
        [self presentViewController:viewController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email Configured", @"") message:NSLocalizedString(@"You don't have an email account setup on this device.  Add one in your Settings app to share via email!", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
        [alertView show];
    }
}

- (IBAction)inviteFacebookFriendsButtonAction:(id)sender {
    SPInviteFriendsViewController *viewController = [[SPInviteFriendsViewController alloc] init];
    [viewController loadData];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - UIImagePicker Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:^(void) {
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        
        // Check if existing user video exists
        UserVideo *userVideo = nil;
        NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"UserVideo" inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localVideoAssetURL == %@", [assetURL absoluteString]];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error == nil && [results count] > 0) {
            userVideo = [results objectAtIndex:0];
            
            if ([[userVideo state] intValue] > 10) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Already Uploaded", @"") message:NSLocalizedString(@"You've already uploaded this piece of media!", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
                [alertView show];
            } else {
                // Upload
                UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
                [viewController setUserVideoToUpload:userVideo];
                [self presentViewController:viewController animated:YES completion:nil];
            }
        } else {
            // Create Recording
            UserVideo *userVideo = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"UserVideo"
                                    inManagedObjectContext:managedObjectContext];
            
            
            // Set record location
            userVideo.localVideoAssetURL = [assetURL absoluteString];
            
            // Set time and length
            userVideo.recordStart = [NSDate date];
            userVideo.recordEnd = userVideo.recordStart;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
            NSString *dateString = [dateFormatter stringFromDate:[userVideo recordStart]];
            
            // Make sure we don't overwrite
            NSUInteger count = 0;
            NSString *outputURLString = nil;
            do {
                NSString *videoExtension = (__bridge NSString *)UTTypeCopyPreferredTagWithClass(( CFStringRef)AVFileTypeMPEG4, kUTTagClassFilenameExtension);
                NSString *photoExtension = (__bridge NSString *)UTTypeCopyPreferredTagWithClass(( CFStringRef)kUTTypePNG, kUTTagClassFilenameExtension);
                NSString *fileNameNoExtension = @"capture";
                NSString *fileName = [NSString stringWithFormat:@"%@-%@-%u",fileNameNoExtension , dateString, count];
                outputURLString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                outputURLString = [outputURLString stringByAppendingPathComponent:fileName];
                NSString *videoURLString = [outputURLString stringByAppendingPathExtension:videoExtension];
                NSString *thumbnailURLString = [outputURLString stringByAppendingPathExtension:photoExtension];
                
                [userVideo setCompressedVideoURL:videoURLString];
                [userVideo setThumbnailLocalURL:thumbnailURLString];
                [userVideo setFilename:fileName];
                count++;
                
            } while ([[NSFileManager defaultManager] fileExistsAtPath:outputURLString]);
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            
            // Set size when we access info from library and capture thumbnail
            ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset) {
                ALAssetRepresentation *rep = [myasset defaultRepresentation];
                userVideo.sizeBytes =  [NSNumber numberWithLongLong:rep.size];
                userVideo.sizeMegaBytes = [NSNumber numberWithLongLong:((rep.size/1024)/1024)];
                
                // Save Thumbnail
                CGImageWriteToFile([myasset aspectRatioThumbnail], [userVideo thumbnailLocalURL]);
                [managedObjectContext processPendingChanges];
                NSError *error = nil;
                if (![managedObjectContext save:&error]) {
                    NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                }
                
                // Upload
                UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
                [viewController setUserVideoToUpload:userVideo];
                [self presentViewController:viewController animated:YES completion:nil];
            };
            
            ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror) {
                
            };
            
            [library assetForURL:assetURL
                     resultBlock:resultblock
                    failureBlock:failureblock];
        }

    }];
        
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual: self.eventScrollView]) {
        // Check if we have scrolled past the image pass the rest of the scroll to tab scrollview
        int offset = self.eventScrollView.contentOffset.y - self.eventImageView.frame.size.height;
 	    if (offset > 0) {
            // Keep the tabs at the top
            [self.eventScrollView setContentOffset:CGPointMake(0, self.eventImageView.frame.size.height)];
            [self.eventScrollView setScrollEnabled:NO];
            
            // Scroll the bottom view
            int scrollableAmount = self.currentTabScrollView.contentSize.height - self.currentTabScrollView.frame.size.height;
            if (scrollableAmount < 0) {
                scrollableAmount = 0;
            }
            
            // Are we further than we scan scroll down
            if ((self.currentTabScrollView.contentOffset.y + offset) > scrollableAmount) {
                [self.currentTabScrollView setContentOffset:CGPointMake(0, scrollableAmount)];
            } else {
                [self.currentTabScrollView setContentOffset:CGPointMake(0, offset)];
            }
        }
    }
}

#pragma mark - Camera Delegate

- (void)selectExistingButtonPressed {
    [self dismissViewControllerAnimated:YES completion:^(void){
        [self chooseFromLibrary:nil];
    }];
}

#pragma mark - Observers

- (void)keyboardWillShow:(NSNotification *)notification {
    if (isToolbarDrawerOpen) {
        NSDictionary* info = [notification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        [UIView animateWithDuration:0.25 animations:^(){
            [self.toolbarDrawer setFrame:CGRectMake(0, self.toolbarDrawer.frame.origin.y - kbSize.height, 320, self.toolbarDrawer.frame.size.height)];
        } completion:^(BOOL finished) {
        }];
    } else {
        // Keep the tabs at the top
        [UIView animateWithDuration:0.25 animations:^(){
            [self.eventScrollView setContentOffset:CGPointMake(0, self.eventImageView.frame.size.height)];
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (isToolbarDrawerOpen) {
        NSDictionary* info = [notification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        [self.toolbarDrawer setFrame:CGRectMake(0, self.toolbarDrawer.frame.origin.y + kbSize.height, 320, self.toolbarDrawer.frame.size.height)];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
