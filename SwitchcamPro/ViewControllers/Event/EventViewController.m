#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import "EventViewController.h"
#import "SPTabsFooterView.h"
#import "SPTabStyle.h"
#import "SPTabsView.h"
#import "Mission.h"
#import "Artist.h"
#import "Venue.h"
#import "Recording.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "EventInfoViewController.h"
#import "EventActivityViewController.h"
#import "EventPeopleViewController.h"
#import "EventVideosViewController.h"
#import "UploadVideoViewController.h"
#import "SPImageHelper.h"

enum { kTagTabBase = 100 };

#define kTopPictureHeight 169

@interface EventViewController ()

@property (nonatomic, retain) NSArray *viewControllers;
@property (nonatomic, assign, readwrite) UIScrollView *currentView;
@property (nonatomic, retain) SPTabsView *tabsContainerView;
@property (nonatomic, retain) SPTabsFooterView *footerView;

@end

@implementation EventViewController

@synthesize style, viewControllers, currentView,
  tabsContainerView, footerView;

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
    
    UIViewController *viewController = [self.viewControllers objectAtIndex:currentTabIndex];
    
    [self.currentView removeFromSuperview];
    self.currentView = (UIScrollView*)viewController.view;
    
    self.currentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.currentView.frame = CGRectMake(0, kTopPictureHeight + self.tabsContainerView.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
    
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
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // The view that contains the tab views is located across the top.
    
    CGRect tabsViewFrame = CGRectMake(0, kTopPictureHeight, self.view.frame.size.width, self.style.tabsViewHeight);
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
        [tabView.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
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
    
    CGRect footerFrame = CGRectMake(0, tabsViewFrame.size.height - self.style.tabBarHeight - self.style.shadowRadius,
                                    tabsViewFrame.size.width,
                                    self.style.tabBarHeight + self.style.shadowRadius);
    
    self.footerView = [[SPTabsFooterView alloc] initWithFrame:footerFrame];
    self.footerView.backgroundColor = [UIColor clearColor];
    self.footerView.style = self.style;
    self.footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.tabsContainerView addSubview:footerView];
    [self.tabsContainerView bringSubviewToFront:footerView];
    
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
    [self.eventImageView setImageWithURL:[NSURL URLWithString:[self.mission picURL]]];
    
    // Set Event Info
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d. YYYY @ ha"];
    NSString *startEventTimeString = [dateFormatter stringFromDate:[self.mission startDatetime]];
    
    NSString *locationString = [NSString stringWithFormat:@"@ %@", [self.mission venue].venueName];
    
    [self.eventLocationLabel setText:locationString];
    [self.eventDateLabel setText:startEventTimeString];
    
    // Set Font / Color
    [self.shareNoteLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
    [self.shareNoteLabel setTextColor:[UIColor whiteColor]];
    [self.shareNoteLabel setShadowColor:[UIColor blackColor]];
    [self.shareNoteLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.sharePhotoLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
    [self.sharePhotoLabel setTextColor:[UIColor whiteColor]];
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
    [self.toolbarDrawer setFrame:CGRectMake(0, self.view.frame.size.height - self.toolbarDrawer.frame.size.height, self.toolbarDrawer.frame.size.width, self.toolbarDrawer.frame.size.height)];
    [self.view bringSubviewToFront:self.toolbarDrawer];
    
    // Adjust content size of scrollview for ez scrolling between event scrollview and tabs scrollview
    [self.eventScrollView setContentSize:CGSizeMake(320, self.eventScrollView.frame.size.height + self.eventImageView.frame.size.height)];

    [super viewDidLoad];
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
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)photoButtonAction:(id)sender {
}

- (IBAction)recordButtonAction:(id)sender {
    SCCamViewController *viewController = [[SCCamViewController alloc] init];
    [viewController setDelegate:self];
    [self presentModalViewController:viewController animated:YES];
}

- (IBAction)noteButtonAction:(id)sender {
}

- (IBAction)chooseFromLibrary:(id)sender {
    // Pick from library, only videos
    UIImagePickerController *viewController = [[UIImagePickerController alloc] init];
    viewController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    viewController.delegate = self;
    viewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    viewController.allowsEditing = NO;
    
    [self presentModalViewController:viewController animated:YES];
}

#pragma mark - UIImagePicker Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:^(void) {
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        
        // Check if existing recording exists
        Recording *recording = nil;
        NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].persistentStoreManagedObjectContext;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localVideoAssetURL == %@", [assetURL absoluteString]];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error == nil && [results count] > 0) {
            recording = [results objectAtIndex:0];
            
            if ([[recording isUploaded] boolValue]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Already Uploaded", @"") message:NSLocalizedString(@"You've already uploaded this piece of media!", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
                [alertView show];
            } else {
                // Upload
                UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
                [viewController setRecordingToUpload:recording];
                [self presentModalViewController:viewController animated:YES];
            }
        } else {
            // Create Recording
            Recording *recording = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"Recording"
                                    inManagedObjectContext:managedObjectContext];
            
            
            // Set record location
            recording.localVideoAssetURL = [assetURL absoluteString];
            recording.isUploaded = [NSNumber numberWithBool:NO];
            
            // Set time and length
            recording.recordStart = [NSDate date];
            recording.recordEnd = recording.recordStart;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
            NSString *dateString = [dateFormatter stringFromDate:[recording recordStart]];
            
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
                
                [recording setCompressedVideoURL:videoURLString];
                [recording setThumbnailURL:thumbnailURLString];
                [recording setFilename:fileName];
                count++;
                
            } while ([[NSFileManager defaultManager] fileExistsAtPath:outputURLString]);
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            
            // Set size when we access info from library and capture thumbnail
            ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset) {
                ALAssetRepresentation *rep = [myasset defaultRepresentation];
                recording.sizeBytes =  [NSNumber numberWithLongLong:rep.size];
                recording.sizeMegaBytes = [NSNumber numberWithLongLong:((rep.size/1024)/1024)];
                
                // Save Thumbnail
                CGImageWriteToFile([myasset aspectRatioThumbnail], [recording thumbnailURL]);
                [managedObjectContext processPendingChanges];
                NSError *error = nil;
                if (![managedObjectContext save:&error]) {
                    NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                }
                
                // Upload
                UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
                [viewController setRecordingToUpload:recording];
                [self presentModalViewController:viewController animated:YES];
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
    [self dismissModalViewControllerAnimated:YES];
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
            [self.currentView setContentOffset:CGPointMake(0, offset)];
        }
    }
}

#pragma mark - Camera Delegate

- (void)selectExistingButtonPressed {
    [self dismissViewControllerAnimated:YES completion:^(void){
        [self chooseFromLibrary:nil];
    }];
}

@end
