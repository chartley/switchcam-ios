//
//  SettingsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/5/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SettingsViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "LabelSwitchCell.h"
#import "ProfileCell.h"
#import "ButtonCell.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // shadowPath, shadowOffset, and rotation is handled by ECSlidingViewController.
    // You just need to set the opacity, radius, and color.
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

#pragma mark - IBActions

- (IBAction)menuButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

#pragma mark - Helper Methods

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    //TODO Tag switches
    switch (indexPath.row) {
        case 0:
        {
            LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
            [labelSwitchCell.leftLabel setText:NSLocalizedString(@"Upload over 3G", @"")];
            labelSwitchCell.staySignedInSwitch = labelSwitchCell.staySignedInSwitch;
            [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        }
            
        case 1:
        {
            LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
            labelSwitchCell.staySignedInSwitch = labelSwitchCell.staySignedInSwitch;
            [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 2:
        {
            LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
            labelSwitchCell.staySignedInSwitch = labelSwitchCell.staySignedInSwitch;
            [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 3:
        {
            LabelSwitchCell *labelSwitchCell = (LabelSwitchCell *)cell;
            labelSwitchCell.staySignedInSwitch = labelSwitchCell.staySignedInSwitch;
            [labelSwitchCell.staySignedInSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 4;
    } else {
        return 2;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelSwitchCellIdentifier];
            break;
        }
            
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:kProfileCellIdentifier];
                    break;
                }
                case 1:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:kButtonCellIdentifier];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
    
    if (cell == nil) {
        switch (indexPath.section) {
            case 0:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelSwitchCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                break;
            }
                
            case 1:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ProfileCell" owner:self options:nil];
                        cell = [nibArray objectAtIndex:0];
                        break;
                    }
                    case 1:
                    {
                        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ButtonCell" owner:self options:nil];
                        cell = [nibArray objectAtIndex:0];
                        break;
                    }
                    default:
                        break;
                }
                break;
            }
            default:
                break;
        }
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

@end
