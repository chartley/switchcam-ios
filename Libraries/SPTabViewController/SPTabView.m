#import "SPTabView.h"
#import "SPTabStyle.h"

// It's best to reference the visual guide to the path of the tab.
// See the Docs/tab-analysis.png file.
// The view width is divided into 4 horizontal sections.
// Each section is divided by a 20 x 16 grid.
// The control points were visually laid out atop this grid.

#define kHorizontalSectionCount           4
#define kGridWidthInSection               16
#define kGridHeight                       20
#define kTabHeightInGridUnits             20
#define kBottomControlPointDXInGridUnits  8
#define kBottomControlPointDYInGridUnits  1
#define kTopControlPointDXInGridUnits     1

static inline CGFloat radians(CGFloat degrees) {
  return degrees * M_PI/180;
}

@interface SPTabView ()

@property (nonatomic, retain, readwrite) UILabel *titleLabel;

- (CGFloat)_sectionWidth;
- (CGSize)_gridSize;
- (CGRect)_tabRect;

@end

@implementation SPTabView

@synthesize titleLabel, delegate, selected, style;

- (id)initWithFrame:(CGRect)frame title:(NSString *)title {
  if ((self = [super initWithFrame:frame])) {
    self.userInteractionEnabled = YES;

    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.style = [SPTabStyle defaultStyle];

    CGRect labelFrame = [self _tabRect];
    self.titleLabel = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
    self.titleLabel.text = title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = self.style.unselectedTitleTextColor;
    self.titleLabel.shadowColor = self.style.unselectedTitleShadowColor;
    self.titleLabel.shadowOffset = self.style.unselectedTitleShadowOffset;
    [self addSubview:self.titleLabel];

    [self addGestureRecognizer:[[[UITapGestureRecognizer alloc]
                                 initWithTarget:self
                                 action:@selector(_onTap:)] autorelease]];
  }

  return self;
}

- (void)_configureTitleLabel {
    if (self.selected) {
        self.titleLabel.textColor    = self.style.selectedTitleTextColor;
        self.titleLabel.shadowColor  = self.style.selectedTitleShadowColor;
        self.titleLabel.shadowOffset = self.style.selectedTitleShadowOffset;
        self.titleLabel.font         = self.style.selectedTitleFont;
    } else {
        self.titleLabel.textColor    = self.style.unselectedTitleTextColor;
        self.titleLabel.shadowColor  = self.style.unselectedTitleShadowColor;
        self.titleLabel.shadowOffset = self.style.unselectedTitleShadowOffset;
        self.titleLabel.font         = self.style.unselectedTitleFont;
    }
}

- (void)_onTap:(UIGestureRecognizer *)gesture {
  UITapGestureRecognizer *tapGesture = (UITapGestureRecognizer *) gesture;
  if (tapGesture.state == UIGestureRecognizerStateEnded) {
    if ([self.delegate respondsToSelector:@selector(didTapTabView:)]) {
      [self.delegate didTapTabView:self];
    }
  }
}

- (CGFloat)_sectionWidth {
  return self.frame.size.width / kHorizontalSectionCount;
}

- (CGSize)_gridSize {
  return CGSizeMake([self _sectionWidth] / kGridWidthInSection,
                    self.frame.size.height / kGridHeight);
}

- (CGRect)_tabRect {
  CGFloat tabHeight = [self _gridSize].height * kTabHeightInGridUnits;
  return CGRectMake(0, self.frame.size.height - tabHeight + 0.5,
                    self.frame.size.width - 0.5, tabHeight);
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorRef tabColor = (self.selected
                           ? self.style.selectedTabColor.CGColor
                           : self.style.unselectedTabColor.CGColor);
    
    // Fill with current tab color
    CGContextSetFillColorWithColor(context, tabColor);
    CGContextSetRGBStrokeColor(context, (255.0/255.0), (255.0/255.0), (255.0/255.0), self.selected?0.0:0.2);
    CGContextSetLineWidth(context, 2);
    CGContextFillRect(context, [self _tabRect]);
    
    
    [self _configureTitleLabel];
}

- (void)setSelected:(BOOL)isSelected {
  selected = isSelected;
  [self setNeedsDisplay];
}

- (void)dealloc {
  self.titleLabel = nil;
  self.style = nil;

  [super dealloc];
}

@end
