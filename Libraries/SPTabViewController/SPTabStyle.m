#import "SPTabStyle.h"
#import "SPConstants.h"

@implementation SPTabStyle

@synthesize tabHeight;
@synthesize tabsViewHeight;
@synthesize tabBarHeight;
@synthesize overlapAsPercentageOfTabWidth;
@synthesize shadowRadius;
@synthesize selectedTabColor;
@synthesize selectedTitleTextColor;
@synthesize selectedTitleFont;
@synthesize selectedTitleShadowColor;
@synthesize selectedTitleShadowOffset;
@synthesize unselectedTabColor;
@synthesize unselectedTitleTextColor;
@synthesize unselectedTitleFont;
@synthesize unselectedTitleShadowColor;
@synthesize unselectedTitleShadowOffset;

- (id)init {
  if ((self = [super init])) {
    self.tabsViewHeight = 50;
    self.tabHeight = 50;
    self.tabBarHeight = 0;
    self.overlapAsPercentageOfTabWidth = 0;
    self.shadowRadius = 3;

    self.selectedTabColor = RGBA(36, 38, 39, 1);
    self.selectedTitleFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:15];
    self.selectedTitleTextColor = RGBA(233, 110, 62, 1);
    self.selectedTitleShadowOffset = CGSizeMake(0, -1);
    self.selectedTitleShadowColor = [UIColor blackColor];

    self.unselectedTabColor = RGBA(30, 32, 32, 1);
    self.unselectedTitleFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:15];
    self.unselectedTitleTextColor = [UIColor whiteColor];
    self.unselectedTitleShadowOffset = CGSizeMake(0, -1);
    self.unselectedTitleShadowColor = [UIColor blackColor];
  }

  return self;
}

- (void)setTabHeight:(NSUInteger)newTabHeight {
  tabHeight = MIN(tabsViewHeight, newTabHeight);
}

+ (SPTabStyle *)defaultStyle {
  return [[[SPTabStyle alloc] init] autorelease];
}

@end
