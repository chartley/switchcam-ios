//
//  UploadVideoViewController.m
//  SwitchcamPro
//
//  Created by William Ketterer on 12/8/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "SPConstants.h"
#import "UploadVideoViewController.h"
#import "LabelInvisibleButtonCell.h"
#import "LabelTextFieldCell.h"
#import "ButtonToProgressCell.h"
#import "Recording.h"
#import "SCS3Uploader.h"
#import "SPSerializable.h"

@interface UploadVideoViewController ()

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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Network Requests

- (void)createUserVideo {
    NSString *facebookId = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey];
    NSString *facebookToken = [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookTokenKey];
    
    // Completion Blocks
    void (^createUserVideoSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
    void (^createUserVideoFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    createUserVideoSuccessBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
        // Create Key
        NSString *videoKey = [NSString stringWithFormat:@"%@-%@", [[NSUserDefaults standardUserDefaults] objectForKey:kSPUserFacebookIdKey] , [SPSerializable formattedStringFromDate: self.recordingToUpload.recordStart]];
        
        NSError *error;
        // Get Data
        NSData *uploadData = [[NSData alloc] initWithContentsOfFile:[self.recordingToUpload compressedVideoURL] options:NSDataReadingMapped error:&error];
        
        
        // Start Upload
        SCS3Uploader *uploader = [[SCS3Uploader alloc] init];
        [uploader uploadVideo:uploadData withKey:videoKey];
    };
    
    createUserVideoFailureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        //TODO better error handling
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops", @"") message:NSLocalizedString(@"Something went wrong, please try again.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alertView show];
    };
    
    // Make Request and set params
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    [httpClient setAuthorizationHeaderWithUsername:facebookId password:facebookToken];
    //TODO Need payload

    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"uservideo/" parameters:nil];
    
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:createUserVideoSuccessBlock failure:createUserVideoFailureBlock];
    
    [operation start];
}



#pragma mark - Button Actions

- (void)uploadButtonAction {
    // Completion Blocks
    void (^compressionSuccessBlock)();
    void (^compressionFailureBlock)(NSError *error);
    
    compressionSuccessBlock = ^() {
        // Notify Switchcam of new recording
        [self createUserVideo];
    };
    
    compressionFailureBlock = ^(NSError *error) {
        // Show error
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alertView show];
    };
    
    // Start Compression
    [self startVideoCompressionWithSuccessHandler:compressionSuccessBlock failureHandler:compressionFailureBlock];
}

#pragma mark - Helper Methods

- (void)startVideoCompressionWithSuccessHandler:(void (^)())successHandler failureHandler:(void (^)(NSError *))failureHandler  {
    NSURL *inputURL = [NSURL URLWithString:[self.recordingToUpload localVideoAssetURL]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *dateString = [dateFormatter stringFromDate:[self.recordingToUpload recordStart]];
    
    // Make sure we don't overwrite
    NSUInteger count = 0;
    NSString *outputURLString = nil;
    do {
        NSString *extension = (__bridge  NSString *)UTTypeCopyPreferredTagWithClass(( CFStringRef)AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension);
        NSString *fileNameNoExtension = [[inputURL URLByDeletingPathExtension] lastPathComponent];
        NSString *fileName = [NSString stringWithFormat:@"%@-%@-%u",fileNameNoExtension , dateString, count];
        outputURLString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        outputURLString = [outputURLString stringByAppendingPathComponent:fileName];
        outputURLString = [outputURLString stringByAppendingPathExtension:extension];
        count++;
        
    } while ([[NSFileManager defaultManager] fileExistsAtPath:outputURLString]);
    
    NSURL *outputURL = [NSURL fileURLWithPath:outputURLString];
    
    [self.recordingToUpload setCompressedVideoURL:outputURLString];
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputURLString]) {
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            successHandler();
        } else {
            NSError *error = exportSession.error;
            failureHandler(error);
        }
    }];
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
            break;
        }
            
        case 1:
        {
            LabelInvisibleButtonCell *labelInvisibleButtonCell = (LabelInvisibleButtonCell *)cell;
            [labelInvisibleButtonCell.leftLabel setText:NSLocalizedString(@"Tag Friends?", @"")];
            [labelInvisibleButtonCell.invisibleButton addTarget:self action:@selector(tagFriends) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        case 2:
        {
            ButtonToProgressCell *labelSwitchCell = (ButtonToProgressCell *)cell;
            [labelSwitchCell.bigButton setTitle:NSLocalizedString(@"Upload", @"") forState:UIControlStateNormal];
            [labelSwitchCell.bigButton addTarget:self action:@selector(uploadButtonAction) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
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
            cell = [tableView dequeueReusableCellWithIdentifier:kLabelInvisibleButtonCellIdentifier];
            break;
        }
        case 2:
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
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LabelInvisibleButtonCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
                break;
            }
            case 2:
            {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"ButtonToProgressCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
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
