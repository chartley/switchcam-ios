//
//  UploadVideoViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <Mixpanel/Mixpanel.h>
#import "SPConstants.h"
#import "UploadVideoViewController.h"
#import "LabelInvisibleButtonCell.h"
#import "LabelTextFieldCell.h"
#import "ButtonToProgressCell.h"
#import "UserVideo.h"
#import "SCS3Uploader.h"
#import "SPSerializable.h"
#import "UIImage+H568.h"
#import "Mission.h"

#define kBufferBetweenThumbnailLabels 10

@interface UploadVideoViewController () {
    UITextField *activeTextField;
}

@property (strong, nonatomic) UIProgressView *compressProgressView;
@property (strong, nonatomic) UILabel *compressProgressLabel;
@property (strong, nonatomic) NSTimer *compressProgressBarTimer;
@property (strong, nonatomic) AVAssetExportSession *compressionSession;

- (void)startUpload;

@end

@implementation UploadVideoViewController

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
    
    [self.lengthLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:12]];
    [self.lengthLabel setTextColor:RGBA(105, 105, 105, 1)];
    [self.lengthLabel setShadowColor:[UIColor blackColor]];
    [self.lengthLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.sizeLabel setFont:[UIFont fontWithName:@"SourceSansPro-It" size:12]];
    [self.sizeLabel setTextColor:RGBA(105, 105, 105, 1)];
    [self.sizeLabel setShadowColor:[UIColor blackColor]];
    [self.sizeLabel setShadowOffset:CGSizeMake(0, -1)];
    
    [self.headerToolbarLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
    [self.headerToolbarLabel setTextColor:[UIColor whiteColor]];
    [self.headerToolbarLabel setShadowColor:[UIColor blackColor]];
    [self.headerToolbarLabel setShadowOffset:CGSizeMake(0, -1)];
    
    // Set Button Image
    UIImage *buttonImage = [[UIImage imageNamed:@"btn-ltgrey"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 15, 20, 15)];
    
    // Set the background for any states you plan to use
    [self.uploadLaterButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    // Set Labels
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"h:mm a"];
    [self.timeLabel setText:[dateFormatter stringFromDate:[self.userVideoToUpload recordStart]]];
    
    // Setup Length String
    int durationSeconds = [[self.userVideoToUpload durationSeconds] intValue];
    int seconds = (durationSeconds) % 60;
    int minutes = (durationSeconds - seconds) / 60;
    NSString *durationString = [NSString stringWithFormat:@"%d:%.2d", minutes, seconds];
    
    NSString *lengthString = [NSString stringWithFormat:NSLocalizedString(@"Length: %@", @""), durationString];
    [self.lengthLabel setText:lengthString];
    
    NSString *sizeString = [NSString stringWithFormat:NSLocalizedString(@"Size: %@MB", @""), [[self.userVideoToUpload sizeMegaBytes] stringValue]];
    [self.sizeLabel setText:sizeString];
    
    // Size to fit labels and set their origins
    [self.timeLabel sizeToFit];
    [self.lengthLabel setFrame:CGRectMake(self.timeLabel.frame.origin.x + self.timeLabel.frame.size.width + kBufferBetweenThumbnailLabels, self.lengthLabel.frame.origin.y, self.lengthLabel.frame.size.width, self.lengthLabel.frame.size.height)];
    
    [self.lengthLabel sizeToFit];
    [self.sizeLabel setFrame:CGRectMake(self.lengthLabel.frame.origin.x + self.lengthLabel.frame.size.width + kBufferBetweenThumbnailLabels, self.sizeLabel.frame.origin.y, self.sizeLabel.frame.size.width, self.sizeLabel.frame.size.height)];
    
    [self.sizeLabel sizeToFit];
    
    // Load thumbnail image
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[self.userVideoToUpload thumbnailLocalURL]];
    
    // Set Thumbnail
    [self.videoThumbnailImageView setImage:thumbnailImage];
    
    // Thumbnail border
    [self.videoThumbnailImageView.layer setCornerRadius:5.0f];
    [self.videoThumbnailImageView.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.videoThumbnailImageView.layer setBorderWidth:1.5f];
    [self.videoThumbnailImageView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.videoThumbnailImageView.layer setShadowOpacity:0.8];
    [self.videoThumbnailImageView.layer setShadowRadius:3.0];
    [self.videoThumbnailImageView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    [self.videoThumbnailImageView.layer setMasksToBounds:YES];
    
    // Set Toolbar
    [self.headerToolbar setBackgroundImage:[UIImage imageNamed:@"bg-appheader"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    // Scrollview contentsize
    if (IS_IPHONE_5) {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, 568-44-20);
    } else {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, 480-44-20);
    }

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
    // Save video title
    [self.userVideoToUpload setInputTitle:self.videoTitleTextField.text];
    
    NSError *error = nil;
    // Save
    NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    [context processPendingChanges];
    if (![context saveToPersistentStore:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    // Fade in progress bar
    [UIView animateWithDuration:1.0 animations:^(){
        [self.compressProgressView setAlpha:1.0];
        [self.compressProgressLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        
    }];
    
    // Completion Blocks
    void (^compressionSuccessBlock)();
    void (^compressionFailureBlock)(NSError *error);
    
    compressionSuccessBlock = ^() {
        [self performSelectorOnMainThread:@selector(backButtonAction:) withObject:self waitUntilDone:NO];
        
        // Start Upload in background
        [self performSelectorInBackground:@selector(startUpload) withObject:nil];
    };
    
    compressionFailureBlock = ^(NSError *error) {
        // Show error
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alertView show];
    };
    
    // Start Compression
    [self startVideoCompressionWithSuccessHandler:compressionSuccessBlock failureHandler:compressionFailureBlock];
    
    // Track
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Video S3 Upload Began"
         properties:[NSDictionary dictionaryWithObjectsAndKeys:self.userVideoToUpload.uploadPath, @"UploadPath", nil]];
}

- (IBAction)backButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper Methods

- (void)startUpload {
    @autoreleasepool {
        NSError *error;
        // Get Data
        NSData *uploadData = [[NSData alloc] initWithContentsOfFile:[self.userVideoToUpload compressedVideoURL] options:NSDataReadingMapped error:&error];
        
        SCS3Uploader *uploader = [[SCS3Uploader alloc] init];
        [uploader uploadVideo:uploadData withKey:self.userVideoToUpload.uploadPath];
    }
    
}

- (void)startVideoCompressionWithSuccessHandler:(void (^)())successHandler failureHandler:(void (^)(NSError *))failureHandler  {
    NSString *outputURLString = [self.userVideoToUpload compressedVideoURL];
    NSURL *inputURL = [NSURL URLWithString:[self.userVideoToUpload localVideoAssetURL]];
    NSURL *outputURL = [NSURL fileURLWithPath:outputURLString];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputURLString]) {
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    }
    
    NSString *uploadQuality = [[NSUserDefaults standardUserDefaults] objectForKey:kUploadQualityKey];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    self.compressionSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:uploadQuality];
    self.compressionSession.outputURL = outputURL;
    self.compressionSession.outputFileType = AVFileTypeMPEG4;
    [self.compressionSession exportAsynchronouslyWithCompletionHandler:^(void) {
        if (self.compressionSession.status == AVAssetExportSessionStatusCompleted) {
            successHandler();
        } else {
            NSError *error = self.compressionSession.error;
            failureHandler(error);
        }
    }];
    
    self.compressProgressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updateCompressDisplay) userInfo:nil repeats:YES];
}

