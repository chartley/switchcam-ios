#import <UIKit/UIKit.h>
#import "SPTabView.h"

@class SPTabsViewController;
@class SPTabsFooterView;
@class SPTabStyle;
@class SPTabsView;

@protocol SPTabsViewControllerDelegate <NSObject>
@optional

- (BOOL)shouldMakeTabCurrentAtIndex:(NSUInteger)index
                         controller:(UIViewController *)viewController
                   tabBarController:(SPTabsViewController *)tabBarController;

- (void)didMakeTabCurrentAtIndex:(NSUInteger)index
                      controller:(UIViewController *)viewController
                tabBarController:(SPTabsViewController *)tabBarController;

@end

@interface SPTabsViewController : UIViewController <SPTabViewDelegate> {
  NSArray *viewControllers;
  UIView *contentView;
  SPTabsView *tabsContainerView;
  SPTabsFooterView *footerView;
  SPTabStyle *tabStyle;
  NSUInteger currentTabIndex;
  id <SPTabsViewControllerDelegate> delegate;
}

@property (nonatomic, assign) id <SPTabsViewControllerDelegate> delegate;
@property (nonatomic, assign, readonly) UIView *contentView;
@property (nonatomic, retain) SPTabStyle *style;

- (id)initWithViewControllers:(NSArray *)viewControllers
                        style:(SPTabStyle *)style;

@end
