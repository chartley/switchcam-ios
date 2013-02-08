//
//  AboutViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "AboutViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "SPConstants.h"
#import "TermsViewController.h"

#define kSwitchcamButtonTag 0
#define kTwitterButtonTag 1
#define kFacebookButtonTag 2
#define kPrivacyTag 3
#define kTermsTag 4

@interface AboutViewController ()

@end

@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    // Set Content Size
    [self.scrollView setContentSize:CGSizeMake(320, 580)];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.switchcamButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.switchcamButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
    
    // Set Button Image
    UIImage *twitterButtonImage = [[UIImage imageNamed:@"btn-twitter-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *twitterHighlightButtonImage = [[UIImage imageNamed:@"btn-twitter-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.twitterButton setBackgroundImage:twitterButtonImage forState:UIControlStateNormal];
    [self.twitterButton setBackgroundImage:twitterHighlightButtonImage forState:UIControlStateSelected];
    
    // Set Button Image
    UIImage *facebookButtonImage = [[UIImage imageNamed:@"btn-fb-lg"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set Button Image
    UIImage *facebookHighlightButtonImage = [[UIImage imageNamed:@"btn-fb-lg-pressed"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.facebookButton setBackgroundImage:facebookButtonImage forState:UIControlStateNormal];
    [self.facebookButton setBackgroundImage:facebookHighlightButtonImage forState:UIControlStateSelected];
    
    // Set Font / Color
    [self.switchcamButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.switchcamButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.switchcamButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
    [self.switchcamButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.twitterButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.twitterButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.twitterButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
    [self.twitterButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.facebookButton.titleLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:17]];
    [self.facebookButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.facebookButton.titleLabel setShadowColor:RGBA(0,0,0,0.4)];
    [self.facebookButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.aboutLabel setFont:[UIFont fontWithName:@"SourceSansPro-Semibold" size:15]];
    [self.aboutLabel setTextColor:[UIColor whiteColor]];
    [self.aboutLabel setShadowColor:[UIColor blackColor]];
    [self.aboutLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.navigationItem setTitle:NSLocalizedString(@"About", @"")];
    
    // Menu Button and Location Button
    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setFrame:CGRectMake(0, 0, 30, 30)];
    [menuButton setImage:[UIImage imageNamed:@"btn-sidemenu"] forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(menuButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    [self.navigationItem setLeftBarButtonItem:menuBarButtonItem];
    [self.navigationItem setHidesBackButton:YES];
    
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setObject:(id)[RGBA(235, 112, 62, 1) CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
    
    
    
    // Privacy Policy
    TTTAttributedLabel *privacyPolicyLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 420, 320, 30)];
    privacyPolicyLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:17];
    privacyPolicyLabel.textColor = RGBA(235, 112, 62, 1);
    privacyPolicyLabel.textAlignment = NSTextAlignmentCenter;
    privacyPolicyLabel.backgroundColor = [UIColor clearColor];
    privacyPolicyLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    privacyPolicyLabel.numberOfLines = 1;
    privacyPolicyLabel.delegate = self;
    privacyPolicyLabel.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    
    NSString *privacyPolicyText = NSLocalizedString(@"Privacy Policy", @"");
    [privacyPolicyLabel setText:privacyPolicyText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange underlineRange = [[mutableAttributedString string] rangeOfString:NSLocalizedString(@"Privacy Policy", @"") options:NSCaseInsensitiveSearch];
        
        // Core Text APIs use C functions without a direct bridge to UIFont. See Apple's "Core Text Programming Guide" to learn how to configure string attributes.
        UIFont *customFont = [UIFont fontWithName:@"SourceSansPro-Bold" size:17];
        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)customFont.fontName, customFont.pointSize, NULL);
        if (font) {
            [mutableAttributedString addAttribute:@"TTTUnderlineAttribute" value:[NSNumber numberWithBool:YES] range:underlineRange];
            CFRelease(font);
        }
        
        return mutableAttributedString;
    }];
    
    NSRange privacyLinkRange = [privacyPolicyText rangeOfString:NSLocalizedString(@"Privacy Policy", @"") options:NSCaseInsensitiveSearch];
    [privacyPolicyLabel addLinkToURL:[NSURL URLWithString:@"http://switchcam.com/legal/privacy"] withRange:privacyLinkRange];
    
    // Terms of Service
    TTTAttributedLabel *termsOfServiceLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 460, 320, 30)];
    termsOfServiceLabel.font = [UIFont fontWithName:@"SourceSansPro-Bold" size:17];
    termsOfServiceLabel.textAlignment = NSTextAlignmentCenter;
    termsOfServiceLabel.textColor = RGBA(235, 112, 62, 1);
    termsOfServiceLabel.backgroundColor = [UIColor clearColor];
    termsOfServiceLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    termsOfServiceLabel.numberOfLines = 1;
    termsOfServiceLabel.delegate = self;
    termsOfServiceLabel.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    
    NSString *termsOfServiceText = NSLocalizedString(@"Terms & Conditions", @"");
    [termsOfServiceLabel setText:termsOfServiceText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange underlineRange = [[mutableAttributedString string] rangeOfString:NSLocalizedString(@"Terms & Conditions", @"") options:NSCaseInsensitiveSearch];
        
        // Core Text APIs use C functions without a direct bridge to UIFont. See Apple's "Core Text Programming Guide" to learn how to configure string attributes.
        UIFont *customFont = [UIFont fontWithName:@"SourceSansPro-Bold" size:17];
        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)customFont.fontName, customFont.pointSize, NULL);
        if (font) {
            [mutableAttributedString addAttribute:@"TTTUnderlineAttribute" value:[NSNumber numberWithBool:YES] range:underlineRange];
            CFRelease(font);
        }
        
        return mutableAttributedString;
    }];
    
    NSRange termsLinkRange = [termsOfServiceText rangeOfString:NSLocalizedString(@"Terms & Conditions", @"") options:NSCaseInsensitiveSearch];
    [termsOfServiceLabel addLinkToURL:[NSURL URLWithString:@"http://switchcam.com/legal/terms"] withRange:termsLinkRange];
    
    // Center
    [privacyPolicyLabel sizeToFit];
    [termsOfServiceLabel sizeToFit];
    
    [privacyPolicyLabel setCenter:CGPointMake(160, 435)];
    [termsOfServiceLabel setCenter:CGPointMake(160, 465)];
    
    [self.scrollView addSubview:privacyPolicyLabel];
    [self.scrollView addSubview:termsOfServiceLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // shadowPath, shadowOffset, and rotation is handled by ECSlidingViewController.
    // You just need to set the opacity, radius, and color.
    self.navigationController.view.layer.shadowOpacity = 0.75f;
    self.navigationController.view.layer.shadowRadius = 10.0f;
    self.navigationController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)switchcamButtonAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leaving app", @"") message:NSLocalizedString(@"Pressing OK will open this link in Safari", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    [alertView setTag:kSwitchcamButtonTag];
    [alertView show];
}