- (void)tagFriends {
    
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0:
        {
            LabelTextFieldCell *labelTextFieldCell = (LabelTextFieldCell *)cell;
            [labelTextFieldCell.leftLabel setText:NSLocalizedString(@"Video Title", @"")];
            [labelTextFieldCell.leftLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:17]];
            [labelTextFieldCell.textField setTextColor:[UIColor whiteColor]];
            [labelTextFieldCell.textField setFont:[UIFont fontWithName:@"SourceSansPro-Light" size:17]];
            [labelTextFieldCell.textField setDelegate:self];
            self.videoTitleTextField = labelTextFieldCell.textField;
            break;
        }
        case 1:
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
            return kLabelTextFieldCellRowHeight;
            break;
        }
        case 1:
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
    return 2;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    switch (indexPath.row) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelTextFieldCellIdentifier];
            break;
        }
        case 1:
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
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelTextFieldCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                break;
            }
            case 1:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ButtonToProgressCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                
                // Grab progress view and label
                self.compressProgressView = [((ButtonToProgressCell*)cell) progressView];
                self.compressProgressLabel = [((ButtonToProgressCell*)cell) progressLabel];
                
                // Custom track
                UIImage *progressImage = [[UIImage imageNamed:@"processingbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
                UIImage *trackImage = [[UIImage imageNamed:@"bg-processing-bar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
                [self.compressProgressView setProgressImage:progressImage];
                [self.compressProgressView setTrackImage:trackImage];
                [self.compressProgressView setFrame:CGRectMake(self.compressProgressView.frame.origin.x, self.compressProgressView.frame.origin.y, self.compressProgressView.frame.size.width, 41)];
                
                // Set Font / Color
                [self.compressProgressLabel setFont:[UIFont fontWithName:@"SourceSansPro-Regular" size:12]];
                [self.compressProgressLabel setTextColor:[UIColor whiteColor]];
                [self.compressProgressLabel setShadowColor:[UIColor blackColor]];
                [self.compressProgressLabel setShadowOffset:CGSizeMake(0, -1)];
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
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-top"]]];
    } else if (indexPath.row == 1) {
        // Bottom
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-bottom"]]];
    } else {
        // Middle
        [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grptableview-middle"]]];
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
    if (self.compressProgressView.progress > .99) {
        [self.compressProgressBarTimer invalidate];
    }
}

- (void)updateCompressBarAndLabel {
    // Update progress bar
    self.compressProgressView.progress = self.compressionSession.progress;
    
    // Update label
    NSString *progressString = [NSString stringWithFormat:NSLocalizedString(@"Processing Video - %d%%", @""), (int)(self.compressionSession.progress * 100)];
    [self.compressProgressLabel setText:progressString];
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
