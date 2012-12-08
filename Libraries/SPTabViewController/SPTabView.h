#import <UIKit/UIKit.h>

@class SPTabView;
@class SPTabStyle;

@protocol SPTabViewDelegate <NSObject>
- (void)didTapTabView:(SPTabView *)tabView;
@end

@interface SPTabView : UIView

@property (nonatomic, retain, readonly) UILabel *titleLabel;
@property (nonatomic, assign) id <SPTabViewDelegate> delegate;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, retain) SPTabStyle *style;

- (id)initWithFrame:(CGRect)frame title:(NSString *)title;

@end
