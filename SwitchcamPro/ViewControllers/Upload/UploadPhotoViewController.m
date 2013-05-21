//
//  UploadPhotoViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 2/7/13.
//  Copyright (c) 2013 William Ketterer. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <Mixpanel/Mixpanel.h>
#import "UploadPhotoViewController.h"
#import "SPConstants.h"
#import "LabelInvisibleButtonCell.h"
#import "LabelTextFieldCell.h"
#import "ButtonToProgressCell.h"
#import "UserVideo.h"
#import "SCS3Uploader.h"
#import "SPSerializable.h"
#import "UIImage+H568.h"
#import "Mission.h"

#define kBufferBetweenThumbnailLabels 10

@interface UploadPhotoViewController () {
    UITextField *activeTextField;
}

@property (strong, nonatomic) UIProgressView *uploadProgressView;
@property (strong, nonatomic) UILabel *uploadProgressLabel;
@property (strong, nonatomic) NSTimer *uploadProgressBarTimer;
@property (strong, nonatomic) NSData *photoData;

- (void)startUpload;

@end

@implementation UploadPhotoViewController

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
    
    // Add background
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgfull-fullapp"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    // Set title
    [self.navigationItem setTitle:NSLocalizedString(@"Upload Video", @"")];
    
    // Set fonts
    [self.timeLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
    [self.timeLabel setTextColor:[UIColor whiteColor]];
    [self.timeLabel setShadowColor:[UIColor blackColor]];
    [self.timeLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.headerToolbarLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.headerToolbarLabel setTextColor:[UIColor whiteColor]];
    [self.headerToolbarLabel setShadowColor:[UIColor blackColor]];
    [self.headerToolbarLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // Set Labels
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"h:mm a"];
    [self.timeLabel setText:[dateFormatter stringFromDate:[self.photoToUpload createDate]]];
    
    // Load thumbnail image
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[self.photoToUpload thumbURL]];
    
    // Set Thumbnail
    [self.photoThumbnailImageView setImage:thumbnailImage];
    
    // Thumbnail border
    [self.photoThumbnailImageView.layer setCornerRadius:5.0f];
    [self.photoThumbnailImageView.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.photoThumbnailImageView.layer setBorderWidth:1.5f];
    [self.photoThumbnailImageView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.photoThumbnailImageView.layer setShadowOpacity:0.8];
    [self.photoThumbnailImageView.layer setShadowRadius:3.0];
    [self.photoThumbnailImageView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    [self.photoThumbnailImageView.layer setMasksToBounds:YES];
    
    // Set Toolbar
    [self.headerToolbar setBackgroundImage:[UIImage imageNamed:@"bg-appheader"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    // Scrollview contentsize
    if (IS_IPHONE_5) {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, 568-44-20);
    } else {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, 480-44-20);
    }
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    [assetLibrary assetForURL:[NSURL URLWithString:[self.photoToUpload localURL]] resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte*)malloc(rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
        self.photoData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        
        UIImage *img = [UIImage
                        imageWithCGImage:[rep fullScreenImage]
                        scale:[rep scale]
                        orientation:UIImageOrientationUp];
        [self.photoThumbnailImageView setImage:img];
    }
                 failureBlock:^(NSError *error) {
                     NSLog(@"Error: %@",[error localizedDescription]);
                 }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Observe keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Button Actions

- (void)uploadButtonAction {
    // Start Upload in background
    [self performSelectorInBackground:@selector(startUpload) withObject:nil];
    
    // Track
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Photo S3 Upload Began"
         properties:[NSDictionary dictionaryWithObjectsAndKeys:self.photoToUpload.photoURL, @"UploadPath", nil]];
}

- (IBAction)backButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper Methods

- (void)startUpload {    
    SCS3Uploader *uploader = [SCS3Uploader sharedInstance];
    [uploader uploadVideo:self.photoData withKey:self.photoToUpload.photoKey];
    
    [self performSelectorOnMainThread:@selector(backButtonAction:) withObject:self waitUntilDone:NO];
}

- (void)tagFriends {
    
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0:
        {
            ButtonToProgressCell *buttonToProgressCell = (ButtonToProgressCell *)cell;
            [buttonToProgressCell.bigButton setTitle:NSLocalizedString(@"Upload", @"") forState:UIControlStateNormal];
            [buttonToProgressCell.bigButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [buttonToProgressCell.bigButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
            [buttonToProgressCell.bigButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
            [buttonToProgressCell.bigButton addTarget:self action:@selector(uploadButtonAction) forControlEvents:UIControlEventTouchUpInside];
            
            
            // Set Button Image
            UIImage *buttonImage = [[UIImage imageNamed:@"btn-orange-lg"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
            UIImage *buttonImageHighlight = [[UIImage imageNamed:@"btn-orange-lg-pressed"]
                                             resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
            // Set the background for any states you plan to use
            [buttonToProgressCell.bigButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
            [buttonToProgressCell.bigButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    switch (indexPath.row) {
        case 0:
        {
            return kButtonToProgressCellRowHeight;
            break;
        }
        default:
            return 0;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.row) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kButtonToProgressCellIdentifier];
            break;
        }
        default:
            break;
    }
    
    if (cell == nil) {
        switch (indexPath.row) {
            case 0:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ButtonToProgressCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                
                // Grab progress view and label
                self.uploadProgressView = [((ButtonToProgressCell*)cell) progressView];
                self.uploadProgressLabel = [((ButtonToProgressCell*)cell) progressLabel];
                
                // Custom track
                UIImage *progressImage = [[UIImage imageNamed:@"processingbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
                UIImage *trackImage = [[UIImage imageNamed:@"bg-processing-bar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
                [self.uploadProgressView setProgressImage:progressImage];
                [self.uploadProgressView setTrackImage:trackImage];
                [self.uploadProgressView setFrame:CGRectMake(self.uploadProgressView.frame.origin.x, self.uploadProgressView.frame.origin.y, self.uploadProgressView.frame.size.width, 41)];
                
                // Set Font / Color
                [self.uploadProgressLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
                [self.uploadProgressLabel setTextColor:[UIColor whiteColor]];
                [self.uploadProgressLabel setShadowColor:[UIColor blackColor]];
                [self.uploadProgressLabel setShadowOffset:CGSizeMake(0, -1)];
                break;
            }
            default:
                break;
        }
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
    // Set backgrounds
    if (indexPath.row == 0) {
        // Top
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-single"]]];
    }
    
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

#pragma mark - NSTimer Methods

- (void) updateCompressDisplay {
    [self performSelectorOnMainThread:@selector(updateCompressBarAndLabel) withObject:nil waitUntilDone:NO];
    
    // Kill timer if we are finished
    if (self.uploadProgressView.progress > .99) {
        [self.uploadProgressBarTimer invalidate];
    }
}

- (void)updateCompressBarAndLabel {
    // Update progress bar
    self.uploadProgressView.progress = 1;
    
    // Update label
    NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Processing Video - %d%%", @""), (int)(self.uploadProgressView.progress * 100)];
    [self.uploadProgressLabel setText:progressString];
}

#pragma mark - Observers

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect rc = [activeTextField bounds];
    rc = [activeTextField convertRect:rc toView:self.scrollView];
    [self.scrollView scrollRectToVisible:rc animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.25 animations:^{
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        self.scrollView.contentInset = contentInsets;
        self.scrollView.scrollIndicatorInsets = contentInsets;
    }
                     completion:(void (^)(BOOL)) ^{
                     }
     ];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
