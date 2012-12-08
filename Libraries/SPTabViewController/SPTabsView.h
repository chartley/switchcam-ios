#import <UIKit/UIKit.h>

@class SPTabStyle;

@interface SPTabsView : UIView {
  NSArray *tabViews;
  SPTabStyle *style;
}

@property (nonatomic, retain) NSArray *tabViews;
@property (nonatomic, retain) SPTabStyle *style;


@end