- (IBAction)twitterButtonAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leaving app", @"") message:NSLocalizedString(@"Pressing OK will open this link in Safari", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    [alertView setTag:kSwitchcamButtonTag];
    [alertView show];
}

- (IBAction)facebookButtonAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leaving app", @"") message:NSLocalizedString(@"Pressing OK will open this link in Safari", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    [alertView setTag:kSwitchcamButtonTag];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Canceled
    } else {
        // Launch Link
        NSURL *urlToLaunch = nil;
        if (alertView.tag == kSwitchcamButtonTag) {
            // Switchcam.com
            urlToLaunch = [NSURL URLWithString:@"http://www.switchcam.com"];
        } else if (alertView.tag == kTwitterButtonTag) {
            // Twitter
            urlToLaunch = [NSURL URLWithString:@"http://www.twitter.com/switchcam"];
        } else if (alertView.tag == kFacebookButtonTag) {
            // Facebook
            urlToLaunch = [NSURL URLWithString:@"http://www.facebook.com/switchcam"];
        } else if (alertView.tag == kPrivacyTag) {
            // Privacy
            urlToLaunch = [NSURL URLWithString:@"http://switchcam.com/legal/privacy"];
        } else if (alertView.tag == kTermsTag) {
            // Terms
            urlToLaunch = [NSURL URLWithString:@"http://switchcam.com/legal/terms"];
        }
        
        [[UIApplication sharedApplication] openURL:urlToLaunch];
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    TermsViewController *viewController = [[TermsViewController alloc] init];
    [viewController setHasAccepted:YES];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
