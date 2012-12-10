//
//  EventViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/6/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import "EventViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "SCCamViewController.h"
#import "EventInfoViewController.h"
#import "EventActivityViewController.h"
#import "EventPeopleViewController.h"
#import "EventVideosViewController.h"
#import "UploadVideoViewController.h"
#import "SPTabStyle.h"


@interface EventViewController ()

@end

@implementation EventViewController

- (id) init {
    // Tabs
    EventInfoViewController *eventInfoViewController = [[EventInfoViewController alloc] init];
    
    EventActivityViewController *eventActivityViewController = [[EventActivityViewController alloc] init];
    
    EventPeopleViewController *eventPeopleViewController = [[EventPeopleViewController alloc] init];
    
    EventVideosViewController *eventVideosViewController = [[EventVideosViewController alloc] init];
    
    NSArray *viewController = [NSArray arrayWithObjects:eventInfoViewController, eventActivityViewController, eventPeopleViewController, eventVideosViewController, nil];
    
    self = [super initWithViewControllers:viewController style:[SPTabStyle defaultStyle]];
    
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Adjust drawer toolbar to be set to the correct origin depending on screen size
    [self.toolbarDrawer setFrame:CGRectMake(0, self.view.frame.size.height - self.toolbarDrawer.frame.size.height, self.toolbarDrawer.frame.size.width, self.toolbarDrawer.frame.size.height)];
    [self.view bringSubviewToFront:self.toolbarDrawer];
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

- (IBAction)photoButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction)recordButtonAction:(id)sender {
    SCCamViewController *viewController = [[SCCamViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentModalViewController:navController animated:YES];
}

- (IBAction)noteButtonAction:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(IBAction)chooseFromLibrary:(id)sender {
    // Pick from library, only videos
    UIImagePickerController *viewController = [[UIImagePickerController alloc] init];
    viewController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    viewController.delegate = self;
    viewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    viewController.allowsEditing = NO;
    
    [self presentModalViewController:viewController animated:YES];
}

#pragma mark - UIImagePicker Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissModalViewControllerAnimated:YES];
    
    // Create Recording
    //TODO
    Recording *recording = nil;
    
    // Upload
    UploadVideoViewController *viewController = [[UploadVideoViewController alloc] init];
    [viewController setRecordingToUpload:recording];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

@end
