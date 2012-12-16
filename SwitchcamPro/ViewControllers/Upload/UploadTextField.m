//
//  UploadTextField.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/15/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "UploadTextField.h"
#import "SPConstants.h"

@implementation UploadTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) drawPlaceholderInRect:(CGRect)rect {
    UIColor *placeholderColor = RGBA(105, 105, 105, 1);
    [placeholderColor setFill];
    [[self placeholder] drawInRect:rect withFont:[UIFont fontWithName:@"SourceSansPro-Light" size:17]];
}

@end
