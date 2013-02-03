//
//  StatusBarToastAndProgressView.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/16/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "StatusBarToastAndProgressView.h"

#define kToastDisplayTime 5

@interface StatusBarToastAndProgressView ()

@property (strong, nonatomic) UIProgressView *statusBarProgressView;
@property (strong, nonatomic) UILabel *statusBarProgressLabel;

@property (strong, nonatomic) UIImageView *toastBackgroundImageView;
@property (strong, nonatomic) UILabel *toastLabel;

@end

@implementation StatusBarToastAndProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.windowLevel = UIWindowLevelStatusBar;
        
        [self setBackgroundColor:[UIColor clearColor]];
        [self setUserInteractionEnabled:NO];
        
        // Create Progress bar and label
        self.statusBarProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.statusBarProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
        
        // Custom track
        UIImage *progressImage = [[UIImage imageNamed:@"bg-statusbar-uploading"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
        UIImage *trackImage = [[UIImage imageNamed:@"bg-statusbar-grey"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
        [self.statusBarProgressView setProgressImage:progressImage];
        [self.statusBarProgressView setTrackImage:trackImage];
        
        // Set frame after setting images
        [self.statusBarProgressView setFrame:CGRectMake(0, 0, 320, 20)];
        [self.statusBarProgressView setUserInteractionEnabled:NO];
        
        // Set Font / Color
        [self.statusBarProgressLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
        [self.statusBarProgressLabel setBackgroundColor:[UIColor clearColor]];
        [self.statusBarProgressLabel setTextColor:[UIColor whiteColor]];
        [self.statusBarProgressLabel setShadowColor:[UIColor blackColor]];
        [self.statusBarProgressLabel setShadowOffset:CGSizeMake(0, -1)];
        [self.statusBarProgressLabel setTextAlignment:NSTextAlignmentRight];
        [self.statusBarProgressLabel setText:NSLocalizedString(@"0% Uploaded", @"")];
        [self.statusBarProgressLabel setUserInteractionEnabled:NO];
        
        // Create Toast bar and label
        self.toastBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        [self.toastBackgroundImageView setImage:[UIImage imageNamed:@"bg-statusbar-green"]];
        [self.toastBackgroundImageView setUserInteractionEnabled:NO];
        
        self.toastLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        
        // Set Font / Color
        [self.toastLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
        [self.toastLabel setTextColor:[UIColor whiteColor]];
        [self.toastLabel setShadowColor:[UIColor blackColor]];
        [self.toastLabel setShadowOffset:CGSizeMake(0, -1)];
        [self.toastLabel setTextAlignment:NSTextAlignmentCenter];
        [self.toastLabel setBackgroundColor:[UIColor clearColor]];
        [self.toastLabel setUserInteractionEnabled:NO];
        
        // Hide all views
        [self.statusBarProgressLabel setAlpha:0.0];
        [self.statusBarProgressView setAlpha:0.0];
        [self.toastBackgroundImageView setAlpha:0.0];
        [self.toastLabel setAlpha:0.0];
        
        [self addSubview:self.statusBarProgressView];
        [self addSubview:self.statusBarProgressLabel];
        [self addSubview:self.toastBackgroundImageView];
        [self addSubview:self.toastLabel];
    }
    return self;
}

#pragma mark - Methods

- (void)showProgressView {
    [self performSelectorOnMainThread:@selector(showProgressViewAnimation) withObject:nil waitUntilDone:NO];
}

- (void)hideProgressView {
    [self performSelectorOnMainThread:@selector(hideProgressViewAnimation) withObject:nil waitUntilDone:NO];
}

- (void)updateProgressLabelWithAmount:(float)progress {
    [self performSelectorOnMainThread:@selector(updateProgressLabelAnimationWithAmount:) withObject:[NSNumber numberWithFloat:progress] waitUntilDone:NO];
}

- (void)showToastWithMessage:(NSString*)message {
    [self performSelectorOnMainThread:@selector(showToastAnimationWithMessage:) withObject:message waitUntilDone:NO];
}

- (void)hideToastMessage {
    [self performSelectorOnMainThread:@selector(hideToastMessageAnimation) withObject:nil waitUntilDone:NO];
}

#pragma mark - Animations

- (void)showProgressViewAnimation {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.statusBarProgressLabel setAlpha:1.0];
        [self.statusBarProgressView setAlpha:1.0];
    } completion:^(BOOL finished) {
    }];
}

- (void)hideProgressViewAnimation {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.statusBarProgressLabel setAlpha:0.0];
        [self.statusBarProgressView setAlpha:0.0];
    } completion:^(BOOL finished) {
    }];
}

- (void)updateProgressLabelAnimationWithAmount:(NSNumber*)progressNumber {
    float progress = [progressNumber floatValue];
    [self.statusBarProgressView setProgress:(progress/100)];
    
    NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"%d%% Uploaded", @""), [progressNumber intValue]];
    [self.statusBarProgressLabel setText:progressString];
}

- (void)showToastAnimationWithMessage:(NSString*)message {
    [self.toastLabel setText:message];
    [UIView animateWithDuration:1.0 animations:^(){
        [self.toastBackgroundImageView setAlpha:1.0];
        [self.toastLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideToastMessage) withObject:nil afterDelay:kToastDisplayTime];
    }];
}

- (void)hideToastMessageAnimation {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.toastBackgroundImageView setAlpha:0.0];
        [self.toastLabel setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
}

@end
