//
//  SPWindow.m
//  SwitchcamPro
//
//  Created by William Ketterer on 2/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//
//  This class will dismiss keyboard whenever a view that isn't the first responder is touched
//

#import "SPWindow.h"

@implementation SPWindow {
    UIView *currentFirstResponder_;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self startObservingFirstResponder];
}

- (void)dealloc {
    [self stopObservingFirstResponder];
}

- (void)startObservingFirstResponder {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(observeBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [center addObserver:self selector:@selector(observeEndEditing:) name:UITextFieldTextDidEndEditingNotification object:nil];
    [center addObserver:self selector:@selector(observeBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [center addObserver:self selector:@selector(observeEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
}

- (void)stopObservingFirstResponder {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [center removeObserver:self name:UITextFieldTextDidEndEditingNotification object:nil];
    [center removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [center removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
}

- (void)observeBeginEditing:(NSNotification *)note {
    currentFirstResponder_ = note.object;
}

- (void)observeEndEditing:(NSNotification *)note {
    if (currentFirstResponder_ == note.object) {
        currentFirstResponder_ = nil;
    }
}

- (void)sendEvent:(UIEvent *)event {
    [self adjustFirstResponderForEvent:event];
    [super sendEvent:event];
}

- (void)adjustFirstResponderForEvent:(UIEvent *)event {
    if (currentFirstResponder_
        && ![self eventContainsTouchInFirstResponder:event]
        && [self eventContainsNewTouchInNonresponder:event]) {
        [currentFirstResponder_ resignFirstResponder];
    }
}

- (BOOL)eventContainsTouchInFirstResponder:(UIEvent *)event {
    for (UITouch *touch in [event touchesForWindow:self]) {
        if (touch.view == currentFirstResponder_)
            return YES;
    }
    return NO;
}

- (BOOL)eventContainsNewTouchInNonresponder:(UIEvent *)event {
    for (UITouch *touch in [event touchesForWindow:self]) {
        if (touch.phase == UITouchPhaseBegan && ![touch.view canBecomeFirstResponder] && ![touch.view isKindOfClass:[UIButton class]])
            return YES;
    }
    return NO;
}
@end
