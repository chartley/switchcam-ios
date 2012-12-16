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
        // Create Progress bar and label
        self.statusBarProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.statusBarProgressView setFrame:CGRectMake(0, 0, 320, 20)];
        
        self.statusBarProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
        
        // Custom track
        UIImage *progressImage = [[UIImage imageNamed:@"bg-statusbar-uploading"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
        UIImage *trackImage = [[UIImage imageNamed:@"bg-statusbar-grey"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
        [self.statusBarProgressView setProgressImage:progressImage];
        [self.statusBarProgressView setTrackImage:trackImage];
        
        // Set Font / Color
        [self.statusBarProgressLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
        [self.statusBarProgressLabel setTextColor:[UIColor whiteColor]];
        [self.statusBarProgressLabel setShadowColor:[UIColor blackColor]];
        [self.statusBarProgressLabel setShadowOffset:CGSizeMake(0, -1)];
        [self.statusBarProgressLabel setTextAlignment:UITextAlignmentRight];
        
        // Create Toast bar and label
        self.toastBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        [self.toastBackgroundImageView setImage:[UIImage imageNamed:@"bg-statusbar-green"]];
        
        self.toastLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        
        // Set Font / Color
        [self.toastLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
        [self.toastLabel setTextColor:[UIColor whiteColor]];
        [self.toastLabel setShadowColor:[UIColor blackColor]];
        [self.toastLabel setShadowOffset:CGSizeMake(0, -1)];
        [self.toastLabel setTextAlignment:UITextAlignmentCenter];
        
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

- (void)showProgressView {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.statusBarProgressLabel setAlpha:1.0];
        [self.statusBarProgressView setAlpha:1.0];
    } completion:^(BOOL finished) {
    }];
}

- (void)hideProgressView {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.statusBarProgressLabel setAlpha:0.0];
        [self.statusBarProgressView setAlpha:0.0];
    } completion:^(BOOL finished) {
    }];
}

- (void)updateProgressLabelWithAmount:(float)progress {
    [self.statusBarProgressView setProgress:progress];
    
    NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"%f% Uploaded", @""), (progress * 100)];
    [self.statusBarProgressLabel setText:progressString];
}

- (void)showToastWithMessage:(NSString*)message {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.toastBackgroundImageView setAlpha:1.0];
        [self.toastLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideToastMessage) withObject:nil afterDelay:kToastDisplayTime];
    }];
}

- (void)hideToastMessage {
    [UIView animateWithDuration:1.0 animations:^(){
        [self.toastBackgroundImageView setAlpha:0.0];
        [self.toastLabel setAlpha:0.0];
    } completion:^(BOOL finished) {
        
    }];
}

@end