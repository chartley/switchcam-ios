//
//  EventInfoViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "EventInfoViewController.h"

@interface EventInfoViewController ()

@end

@implementation EventInfoViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)imGoingButtonAction:(id)sender {
    [self.goingDetailLabel setText:NSLocalizedString(@"We'll send you updates during the shoot and notify you when to start shooting.", @"")];
}

- (IBAction)imNotGoingButtonAction:(id)sender {
    [self.goingDetailLabel setText:NSLocalizedString(@"Bummer! Watch the activity feed during the event and we'll notify you when the final event is built!", @"")];
}

@end
