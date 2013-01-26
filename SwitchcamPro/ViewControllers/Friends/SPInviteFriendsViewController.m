//
//  SPInviteFriendsViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 1/26/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <FacebookSDK/FBGraphObjectPagingLoader.h>
#import "SPInviteFriendsViewController.h"
#import "SPInviteFriendsTableDataSource.h"
#import "SPInviteFriendsTableSelection.h"

@interface SPInviteFriendsViewController ()

@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) NSString *searchText;
@property (nonatomic, retain) FBGraphObjectTableDataSource *dataSource;
@property (nonatomic, retain) FBGraphObjectTableSelection *selectionManager;
@property (nonatomic, retain) FBGraphObjectPagingLoader *loader;

@end

@implementation SPInviteFriendsViewController

@synthesize searchBar = _searchBar;
@synthesize searchText = _searchText;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        // Data Source
        FBGraphObjectTableDataSource *dataSource = [[SPInviteFriendsTableDataSource alloc]
                                                    init];
        dataSource.defaultPicture = [UIImage imageNamed:@"FacebookSDKResources.bundle/FBFriendPickerView/images/default.png"];
        dataSource.controllerDelegate = ((FBGraphObjectTableDataSource*)self.dataSource).controllerDelegate;
        dataSource.itemTitleSuffixEnabled = YES;
        dataSource.itemPicturesEnabled = YES;
        self.dataSource = dataSource;
        
        // Paging loader
        FBGraphObjectPagingLoader *loader = [[FBGraphObjectPagingLoader alloc] initWithDataSource:dataSource
                                                                pagingMode:FBGraphObjectPagingModeImmediate];
        loader.delegate = self.loader.delegate;
        self.loader = loader;
        
        // Selection Manager
        FBGraphObjectTableSelection *selectionManager = [[SPInviteFriendsTableSelection alloc]
                                                          initWithDataSource:dataSource];
        selectionManager.delegate = self.selectionManager.delegate;
        self.selectionManager = selectionManager;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    [self addSearchBarToFriendPickerView];
    self.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Add Back button
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setFrame:CGRectMake(0, 0, 30, 30)];
    [backButton setImage:[UIImage imageNamed:@"btn-cancel"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backBarButtonItem];
    [self.navigationItem setHidesBackButton:YES];
    
    if (self.isTagging) {
        [self.navigationItem setTitle:NSLocalizedString(@"Select friends to tag", @"")];
        
        // Add Check button
        UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [checkButton setFrame:CGRectMake(0, 0, 30, 30)];
        
        [checkButton setImage:[UIImage imageNamed:@"btn-check-inactive"] forState:UIControlStateNormal];
        UIBarButtonItem *checkBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:checkButton];
        [self.navigationItem setRightBarButtonItem:checkBarButtonItem];
    } else {
        [self.navigationItem setTitle:NSLocalizedString(@"Invite Friends", @"")];
        
        // Add Send button
        UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [sendButton setFrame:CGRectMake(0, 0, 60, 30)];
        
        // Set Button Image
        UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
        
        // Set Button Image
        UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
        
        // Set the background for any states you plan to use
        [sendButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [sendButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
        [sendButton setTitle:NSLocalizedString(@"Send", @"") forState:UIControlStateNormal];;
        UIBarButtonItem *sendBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
        [self.navigationItem setRightBarButtonItem:sendBarButtonItem];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.searchBar = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)checkButtonAction:(id)sender {
    // TODO Behavior needs to be defined
}

- (IBAction)sendButtonAction:(id)sender {
    // TODO Behavior needs to be defined
}

#pragma mark - Search

- (void)addSearchBarToFriendPickerView {
    if (self.searchBar == nil) {
        CGFloat searchBarHeight = 44.0;
        self.searchBar =
        [[UISearchBar alloc]
         initWithFrame:
         CGRectMake(0,0,
                    self.view.bounds.size.width,
                    searchBarHeight)];
        self.searchBar.autoresizingMask = self.searchBar.autoresizingMask |
        UIViewAutoresizingFlexibleWidth;
        self.searchBar.delegate = self;
        self.searchBar.showsCancelButton = YES;
        
        [self.canvasView addSubview:self.searchBar];
        CGRect newFrame = self.view.bounds;
        newFrame.size.height -= searchBarHeight;
        newFrame.origin.y = searchBarHeight;
        self.tableView.frame = newFrame;
        [self.tableView setBackgroundColor:[UIColor clearColor]];
    }
}

- (void) handleSearch:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.searchText = searchBar.text;
    [self updateView];
}

#pragma mark - UISearchBar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [self handleSearch:searchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    self.searchText = nil;
    [searchBar resignFirstResponder];
    [self updateView];
}

#pragma mark - FBGraphObjectViewControllerDelegate

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id<FBGraphUser>)user
{
    if (self.searchText && ![self.searchText isEqualToString:@""]) {
        NSRange result = [user.name
                          rangeOfString:self.searchText
                          options:NSCaseInsensitiveSearch];
        if (result.location != NSNotFound) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return YES;
    }
    return YES;
}

- (void)friendPickerViewControllerSelectionDidChange:
(FBFriendPickerViewController *)friendPicker {
    if ([friendPicker.selection count] > 0) {
        if (self.isTagging) {
            [self.navigationItem setTitle:NSLocalizedString(@"Select friends to tag", @"")];
            
            // Add Check button
            UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [checkButton setFrame:CGRectMake(0, 0, 30, 30)];
            
            [checkButton setImage:[UIImage imageNamed:@"btn-check-active"] forState:UIControlStateNormal];
            UIBarButtonItem *checkBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:checkButton];
            [self.navigationItem setRightBarButtonItem:checkBarButtonItem];
        } else {
            [self.navigationItem setTitle:NSLocalizedString(@"Invite Friends", @"")];
            
            // Add Send button
            UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [sendButton setFrame:CGRectMake(0, 0, 60, 30)];
            
            // Set Button Image
            UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
            
            // Set Button Image
            UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                             resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
            
            // Set the background for any states you plan to use
            [sendButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
            [sendButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
            [sendButton setTitle:NSLocalizedString(@"Send", @"") forState:UIControlStateNormal];
            [sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            UIBarButtonItem *sendBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
            [self.navigationItem setRightBarButtonItem:sendBarButtonItem];
        }
    } else {
        if (self.isTagging) {
            [self.navigationItem setTitle:NSLocalizedString(@"Select friends to tag", @"")];
            
            // Add Check button
            UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [checkButton setFrame:CGRectMake(0, 0, 30, 30)];
            
            [checkButton setImage:[UIImage imageNamed:@"btn-check-inactive"] forState:UIControlStateNormal];
            UIBarButtonItem *checkBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:checkButton];
            [self.navigationItem setRightBarButtonItem:checkBarButtonItem];
        } else {
            [self.navigationItem setTitle:NSLocalizedString(@"Invite Friends", @"")];
            
            // Add Send button
            UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [sendButton setFrame:CGRectMake(0, 0, 60, 30)];
            
            // Set Button Image
            UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
            
            // Set Button Image
            UIImage *highlightButtonImage = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                             resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
            
            // Set the background for any states you plan to use
            [sendButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
            [sendButton setBackgroundImage:highlightButtonImage forState:UIControlStateSelected];
            [sendButton setTitle:NSLocalizedString(@"Send", @"") forState:UIControlStateNormal];
            UIBarButtonItem *sendBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
            [self.navigationItem setRightBarButtonItem:sendBarButtonItem];
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
        }
    }
}

@end
