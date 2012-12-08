#import "SPTabsViewController.h"
#import "SPTabsFooterView.h"
#import "SPTabStyle.h"
#import "SPTabsView.h"

enum { kTagTabBase = 100 };

@interface SPTabsViewController ()

@property (nonatomic, retain) NSArray *viewControllers;
@property (nonatomic, assign, readwrite) UIView *contentView;
@property (nonatomic, retain) SPTabsView *tabsContainerView;
@property (nonatomic, retain) SPTabsFooterView *footerView;

@end

@implementation SPTabsViewController

@synthesize delegate, style, viewControllers, contentView,
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

- (void)dealloc {
  self.style = nil;
  self.viewControllers = nil;
  self.tabsContainerView = nil;
  self.footerView = nil;

  [super dealloc];
}

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

  [self.contentView removeFromSuperview];
  self.contentView = viewController.view;
  
  self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  self.contentView.frame = CGRectMake(0, self.tabsContainerView.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
  
  [self.view addSubview:self.contentView];

  [self _reconfigureTabs];
}

- (void)didTapTabView:(SPTabView *)tappedView {
  NSUInteger index = tappedView.tag - kTagTabBase;
  NSAssert(index < [self.viewControllers count], @"invalid tapped view");

  UIViewController *viewController = [self.viewControllers objectAtIndex:index];

  if ([self.delegate respondsToSelector:@selector(shouldMakeTabCurrentAtIndex:controller:tabBarController:)])
    if (![self.delegate shouldMakeTabCurrentAtIndex:index controller:viewController tabBarController:self])
      return;

  [self _makeTabViewCurrent:tappedView];

  if ([self.delegate respondsToSelector:@selector(didMakeTabCurrentAtIndex:controller:tabBarController:)])
    [self.delegate didMakeTabCurrentAtIndex:index controller:viewController tabBarController:self];
}

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // The view that contains the tab views is located across the top.
    
    CGRect tabsViewFrame = CGRectMake(0, 200, self.view.frame.size.width, self.style.tabsViewHeight);
    self.tabsContainerView = [[[SPTabsView alloc] initWithFrame:tabsViewFrame] autorelease];
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
    
    self.footerView = [[[SPTabsFooterView alloc] initWithFrame:footerFrame] autorelease];
    self.footerView.backgroundColor = [UIColor clearColor];
    self.footerView.style = self.style;
    self.footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.tabsContainerView addSubview:footerView];
    [self.tabsContainerView bringSubviewToFront:footerView];
    
    [self _makeTabViewCurrent:[self.tabsContainerView.tabViews objectAtIndex:0]];

    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationMaskPortrait);
}

@end
