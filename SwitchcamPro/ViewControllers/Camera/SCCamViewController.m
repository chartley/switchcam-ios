/*
     File: SCCamViewController.m
 Abstract: A view controller that coordinates the transfer of information between the user interface and the capture manager.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SCCamViewController.h"
#import "SCCamCaptureManager.h"
#import "SCCamRecorder.h"
#import "UploadVideoViewController.h"
#import "UserVideo.h"
#import "Mission.h"
#import "SPLocationManager.h"

static void *SCCamFocusModeObserverContext = &SCCamFocusModeObserverContext;

@interface SCCamViewController () <UIGestureRecognizerDelegate> {
    NSTimer *videoLengthTimer;
    int timerCount;
    MBProgressHUD *HUD;
}

@property (nonatomic, retain) IBOutlet UILabel *timerCountLabelLandscape;
@property (nonatomic, retain) IBOutlet UIImageView *timerBackgroundLandscape;
@end

@interface SCCamViewController (InternalMethods)
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateButtonStates;
@end

@interface SCCamViewController (SCCamCaptureManagerDelegate) <SCCamCaptureManagerDelegate>
@end

@implementation SCCamViewController

@synthesize captureManager;
@synthesize cameraToggleButton;
@synthesize recordButton;
@synthesize stillButton;
@synthesize closeButton;
@synthesize recorderGlow;
@synthesize focusModeLabel;
@synthesize videoPreviewView;
@synthesize captureVideoPreviewLayer;

@synthesize timerCountLabelLandscape;
@synthesize timerBackgroundLandscape;

@synthesize delegate;

- (NSString *)stringForFocusMode:(AVCaptureFocusMode)focusMode
{
	NSString *focusString = @"";
	
	switch (focusMode) {
		case AVCaptureFocusModeLocked:
			focusString = @"locked";
			break;
		case AVCaptureFocusModeAutoFocus:
			focusString = @"auto";
			break;
		case AVCaptureFocusModeContinuousAutoFocus:
			focusString = @"continuous";
			break;
	}
	
	return focusString;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode"];
	[captureManager release];
    [videoPreviewView release];
	[captureVideoPreviewLayer release];
    [cameraToggleButton release];
    [recordButton release];
    [stillButton release];	
	[focusModeLabel release];
	
    [super dealloc];
}

- (void)viewDidLoad
{
    // Initialization
    self.closeButton.hidden = NO;
    
	if ([self captureManager] == nil) {
		SCCamCaptureManager *manager = [[SCCamCaptureManager alloc] init];
		[self setCaptureManager:manager];
		[manager release];
		
		[[self captureManager] setDelegate:self];

		if ([[self captureManager] setupSession]) {
            // Create video preview layer and add it to the UI
			AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[[self captureManager] session]];
			UIView *view = [self videoPreviewView];
			CALayer *viewLayer = [view layer];
			[viewLayer setMasksToBounds:YES];
			
			CGRect bounds = [view bounds];
			[newCaptureVideoPreviewLayer setFrame:bounds];
			
			[newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            
            // Requires change if doing pre-iOS6
            if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported]) {
                [newCaptureVideoPreviewLayer.connection setVideoOrientation:self.interfaceOrientation];
            }
			
			[viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
			
			[self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
            [newCaptureVideoPreviewLayer release];
			
            // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[[self captureManager] session] startRunning];
			});
			
            [self updateButtonStates];
            
            // Create the focus mode UI overlay
			UILabel *newFocusModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(150, 300, viewLayer.bounds.size.width - 20, 20)];
			[newFocusModeLabel setBackgroundColor:[UIColor clearColor]];
			[newFocusModeLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.50]];
			AVCaptureFocusMode initialFocusMode = [[[captureManager videoInput] device] focusMode];
			[newFocusModeLabel setText:[NSString stringWithFormat:@"focus: %@", [self stringForFocusMode:initialFocusMode]]];
			[view addSubview:newFocusModeLabel];
			[self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:SCCamFocusModeObserverContext];
			[self setFocusModeLabel:newFocusModeLabel];
            [newFocusModeLabel release];
            
            // Add a single tap gesture to focus on the point tapped, then lock focus
			UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
			[singleTap setDelegate:self];
			[singleTap setNumberOfTapsRequired:1];
			[view addGestureRecognizer:singleTap];
			
            // Add a double tap gesture to reset the focus mode to continuous auto focus
			UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
			[doubleTap setDelegate:self];
			[doubleTap setNumberOfTapsRequired:2];
			[singleTap requireGestureRecognizerToFail:doubleTap];
			[view addGestureRecognizer:doubleTap];
			
			[doubleTap release];
			[singleTap release];
		}		
	}
    
    // Grab library thumbnail
    [self grabLibraryThumbnail];
    
    // Recorder Glow
    self.recorderGlow.animationImages = @[ [UIImage imageNamed:@"record-button-on"],
    [UIImage imageNamed:@"camera-recordbutton"] ];
    
    // all frames will execute in 1.75 seconds
    self.recorderGlow.animationDuration = 1.0;
    // repeat the annimation forever
    self.recorderGlow.animationRepeatCount = 0;
    [self.recorderGlow startAnimating];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // If no torch supported, hide controls for it
    if ([device hasTorch] == NO)
    {
        self.flashButton.hidden = YES;
        self.flashImageView.hidden = YES;
    }
    
    // Set Button with resizable one
    UIImage *cameraButtonImage = [[UIImage imageNamed:@"btn-camera"]
                                  resizableImageWithCapInsets:UIEdgeInsetsMake(17, 22, 17, 22)];
    self.cameraToggleImageView.image = cameraButtonImage;
    
    // Set Button with resizable one
    UIImage *flashButtonImage = [[UIImage imageNamed:@"btn-camera-circle"]
                                  resizableImageWithCapInsets:UIEdgeInsetsMake(17, 17, 17, 17)];
    self.flashImageView.image = flashButtonImage;
    
		
    // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	// Regiser for HUD callbacks so we can remove it from the window at the right time
	HUD.delegate = self;
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden: YES withAnimation: UIStatusBarAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden: NO
                                            withAnimation: UIStatusBarAnimationNone];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SCCamFocusModeObserverContext) {
        // Update the focus UI overlay string when the focus mode changes
		[focusModeLabel setText:[NSString stringWithFormat:@"focus: %@", [self stringForFocusMode:(AVCaptureFocusMode)[[change objectForKey:NSKeyValueChangeNewKey] integerValue]]]];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

#pragma mark - Helper Methods

- (void)closeTorchDrawer {
    // Shrink button & hide options
    [UIView animateWithDuration:.4f
                     animations:^{
                         [self.flashImageView setFrame:CGRectMake(self.flashImageView.frame.origin.x, self.flashImageView.frame.origin.y, 81, self.flashImageView.frame.size.height)];
                         [self.flashSelectAutoButton setAlpha:0.0];
                         [self.flashSelectOnButton setAlpha:0.0];
                         [self.flashSelectOffButton setAlpha:0.0];
                         [self.flashSelectedButton setAlpha:1.0];
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)grabLibraryThumbnail {
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    
    // Completion Blocks
    void (^enumerationBlock)(ALAssetsGroup *group, BOOL *stop);
    void (^failureBlock)(NSError *error) ;
    
    enumerationBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        
        if (group.numberOfAssets > 0) {
            // Grab first image
            UIImage *thumbnail = [UIImage imageWithCGImage:group.posterImage];
            [self.selectExistingButton setImage:thumbnail forState:UIControlStateNormal];
        }
        
        // Stop enumerating
        *stop = YES;
    };
    
    failureBlock = ^(NSError *error) {
        // TODO some placeholder
        // Do nothing
    };
    
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:enumerationBlock failureBlock:failureBlock];
}

#pragma mark - IBActions Actions

- (IBAction)toggleCamera:(id)sender {
    // Toggle between cameras when there is more than one
    [[self captureManager] toggleCamera];
    
    // Do an initial focus
    [[self captureManager] continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

- (IBAction)toggleRecording:(id)sender {
    // Start recording if there isn't a recording running. Stop recording if there is.
    [[self recordButton] setEnabled:NO];
    
    if (![[[self captureManager] recorder] isRecording]) {
        // Start collecting data of our new video
        NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        UserVideo *currentRecording = [NSEntityDescription
                                          insertNewObjectForEntityForName:@"UserVideo"
                                          inManagedObjectContext:context];
        
        CLLocationCoordinate2D coordinate = [[[SPLocationManager sharedInstance] currentLocation] coordinate];
        
        [currentRecording setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
        [currentRecording setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
        [currentRecording setMission:self.selectedMission];
        [currentRecording setRecordStart:[NSDate date]];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
        NSString *dateString = [dateFormatter stringFromDate:[currentRecording recordStart]];
        
        // Make sure we don't overwrite
        NSUInteger count = 0;
        NSString *outputURLString = nil;
        do {
            NSString *videoExtension = (NSString *)UTTypeCopyPreferredTagWithClass(( CFStringRef)AVFileTypeMPEG4, kUTTagClassFilenameExtension);
            NSString *photoExtension = (NSString *)UTTypeCopyPreferredTagWithClass(( CFStringRef)kUTTypePNG, kUTTagClassFilenameExtension);
            NSString *fileNameNoExtension = @"capture";
            NSString *fileName = [NSString stringWithFormat:@"%@-%@-%u",fileNameNoExtension , dateString, count];
            outputURLString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            outputURLString = [outputURLString stringByAppendingPathComponent:fileName];
            NSString *videoURLString = [outputURLString stringByAppendingPathExtension:videoExtension];
            NSString *thumbnailURLString = [outputURLString stringByAppendingPathExtension:photoExtension];
            
            [currentRecording setCompressedVideoURL:videoURLString];
            [currentRecording setThumbnailLocalURL:thumbnailURLString];
            [currentRecording setFilename:fileName];
            count++;
            
        } while ([[NSFileManager defaultManager] fileExistsAtPath:outputURLString]);
        
        
        [[self captureManager] setCurrentRecording:currentRecording];
        
        // Hide the close button
        self.closeButton.hidden = YES;
        self.closeImageView.hidden = YES;
        
        // Start Timer
        timerCount = 0;
        videoLengthTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(increaseAndDisplayTime) userInfo:nil repeats:YES];
        
        self.recorderGlow.hidden = NO;
        
        [[self captureManager] startRecording];
    } else {
        HUD.labelText = @"Saving";
        
        [HUD show:YES];
        
        [[self captureManager] stopRecording];
        
        // Stop recording
        [[[self captureManager] currentRecording] setRecordEnd:[NSDate date]];
        
        // Stop glow
        self.recorderGlow.hidden = YES;
        
        // Show the close button
        self.closeButton.hidden = NO;
        self.closeImageView.hidden = NO;
        
        // Stop timer
        [videoLengthTimer invalidate];
        videoLengthTimer = nil;
    }
}

- (IBAction)captureStillImage:(id)sender {
    // Capture a still image
    [[self stillButton] setEnabled:NO];
    [[self captureManager] captureStillImage];
    
    // Flash the screen white and fade it out to give UI feedback that a still image was taken
    UIView *flashView = [[UIView alloc] initWithFrame:[[self videoPreviewView] frame]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [[[self view] window] addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                         [flashView release];
                     }
     ];
}

- (IBAction)closeButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleFlashAction:(id)sender {
    // Grow button & show options
    [UIView animateWithDuration:.4f
                     animations:^{
                         [self.flashImageView setFrame:CGRectMake(self.flashImageView.frame.origin.x, self.flashImageView.frame.origin.y, 160, self.flashImageView.frame.size.height)];
                         [self.flashSelectAutoButton setAlpha:1.0];
                         [self.flashSelectOnButton setAlpha:1.0];
                         [self.flashSelectOffButton setAlpha:1.0];
                         [self.flashSelectedButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished){
                     }];
}

- (IBAction)toggleFlashAutoAction:(id)sender {
    [[self captureManager] setTorchMode:AVCaptureTorchModeAuto];
    [self.flashSelectedButton setTitle:NSLocalizedString(@"Auto", @"") forState:UIControlStateNormal];
    [self closeTorchDrawer];
}

- (IBAction)toggleFlashOnAction:(id)sender {
    [[self captureManager] setTorchMode:AVCaptureTorchModeOn];
    [self.flashSelectedButton setTitle:NSLocalizedString(@"On", @"") forState:UIControlStateNormal];
    [self closeTorchDrawer];
}

- (IBAction)toggleFlashOffAction:(id)sender {
    [[self captureManager] setTorchMode:AVCaptureTorchModeOff];
    [self.flashSelectedButton setTitle:NSLocalizedString(@"Off", @"") forState:UIControlStateNormal];
    [self closeTorchDrawer];
}

- (IBAction)selectExistingButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(selectExistingButtonPressed)]) {
		[self.delegate performSelector:@selector(selectExistingButtonPressed) withObject:nil];
	}
}

#pragma mark - Timer Methods

- (void)increaseAndDisplayTime {
    timerCount++;
    int seconds = (timerCount) % 60;
    int minutes = (timerCount - seconds) / 60;
    timerCountLabelLandscape.text = [NSString stringWithFormat:@"%d:%.2d", minutes, seconds];
}

@end

@implementation SCCamViewController (InternalMethods)

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates 
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    if ([[self.captureManager recorder].videoConnection isVideoMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }    

    if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;

                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:[self videoPreviewView]];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported])
        [captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

// Update button states based on the number of available cameras and mics
- (void)updateButtonStates
{
	NSUInteger cameraCount = [[self captureManager] cameraCount];
	NSUInteger micCount = [[self captureManager] micCount];
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        if (cameraCount < 2) {
            [[self cameraToggleButton] setEnabled:NO]; 
            
            if (cameraCount < 1) {
                [[self stillButton] setEnabled:NO];
                
                if (micCount < 1)
                    [[self recordButton] setEnabled:NO];
                else
                    [[self recordButton] setEnabled:YES];
            } else {
                [[self stillButton] setEnabled:YES];
                [[self recordButton] setEnabled:YES];
            }
        } else {
            [[self cameraToggleButton] setEnabled:YES];
            [[self stillButton] setEnabled:YES];
            [[self recordButton] setEnabled:YES];
        }
    });
}

@end

@implementation SCCamViewController (SCCamCaptureManagerDelegate)

- (void)captureManager:(SCCamCaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    });
}

- (void)captureManagerRecordingBegan:(SCCamCaptureManager *)captureManager
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[self recordButton] setEnabled:YES];
    });
}

- (void)captureManagerRecordingFinished:(SCCamCaptureManager *)captureManager
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[self recordButton] setEnabled:YES];
        
        [HUD hide:YES];
        
        // Save
        NSManagedObjectContext *context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        [context processPendingChanges];
        NSError *error = nil;
        if (![context saveToPersistentStore:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    });
}

- (void)captureManagerStillImageCaptured:(SCCamCaptureManager *)captureManager
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[self stillButton] setEnabled:YES];
    });
}

- (void)captureManagerDeviceConfigurationChanged:(SCCamCaptureManager *)captureManager
{
	[self updateButtonStates];
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[HUD removeFromSuperview];
	[HUD release];
	HUD = nil;
}

@end
