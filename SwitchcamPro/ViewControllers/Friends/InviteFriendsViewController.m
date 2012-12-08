//
//  InviteFriendsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "InviteFriendsViewController.h"
#import "UILocalizedIndexedCollation+Util.h"

@interface InviteFriendsViewController ()

@property (strong, nonatomic) NSArray *facebookFriends;

@end

@implementation InviteFriendsViewController

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
    
    // Get list of friends
    [[FBRequest requestForGraphPath:@"me/friends"] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphObject> *result, NSError *error) {
        if (!error) {
            NSArray *listOfFriends = [result objectForKey:@"data"];
            self.facebookFriends = [UILocalizedIndexedCollation collateObjects:listOfFriends usingCollationStringSelector:@selector(name)];
            [self.selectFriendsTableView reloadData];
        }
    }];
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.facebookFriends count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.facebookFriends objectAtIndex:section] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.facebookFriends objectAtIndex:section] count]) {
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
    } else {
        return nil;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    id person = [[self.facebookFriends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [person name];
    //[cell.imageView setImageWithURL:[person profilePictureURL] placeholderImage:[UIImage imageNamed:@"fb.png"]];
    
    return cell;
}

@end
