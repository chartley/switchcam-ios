#import "EventViewController.h"
#import "SPTabsFooterView.h"
#import "SPTabStyle.h"
#import "SPTabsView.h"
#import "Event.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "SCCamViewController.h"
#import "EventInfoViewController.h"
#import "EventActivityViewController.h"
#import "EventPeopleViewController.h"
#import "EventVideosViewController.h"
#import "UploadVideoViewController.h"

enum { kTagTabBase = 100 };

#define kTopPictureHeight 169

@interface EventViewController ()

@property (nonatomic, retain) NSArray *viewControllers;
@property (nonatomic, assign, readwrite) UIView *currentView;
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

- (id) init {
    // Tabs
    EventInfoViewController *eventInfoViewController = [[EventInfoViewController alloc] init];
    
    EventActivityViewController *eventActivityViewController = [[EventActivityViewController alloc] init];
    
    EventPeopleViewController *eventPeopleViewController = [[EventPeopleViewController alloc] init];
    
    EventVideosViewController *eventVideosViewController = [[EventVideosViewController alloc] init];
    
    NSArray *viewController = [NSArray arrayWithObjects:eventInfoViewController, eventActivityViewController, eventPeopleViewController, eventVideosViewController, nil];
    
    self = [self initWithViewControllers:viewController style:[SPTabStyle defaultStyle]];
    
    if (self) {
        // Custom initialization
        
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
    self.currentView = viewController.view;
    
    self.currentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.currentView.frame = CGRectMake(0, kTopPictureHeight + self.tabsContainerView.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [self.view addSubview:self.currentView];
    
    [self _reconfigureTabs];
}

- (void)didTapTabView:(SPTabView *)tappedView {
    NSUInteger index = tappedView.tag - kTagTabBase;
    NSAssert(index < [self.viewControllers count], @"invalid tapped view");
    
    [self _makeTabViewCurrent:tappedView];
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
    [self.view addSubview:tabsContainerView];
    
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
        tabView.titleLabel.font = self.style.unselectedTitleFont;
        tabView.delegate = self;
        
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
    
    // Adjust drawer toolbar to be set to the correct origin depending on screen size
    [self.toolbarDrawer setFrame:CGRectMake(0, self.view.frame.size.height - self.toolbarDrawer.frame.size.height, self.toolbarDrawer.frame.size.width, self.toolbarDrawer.frame.size.height)];
    [self.view bringSubviewToFront:self.toolbarDrawer];

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
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)recordButtonAction:(id)sender {
    SCCamViewController *viewController = [[SCCamViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentModalViewController:navController animated:YES];
}

- (IBAction)noteButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(IBAction)chooseFromLibrary:(id)sender {
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
    [self dismissModalViewControllerAnimated:YES];
    
    // Create Recording
    //TODO
    Recording *recording = nil;
    
    // Upload
    UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
    [viewController setRecordingToUpload:recording];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

@end
