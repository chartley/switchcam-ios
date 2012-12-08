#import <UIKit/UIKit.h>

@class SPTabStyle;

// Adds some space under the tabs so that the tabs don't jut right up atop the content view.

@interface SPTabsFooterView : UIView

@property (nonatomic, retain) SPTabStyle *style;

@end
