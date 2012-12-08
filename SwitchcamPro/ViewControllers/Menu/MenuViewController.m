//
//  MenuViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/3/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "MenuViewController.h"
#import "MenuItemCell.h"
#import "MyEventsViewController.h"
#import "FindEventsViewController.h"
#import "SettingsViewController.h"
#import "AboutViewController.h"

@interface MenuViewController()
@property (nonatomic, strong) NSArray *menuItems;
@end

@implementation MenuViewController
@synthesize menuItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.menuItems = [NSArray arrayWithObjects:@"My Events", @"Find Events", @"Settings", @"About", @"Sign Out", nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.slidingViewController setAnchorRightRevealAmount:280.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuItemCell *cell = (MenuItemCell *)[tableView dequeueReusableCellWithIdentifier:kMenuItemCellIdentifier];
    
    
    if (cell == nil) {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"MenuItemCell" owner:self options:nil];
        cell = [nibArray objectAtIndex:0];
        
        // Set Custom Font
        [cell.leftLabel setFont:[UIFont fontWithName:@"SourceSansPro-Bold" size:18]];
        [cell.leftLabel setShadowColor:[UIColor blackColor]];
        [cell.leftLabel setShadowOffset:CGSizeMake(0, 1)];
    }
    
    cell.leftLabel.text = [self.menuItems objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *newTopViewController = nil;
    
    switch (indexPath.row) {
        case 0:
            newTopViewController = [[MyEventsViewController alloc] init];
            break;
            
        case 1:
            newTopViewController = [[FindEventsViewController alloc] init];
            break;
            
        case 2:
            newTopViewController = [[SettingsViewController alloc] init];
            break;
            
        case 3:
            newTopViewController = [[AboutViewController alloc] init];
            break;
            
        case 4:
            newTopViewController = [[MyEventsViewController alloc] init];
            break;
            
        default:
            break;
    }
    
    if (newTopViewController != nil) {
        [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
        }];
    }
}

@end
