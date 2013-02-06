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
#import "MenuPendingUploadDSD.h"
#import "AppDelegate.h"
#import "SPNavigationController.h"

@interface MenuViewController()
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) MenuPendingUploadDSD *pendingDataSourceDelegate;
@end

@implementation MenuViewController
@synthesize menuItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.menuItems = [NSArray arrayWithObjects:@"My Shoots", @"Find Shoots", @"Settings", @"About", @"Sign Out", nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    [self.slidingViewController setAnchorRightRevealAmount:280.0f];
    self.slidingViewController.underLeftWidthLayout = ECFullWidth;
    
    self.pendingDataSourceDelegate = [[MenuPendingUploadDSD alloc] init];
    [self.pendingDataSourceDelegate setMenuViewController:self];
    [self.pendingUploadTableView setDataSource:self.pendingDataSourceDelegate];
    [self.pendingUploadTableView setDelegate:self.pendingDataSourceDelegate];
    [self.pendingUploadTableView setTableFooterView:[[UIView alloc] init]];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.pendingDataSourceDelegate refreshUploads];
    [self.pendingUploadTableView reloadData];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Menu TableView Data Source / Delegate

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
        {
            MyEventsViewController *myEventsViewController = [[MyEventsViewController alloc] initWithNibName:@"MyEventsViewController" bundle:nil];
            SPNavigationController *navController = [[SPNavigationController alloc] initWithRootViewController:myEventsViewController];
            newTopViewController = navController;
            break;
        }
            
        case 1:
        {
            FindEventsViewController *findEventsViewController = [[FindEventsViewController alloc] initWithNibName:@"FindEventsViewController" bundle:nil];
            SPNavigationController *navController = [[SPNavigationController alloc] initWithRootViewController:findEventsViewController];
            newTopViewController = navController;
        }
            break;
            
        case 2:
        {
            SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
            SPNavigationController *navController = [[SPNavigationController alloc] initWithRootViewController:settingsViewController];
            newTopViewController = navController;
        }
            break;
            
        case 3:
        {
            AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
            SPNavigationController *navController = [[SPNavigationController alloc] initWithRootViewController:aboutViewController];
            newTopViewController = navController;
        }
            break;
            
        case 4:
        {
            // Sign out
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate logoutUser];
            break;
        }
            
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
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
