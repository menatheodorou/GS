//
//  ImageCaptureViewController.m
//  ZetaCamera
//
//  Created by benjamin michel on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageCaptureViewController.h"
#import "EMResourceValue.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIo/CGImageProperties.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoTimer.h"
#import "MediaViewController.h"
#import "EMFramework.h"
#import "InfoViewController.h"
#import "SettingViewController.h"
#import "VisionUtility.h"
#import "SettingMenuView.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+ImageCrop.h"
#import "Global.h"
#import "GripShootSettingsVC.h"
#import "Constant.h"
#import "OrientNavigationVC.h"
#import "INTULocationManager.h"
#import "PreviewViewController.h"
#import "QBAssetsCollectionViewLayout.h"
#import "QBAssetsCollectionViewController.h"

//#import "TestFlight.h"

/**
 Importing the different devices
 */
#import "VideoDevice.h"
#import "PhotoDevice.h"

#import "DevicePickerView.h"


/**
 Values for the status of the flash
 */
#define FLASH_AUTO 0
#define FLASH_ON 1
#define FLASH_OFF 2
#define FLASH_LIGHT 3
#define FLASH_UNSUPPORTED 4

#define HORIZONTAL_TOP_BAR_PADDING 20.0f

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

#define FOCUS_MARK_SIZE     80.0f

#define MOTION_THRESHOLD    1.10f

#define CAPTURE_DIRECTORY [NSString stringWithFormat:@"%@capture", NSTemporaryDirectory()]

static NSString * const GripShootCaptureStillImageIsCapturingStillImageObserverContext = @"PBJVisionCaptureStillImageIsCapturingStillImageObserverContext";



static uint64_t const RequiredMinimumDiskSpaceInBytes = 1073741824;
static uint64_t const PhotoRequiredMinimumDiskSpaceInBytes = 99999872;
static uint64_t const VideoRequiredMinimumDiskSpaceInBytes = 99999872;

@interface ImageCaptureViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, SettingMenuDelegate, SettingViewControllerDelegate, QBAssetsCollectionViewControllerDelegate> {
    CGAffineTransform transform;
    
    int scaleType;
    
    NSTimer *animationTimer;
    NSInteger animationCount;
    
    BOOL videoCaptureBlinkFlag;
    NSInteger _gridRotatePosition;
    
    IBOutlet DevicePickerView *_devicePickerView;
    
    IBOutlet UIButton *_switchModeButton;
    
    CGRect cameraRect;
    CGRect videoRect;
    
    IBOutlet UITableView *_table;
    __weak IBOutlet UILabel *_versionLabel;
    
    UIInterfaceOrientation simulatedOrientation;
    
    dispatch_queue_t _imageProcessQueue;
}

//indicate if we are using the front camera
@property (nonatomic) Boolean usingFrontCamera;

@property (nonatomic) Boolean needToSwitch;

@property (nonatomic, strong) GPUImageStillCamera *stillCamera;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;

@property (assign, nonatomic) NSInteger locationRequestID;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (assign, nonatomic) NSTimeInterval timeout;

@property (nonatomic, strong) SettingViewController *settingVC;
@property (nonatomic, strong) PreviewViewController *previewVC;

@property (nonatomic, strong) UIImage *lastCapturedImage;

/**
 The video timer
 */
@property(nonatomic, strong) VideoTimer *videoTimer;

@property (nonatomic, getter = isShowingPopover) BOOL showingPopover;


@property(nonatomic, strong) MWPhoto* lastPhoto;


@end

static int flashStatus;

@implementation ImageCaptureViewController

@synthesize reviewButton;
@synthesize cameraPreview;
@synthesize usingFrontCamera;
@synthesize videoSwitchButton;
@synthesize captureButton;
@synthesize videoTimer;
@synthesize timeLabel;
@synthesize flashButton;
@synthesize cameraSwitch;
@synthesize cameraSlider;
@synthesize timeLabelBackground;
@synthesize remoteButton;
@synthesize shutterView;
@synthesize scaleFactor;

bool scaleType = 0;


#pragma mark ELCImagePickerControllerDelegate Methods

- (void)assetsCollectionViewController:(QBAssetsCollectionViewController *)assetsCollectionViewController didSelectAsset:(ALAsset *)asset {
    
    self.photos =[[NSMutableArray alloc] init];
    
    for (ALAsset *asset in self.assets) {

        //NSLog(@"%@", [asset.defaultRepresentation.url absoluteString]);
        
        [self.photos addObject:[MWPhoto photoWithURL:asset.defaultRepresentation.url]];
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.wantsFullScreenLayout = YES;
    browser.zoomPhotosToFill = YES;
    //browser.interfaceOrientation = _currentOrientation;
    
    [browser setCurrentPhotoIndex:[self.assets indexOfObject:asset]];
    
    [assetsCollectionViewController.navigationController pushViewController:browser animated:YES];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

//- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
//    MWPhoto *photo = [self.photos objectAtIndex:index];
//    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
//    return [captionView autorelease];
//}

//- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
//    NSLog(@"ACTION!");
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %i", index);
}


#pragma mark - view lifecicle
-(BOOL)prefersStatusBarHidden
{
    return YES;
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    NSLog(@"%d", [[EMConnectionManager sharedManager] connectionState]);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [self resetGeoTag];
        [self resetSCN];
        [self resetLeftMode];
        [self resetStorageMemory];
        
        
        // To prevent camera freeze
        
        __block CGRect cameraFrame = _cameraContainerView.frame;
        cameraFrame.origin.x += 1;
        cameraFrame.size.width -= 2;
        _cameraContainerView.frame = cameraFrame;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            cameraFrame.origin.x -= 1;
            cameraFrame.size.width += 2;
            _cameraContainerView.frame = cameraFrame;
        });
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(BOOL)shouldAutorotate {
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationMaskPortrait;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    self.needToSwitch = NO;
    
    if (_captureMode == kCaptureModeVideo) {
        if (_recordingVideo) {
            [self stopRecordingVideo];
        }
    }
}

-(void)invalidateTimer {
    [_zoomTimer invalidate];
    _zoomTimer = nil;
}

-(void)zoomToCurrentScaleFactor {
    CGAffineTransform transformScaleIn = CGAffineTransformMakeScale([self scaleFactor], [self scaleFactor]);
    self.cameraPreview.transform = transformScaleIn;
    [self setZoom:self.scaleFactor];
}

-(void)zoomIn {
    
    if ([self scaleFactor] >= 5.0) {
        return;
    }
    
    //    if (_captureMode == kCaptureModeVideo)
    //    {
    if ([self.stillCamera.inputCamera.activeFormat respondsToSelector:@selector(videoMaxZoomFactor)])
    {
        if (([self scaleFactor] + 0.02) > self.stillCamera.inputCamera.activeFormat.videoMaxZoomFactor)
            return;
    }
    
    [self setScaleFactor:[self scaleFactor] + 0.02];
    /*
     if([avCaptureDevice respondsToSelector:@selector(rampToVideoZoomFactor::)])
     {
     [avCaptureDevice lockForConfiguration:nil];
     [avCaptureDevice rampToVideoZoomFactor:[self scaleFactor] withRate:2];
     [avCaptureDevice unlockForConfiguration];
     }*/
    [self.stillCamera.inputCamera lockForConfiguration:nil];
    
    if ([self.stillCamera.inputCamera respondsToSelector:@selector(setVideoZoomFactor:)])
    {
        if ([self scaleFactor] <= self.stillCamera.inputCamera.activeFormat.videoMaxZoomFactor) {
            if (self.scaleFactor < 1.0) {
                self.scaleFactor = 1.0;
            }
            self.stillCamera.inputCamera.videoZoomFactor = [self scaleFactor];
        }
    }
    [self.stillCamera.inputCamera unlockForConfiguration];
    //    }
    //    else
    //    {
    //        [self setScaleFactor:[self scaleFactor] + 0.02];
    //        [self zoomToCurrentScaleFactor];
    //    }
}

-(void)zoomOut {
    if ([self scaleFactor] <= 1.0) {
        [self setScaleFactor:1.0];
        return;
    }
    [self setScaleFactor:[self scaleFactor] - 0.02];
    
    //    if (_captureMode == kCaptureModeVideo)
    //    {
    [self.stillCamera.inputCamera lockForConfiguration:nil];
    
    if ([self.stillCamera.inputCamera respondsToSelector:@selector(setVideoZoomFactor:)]) {
        if (self.scaleFactor < 1.0) {
            self.scaleFactor = 1.0;
        }
        
        self.stillCamera.inputCamera.videoZoomFactor = [self scaleFactor];
    }
    [self.stillCamera.inputCamera unlockForConfiguration];
    //    }
    //    else
    //        [self zoomToCurrentScaleFactor];
}

-(IBAction)infoButtonPressed:(id)sender {
    if (_captureMode == kCaptureModeVideo && _recordingVideo) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Stop Recording?", @"Title to stop recording") message:NSLocalizedString(@"Would you like to stop recording video and view Grip & Shoot info?", @"Message for stop recording alert") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel Button") otherButtonTitles:NSLocalizedString(@"Stop Recording", @"Stop recording button"), nil];
        [alert show];
        return;
    }
    
    InfoViewController *viewController = [[InfoViewController alloc] initWithNibName:@"InfoView" bundle:[NSBundle mainBundle]];
//    [viewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:viewController animated:NO completion:NULL];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        [self takePhoto:self];
        [self infoButtonPressed:self];
    }
}

-(void)startZoomingIn {
    [self invalidateTimer];
    _zoomTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(zoomIn) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_zoomTimer forMode:NSDefaultRunLoopMode];
}

-(void)stopZoomingIn {
    [self invalidateTimer];
    
    if (!_recordingVideo)
        [self performSelectorOnMainThread:@selector(setAutoFocus) withObject:nil waitUntilDone:NO];
}

-(void)startZoomingOut {
    [self invalidateTimer];
    _zoomTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(zoomOut) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_zoomTimer forMode:NSDefaultRunLoopMode];
}

-(void)stopZoomingOut {
    [self invalidateTimer];
    
    if (!_recordingVideo)
        [self performSelectorOnMainThread:@selector(setAutoFocus) withObject:nil waitUntilDone:NO];
}

- (void)rotateGridView {
    _gridRotatePosition ++;
    
    if (self.gridType == kGridTypeSprial) {
        _gridRotatePosition = _gridRotatePosition % 4;
    } else {
        _gridRotatePosition = _gridRotatePosition % 2;
    }
    
    switch (_gridRotatePosition) {
        case 0:
             _gridBGView.transform = CGAffineTransformIdentity;
            break;
        case 1:
            _gridBGView.layer.transform = CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f);
            break;
        case 2:
            _gridBGView.transform = CGAffineTransformMakeScale(1, -1);
            break;
        case 3:
            _gridBGView.transform =  CGAffineTransformMakeRotation(M_PI);
            break;
        
        default:
            break;
    }
}

- (CGRect)frameForShortcutViewInOrientation:(UIInterfaceOrientation)orientation {
    CGRect rect;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            rect = CGRectMake(cameraView.frame.size.width - 158, cameraView.frame.size.height - _bottomBar.frame.size.height  - 30, 158, 30);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(cameraView.frame.size.width - 30, cameraView.frame.size.height - _bottomBar.frame.size.height  - 158, 30, 158);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rect = CGRectMake(cameraView.frame.size.width - 158, cameraView.frame.size.height - _bottomBar.frame.size.height  - 30, 158, 30);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake(cameraView.frame.size.width - 30, cameraView.frame.size.height - _bottomBar.frame.size.height  - 158, 30, 158);
            break;
        default:
            rect = CGRectMake(cameraView.frame.size.width - 158, cameraView.frame.size.height - _bottomBar.frame.size.height  - 30, 158, 30);
            break;
    }
    return rect;
}

- (CGRect)frameForSettingViewInOrientation:(UIInterfaceOrientation)orientation {
    CGRect rect;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            rect = CGRectMake(0, 70, 320, 154);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(0, 70, 154, _cameraContainerView.bounds.size.height);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rect = CGRectMake(0, 70, 320, 154);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake(0, 70, 154, _cameraContainerView.bounds.size.height);
            break;
        default:
            rect = CGRectMake(0, 70, 320, 154);
            break;
    }
    return rect;
}

-(CGRect)frameForVersionLabelInInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGRect rect;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            rect = CGRectMake(212,7,103,24);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rect = CGRectMake(212,7,103,24);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(288, 9, 24, 103);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake(288, 9, 24, 103);
            break;
        default:
            rect = CGRectMake(212,7,103,24);
            break;
    }
    return rect;
}

-(CGRect)frameForDevicePickerInInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGRect rect, remoteButtonFrame;
    
    if ([Global leftMode]) {
        remoteButtonFrame = [_introView convertRect:[_deviceControlView frame] fromView:_bottomBar];
    } else {
        remoteButtonFrame = [_introView convertRect:[_deviceControlView frame] fromView:_topButtonsBarView];
    }
    
    CGFloat x = floorf(([[self view] bounds].size.width / 2) - ([_devicePickerView bounds].size.width / 2));
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            rect = CGRectMake(x, 230.0f, [_devicePickerView bounds].size.width, [_devicePickerView bounds].size.height);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            rect = CGRectMake(x, 230.0f, [_devicePickerView bounds].size.width, [_devicePickerView bounds].size.height);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(55.0f, (remoteButtonFrame.origin.y - floorf([_devicePickerView bounds].size.width)) -_bottomBar.frame.size.height, [_devicePickerView bounds].size.height, [_devicePickerView bounds].size.width);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake([self view].bounds.size.width - 55.0f - [_devicePickerView bounds].size.height, (remoteButtonFrame.origin.y  - floorf([_devicePickerView bounds].size.width)) -_bottomBar.frame.size.height, [_devicePickerView bounds].size.height, [_devicePickerView bounds].size.width);
            break;
        default:
            rect = CGRectMake(x, 230.0f, [_devicePickerView bounds].size.width, [_devicePickerView bounds].size.height);
            break;
    }
    return rect;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self loadAssets];
    [self resetGeoLocation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create directory
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:CAPTURE_DIRECTORY]) {
        [[NSFileManager defaultManager] removeItemAtPath:CAPTURE_DIRECTORY error:nil];
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:CAPTURE_DIRECTORY withIntermediateDirectories:YES attributes:nil error:nil];
    
    [self.view addSubview:_introView];
    [_introView setFrame:self.view.bounds];
    
    [self loadAssets];
    
    _cameraRotateView.transform = CGAffineTransformMakeRotation(M_PI_2);
    [_cameraRotateView setFrame:_cameraRotateView.bounds];
    
    _captureMode = kCaptureModePhoto;
    _imageProcessQueue = dispatch_queue_create("com.gripshoot.imagequeu", DISPATCH_QUEUE_SERIAL);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                 name:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                               object:nil];
    
    
    NSMutableArray* introImages = [NSMutableArray arrayWithCapacity:4];
    
    for (int i = 0; i<4; i++)
        [introImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"trigger-animation%d.png", i]]];
    
    _introImageView.animationImages = introImages;
    
    _introImageView.animationDuration = 1;
    _introImageView.animationRepeatCount = 0;
    
    [_introImageView startAnimating];
    
    CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(90));
    
    [self.linkLabel setTransform:CGAffineTransformTranslate(rotateTransform, 0, 120.0)];
    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    _versionLabel.text = [NSString stringWithFormat:@"Version %@", version];
    
    //[cameraView bringSubviewToFront:_introImageView];
    //[cameraView bringSubviewToFront:self.linkLabel];
    
    //_introImageView.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationWillEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationDidEnterBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    simulatedOrientation = UIInterfaceOrientationPortrait;
    
    [_devicePickerView setFrame:[self frameForDevicePickerInInterfaceOrientation:simulatedOrientation]];
    
    _devicePickerView._table.backgroundView = nil;
    _devicePickerView._table.backgroundColor = [UIColor clearColor];
    
    [[self view] addSubview:_devicePickerView];
    [_devicePickerView setAlpha:0.0];
    
    [self setupCamera];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        __block UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            identifier = UIBackgroundTaskInvalid;
        }];
        
        if (_captureMode == kCaptureModeVideo) {
            if (_recordingVideo) {
                [self takePhoto:self];
            }
        }
        
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }];
    
    [self setScaleFactor:1.0];
    
    [[EMConnectionListManager sharedManager] addObserver:self forKeyPath:@"devices" options:NSKeyValueObservingOptionInitial context:NULL];
    
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.usingFrontCamera = NO;
    
    
    //[self positionPreviewForPhoto];
    [self performSelector:@selector(positionPreviewForPhoto) withObject:nil afterDelay:0.2];
    
    self.videoTimer = [[VideoTimer alloc] initWithController:self];
    
    [[EMConnectionManager sharedManager] addObserver:self forKeyPath:@"connectionState" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indicatorDidFire:) name:kEMConnectionDidReceiveIndicatorNotificationName object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kEMConnectionDidReceiveIndicatorNotificationName object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        NSDictionary *userInfo = [note userInfo];
        id value = [userInfo objectForKey:kEMIndicatorResourceKey];
        NSString *name = [userInfo objectForKey:kEMIndicatorNameKey];
        NSLog(@"%@: %@", name, value);
    }];
    
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.layer.cornerRadius = 5.0;
    timeLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    timeLabel.layer.borderWidth = 1.2;
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (finishedSavingImage) name:@"FinishedSavingImage" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (capturedImage:) name:@"CapturedImage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (finishedSavingImage:) name:@"FinishedSavingImage" object:nil];
    
    //[self startZoomingIn];
    
    
    // Tap Focus
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocus:)];
    [tapGR setNumberOfTapsRequired:1];
    [tapGR setNumberOfTouchesRequired:1];
    [self.cameraPreview addGestureRecognizer:tapGR];
    
    UIPinchGestureRecognizer *pinch =[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [cameraView addGestureRecognizer:pinch];
    
    // Focus Mark
    self.focusMarkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FOCUS_MARK_SIZE, FOCUS_MARK_SIZE)];
    self.focusMarkView.layer.borderColor = [[UIColor greenColor] CGColor];
    self.focusMarkView.layer.borderWidth = 1.0f;
    self.focusMarkView.alpha = 0;
    [self.cameraPreview addSubview:self.focusMarkView];
    
    // Auto Focus
    [self setAutoFocus];
    
    [self initMotionManager];
    
    [self resetSCN];
    
    self.timeout = 10.0;
    self.locationRequestID = NSNotFound;
    self.aspectRatio = kAspectType43;
    
    [self resetGeoLocation];
}

- (void)finishedSavingImage:(NSNotification *)notification
{
    //[self getLastPhoto];
    
    NSLog(@"finished saving image");
    
    //[self performSelector:@selector(getLastPhoto) withObject:nil afterDelay:0.1];
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self performSelector:@selector(getLastPhoto) withObject:nil afterDelay:0.1];
                   });
    
}


- (void)capturedImage:(NSNotification *)notification
{
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       self.captureButton.selected = NO;
                       self.captureButton.userInteractionEnabled = YES;
                       
                       //[self getLastPhoto];
                       
                       NSLog(@"captured Image");
                   });
    
    
}

#pragma mark - Fire Device Delegate

-(void)indicatorDidFire:(NSNotification *)notification {
    
    if (!cameraView.userInteractionEnabled)
        return;
    
    NSDictionary *userInfo = [notification userInfo];
    id value = [userInfo objectForKey:kEMIndicatorResourceKey];
    NSString *name = [userInfo objectForKey:kEMIndicatorNameKey];
    if ([name isEqualToString:@"zoomInButton"]) {
        NSInteger plusIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_PLUS_ACTION] integerValue];
        
        switch (plusIndex) {
            case kGripSettingAspect:
                if ([value isEqualToString:@"PRESSED"]) {
                    NSInteger aspectRatio = self.aspectRatio;
                    aspectRatio ++;
                    self.aspectRatio = aspectRatio % 3;
                }
                break;
            case kGripSettingExposure:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self increaseExposure];
                    [self showExposureView];
                }
                break;
            case kGripSettingFlash:
                if ([value isEqualToString:@"PRESSED"]) {
                    
                    if (_captureMode == kCaptureModePhoto) {
                        flashStatus ++;
                        
                        flashStatus = flashStatus % 4;
                        [self setFlashMode:flashStatus];
                    } else {
                        [self flashSwitch:nil];
                    }
                }
                break;
            case kGripSettingGeoTagging:
                if ([value isEqualToString:@"PRESSED"]) {
                    BOOL geoTagging = [Global showGeoTagging];
                    geoTagging = !geoTagging;
                    [Global setShowGetTagging:geoTagging];
                    [self resetGeoTag];
                }
                break;
            case kGripSettingGrid:
                if ([value isEqualToString:@"PRESSED"]) {
                    NSInteger gridType = self.gridType;
                    gridType ++;
                    
                    if (self.aspectRatio == kAspectType11) {
                        self.gridType = gridType % 2;
                    } else {
                        self.gridType = gridType % 4;
                    }
                    
                    [self showGridSettingView];
                }
                break;
            case kGripSettingCameraMode:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self switchVideo:nil];
                }
                break;
            case kGripSettingPreference:
                if ([value isEqualToString:@"PRESSED"]) {
                    if (self.settingVC) {
                        [self.settingVC dismissViewControllerAnimated:YES completion:^{
                            self.settingVC = nil;
                        }];
                    } else {
                        [self willShowSettingView];
                    }
                }
                break;
            case kGripSettingPhotoPreview:
                if ([value isEqualToString:@"PRESSED"]) {
                    if (self.previewVC) {
                        [self dismissPreviewImage];
                    } else {
                        [self showPreviewImage];
                    }
                }
                break;
            case kGripSettingCameraType:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self cameraSwitch:nil];
                }
                break;
            case kGripSettingWhiteBalance:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self increaseWhiteBalance];
                    [self showWhiteBalanceView];
                }
                break;
            case kGripSettingZoom:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self startZoomingIn];
                }
                else {
                    [self stopZoomingIn];
                }
                break;
            default:
                break;
        }
    }
    else if ([name isEqualToString:@"zoomOutButton"]) {
        NSInteger plusIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_MINUS_ACTION] integerValue];
        
        switch (plusIndex) {
            case kGripSettingAspect:
                if ([value isEqualToString:@"PRESSED"]) {
                    NSInteger aspectRatio = self.aspectRatio;
                    aspectRatio --;
                    
                    if (aspectRatio < 0) {
                        aspectRatio = 2;
                    }
                    
                    self.aspectRatio = aspectRatio % 3;
                }
                
                break;
            case kGripSettingExposure:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self decreaseExposure];
                    [self showExposureView];
                }
                
                break;
            case kGripSettingFlash:
                if ([value isEqualToString:@"PRESSED"]) {
                    
                    if (_captureMode == kCaptureModePhoto) {
                        flashStatus --;
                        
                        if (flashStatus < 0) {
                            flashStatus = 3;
                        }
                        
                        flashStatus = flashStatus % 4;
                        [self setFlashMode:flashStatus];
                    } else {
                        [self flashSwitch:nil];
                    }
                }
                
                break;
            case kGripSettingGeoTagging:
                if ([value isEqualToString:@"PRESSED"]) {
                    BOOL geoTagging = [Global showGeoTagging];
                    geoTagging = !geoTagging;
                    [Global setShowGetTagging:geoTagging];
                    [self resetGeoTag];
                }
                
                break;
            case kGripSettingGrid:
                if ([value isEqualToString:@"PRESSED"]) {
                    NSInteger gridType = self.gridType;
                    gridType --;
                    
                    if (gridType < 0) {
                        gridType = 3;
                    }
                    
                    if (self.aspectRatio == kAspectType11) {
                        self.gridType = gridType % 2;
                    } else {
                        self.gridType = gridType % 4;
                    }
                    
                    [self showGridSettingView];
                }
                
                break;
            case kGripSettingCameraMode:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self switchVideo:nil];
                }
                
                break;
            case kGripSettingCameraType:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self cameraSwitch:nil];
                }
                
                break;
            case kGripSettingPreference:
                if ([value isEqualToString:@"PRESSED"]) {
                    if (self.settingVC) {
                        [self.settingVC dismissViewControllerAnimated:YES completion:^{
                            self.settingVC = nil;
                        }];
                    } else {
                        [self willShowSettingView];
                    }
                }
                break;
            case kGripSettingPhotoPreview:
                if ([value isEqualToString:@"PRESSED"]) {
                    if (self.previewVC) {
                        [self dismissPreviewImage];
                    } else {
                        [self showPreviewImage];
                    }
                }
                break;
            case kGripSettingWhiteBalance:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self decreaseWhiteBalance];
                    [self showWhiteBalanceView];
                }
                
                break;
            case kGripSettingZoom:
                if ([value isEqualToString:@"PRESSED"]) {
                    [self startZoomingOut];
                }
                else {
                    [self stopZoomingOut];
                }
                break;
            default:
                break;
        }
    }
    else if ([name isEqualToString:@"pictureButton"]) {
        [self takePhoto:self];
    }
}

#pragma mark - IBAction

-(IBAction)deviceButtonPressed:(id)sender {
    if ([self isShowingPopover]) {
        [self _hidePopover];
    }
    else {
        [self _showPopover];
    }
}

- (IBAction)tapSetting:(id)sender {
    if (!self.settingView) {
        
        if (self.notifyView) {
            [self.notifyView removeFromSuperview];
            self.notifyView = nil;
        }
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"SettingMenuView" owner:self options:nil];
        SettingMenuView *settingsView = nibs.firstObject;
        settingsView.delegate = self;
        [settingsView setFrame:_settingContainView.bounds];
        [_settingContainView addSubview:settingsView];
        self.settingView = settingsView;
        [_settingButton setSelected:YES];
        [_settingContainView setHidden:NO];
        [settingsView setOrientation:_currentOrientaion];
        
        [self resetLeftMode];
        
        __block CGRect settingFrame = settingsView.frame;
        
        settingFrame.origin.y = -_settingContainView.bounds.size.height;
        
        [settingsView setFrame:settingFrame];
        
        [UIView animateWithDuration:0.3 animations:^{
            settingFrame.origin.y = 0;
            [settingsView setFrame:settingFrame];
        }];
    } else {
        __block CGRect settingFrame = self.settingView.frame;
        __block SettingMenuView *settingView = self.settingView;
        
        [_settingButton setSelected:NO];
        
        [UIView animateWithDuration:0.3 animations:^{
            settingFrame.origin.y = -_settingContainView.bounds.size.height;
            [settingView setFrame:settingFrame];
        } completion:^(BOOL finished) {
            [settingView removeFromSuperview];
            
            self.settingView = nil;
            [_settingContainView setHidden:YES];
        }];
    }
}

- (IBAction)tapGripShootSetting:(id)sender {
    GripShootSettingsVC *settingVC = [[GripShootSettingsVC alloc] init];
    UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:settingVC];
    [navigationVC.navigationBar setHidden:YES];
    
    [self presentViewController:navigationVC animated:YES completion:^{
        
    }];
}

- (IBAction)tapSkipConnection:(id)sender {
    _introView.hidden = YES;
    self.linkLabel.hidden = YES;
    
    [animationTimer invalidate];
    animationTimer = nil;
    
    self.remoteButton.selected = NO;
    [_table reloadData];
    
    if ([self isShowingPopover])
        [self _hidePopover];
}

-(IBAction)reviewButtonPressed:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

-(IBAction)takePhoto:(id)sender {
    if (self.captureButton.userInteractionEnabled == NO)
        return;
    
    if (_videoRecordingTimer) {
        [_videoRecordingTimer invalidate];
        _videoRecordingTimer = nil;
    }
    
    self.captureButton.selected = YES;
    
    [self.stillCamera startCameraCapture];
    
    if (_captureMode == kCaptureModeVideo) {
        // Check device memory
        
        if (!_recordingVideo) {
            BOOL isDiskSpaceAvailable = [ImageCaptureViewController availableDiskSpaceInBytes] > VideoRequiredMinimumDiskSpaceInBytes;
            
            
            if (!isDiskSpaceAvailable) {
                NSLog(@"%llu", VideoRequiredMinimumDiskSpaceInBytes - [ImageCaptureViewController availableDiskSpaceInBytes]);
                [ImageCaptureViewController showMemoryWarning];
                return;
            } else {
                NSLog(@"%llu", [ImageCaptureViewController availableDiskSpaceInBytes] - VideoRequiredMinimumDiskSpaceInBytes);
            }
        }
       	
        if (!_recordingVideo)
            [self startRecordingVideo];
        else
            [self stopRecordingVideo];
        
    }
    else
    {
        
        // Check device memory
        
        BOOL isDiskSpaceAvailable = [ImageCaptureViewController availableDiskSpaceInBytes] > PhotoRequiredMinimumDiskSpaceInBytes;
        
        if (!isDiskSpaceAvailable) {
            [ImageCaptureViewController showMemoryWarning];
            return;
        }
        
        [self.filter removeTarget:self.cameraPreview];
        
        [self capturePhoto];
        
        
    }
}

-(IBAction)switchVideo:(id)sender {
    if (_recordingVideo) {
        return;
    }
    
    [self.filter removeTarget:cameraPreview];
    
    if (_captureMode == kCaptureModePhoto) {
        [self setVideoMode];
        
        AVCaptureSession *session = self.stillCamera.captureSession;
        [session beginConfiguration];
        session.sessionPreset = AVCaptureSessionPresetHigh;
        [session commitConfiguration];
        
        [_switchModeButton setImage:[UIImage imageNamed:@"photo_mode"] forState:UIControlStateNormal];
        [_switchModeButton setImage:[UIImage imageNamed:@"photo_mode_selected"] forState:UIControlStateHighlighted];
        
        
    } else if(_captureMode == kCaptureModeVideo){
        
        [self setPhotoMode];
        
        AVCaptureSession *session = self.stillCamera.captureSession;
        [session beginConfiguration];
        session.sessionPreset = AVCaptureSessionPresetPhoto;
        [session commitConfiguration];
        //captureVideoPreviewLayer.frame = [cameraPreview bounds];
        
        
        [self positionPreviewForPhoto];
        
        [_switchModeButton setImage:[UIImage imageNamed:@"video_mode"] forState:UIControlStateNormal];
        [_switchModeButton setImage:[UIImage imageNamed:@"video_mode_selected"] forState:UIControlStateHighlighted];
        
    } else {
        NSLog(@"Current device Error");
    }
    
    
    [self.stillCamera.inputCamera lockForConfiguration:nil];
    
    self.scaleFactor = 1.0;
    
    if ([self.stillCamera.inputCamera respondsToSelector:@selector(setVideoZoomFactor:)])
        self.stillCamera.inputCamera.videoZoomFactor = self.scaleFactor;
    
    [self.stillCamera.inputCamera unlockForConfiguration];
    
    if (_captureMode == kCaptureModeVideo) {
        [self configureMovieWriter];
    }
    
    CGAffineTransform transformScaleIn = CGAffineTransformMakeScale([self scaleFactor], [self scaleFactor]);
    self.cameraPreview.transform = transformScaleIn;
    
    [self.filter addTarget:self.cameraPreview];
    
    if (flashStatus == FLASH_LIGHT) {
        [self turnFlash:YES];
    }
}

-(IBAction)cameraSwitch:(id)sender {
    if (_captureMode == kCaptureModeVideo){
        [self stopRecordingVideo];
    }
    
    [self.filter removeTarget:cameraPreview];
    
    [self.stillCamera rotateCamera];
    
    if(usingFrontCamera){
        usingFrontCamera = NO;
        [[self flashButton] setHidden:NO];
        _cameraContainerView.transform = CGAffineTransformIdentity;
    }
    else {
        usingFrontCamera = YES;
        [[self flashButton] setHidden:YES];
        _cameraContainerView.layer.transform = CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f);
        _cameraContainerView.transform = CGAffineTransformScale(_cameraContainerView.transform, 1, -1);
    }
    
    if (_captureMode == kCaptureModeVideo) {
        [self setVideoMode];
        [self configureMovieWriter];
    }
    
    
    [self.filter addTarget:cameraPreview];
    self.scaleFactor = 1.0;
    
    if (flashStatus == FLASH_LIGHT) {
        [self turnFlash:YES];
    }
}

#pragma mark - Bluetooth connection delegate

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [EMConnectionManager sharedManager]) {
        EMConnectionState state = [[EMConnectionManager sharedManager] connectionState];
        //TFLog(@"Connection state: %d", state);
        if (state == EMConnectionStatePending || state == EMConnectionStatePendingForDefaultSchema) {
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(animate) userInfo:nil repeats:YES];
            [animationTimer fire];
            [_connectingImgView setHidden:NO];
            [_logoButton setHidden:YES];
            
            if ([self isShowingPopover])
                [self _hidePopover];
        }
        else if (state == EMConnectionStateConnected) {
            
            [_introImageView stopAnimating];
            _introView.hidden = YES;
            self.linkLabel.hidden = YES;
            
            [_connectingImgView setHidden:YES];
            [_logoButton setHidden:NO];
            
            [animationTimer invalidate];
            animationTimer = nil;
            self.remoteButton.selected = YES;
            [_table reloadData];
            
            [ImageCaptureViewController checkDeviceStorage];
            
            if ([self isShowingPopover])
                [self _hidePopover];
        }
        else if (state == EMConnectionStateInvalidSchemaHash || state == EMConnectionStateSchemaNotFound) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unknown device", @"Title for unknown device alert") message:NSLocalizedString(@"The device you are attempting to connect to is not known by this application.", @"Message for unknown device alert") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"Close button") otherButtonTitles:nil];
            [alert show];
            [animationTimer invalidate];
            animationTimer = nil;
            
            [_connectingImgView setHidden:YES];
            [_logoButton setHidden:NO];
            
            [_introImageView startAnimating];
            _introView.hidden = NO;
            self.linkLabel.hidden = NO;
            
            self.remoteButton.selected = NO;
        }
        else {
            [animationTimer invalidate];
            animationTimer = nil;
            
            [_connectingImgView setHidden:YES];
            [_logoButton setHidden:NO];
            
            [_introImageView startAnimating];
            _introView.hidden = NO;
            self.linkLabel.hidden = NO;
            
            [self.remoteButton setSelected:NO];
            [self setDevices:[[EMConnectionListManager sharedManager] devices]];
            [_table reloadData];
        }
    } else if (object == [EMConnectionListManager sharedManager]) {
        EMConnectionState state = [[EMConnectionManager sharedManager] connectionState];
        [self setDevices:[[EMConnectionListManager sharedManager] devices]];
        [_table reloadData];
        //NSLog(@"here pressed");
        if (![self isShowingPopover] && (self.devices.count >0) && (state != EMConnectionStateConnected))
            [self _showPopover];
    } else  if ( context == (__bridge void *)GripShootCaptureStillImageIsCapturingStillImageObserverContext) {
        
        BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if ( isCapturingStillImage ) {
            NSLog(@"Will Capture Image");
            
            CATransition *shutterAnimation = [CATransition animation];
            [shutterAnimation setDelegate:self];
            [shutterAnimation setDuration:0.4];
            
            shutterAnimation.timingFunction = UIViewAnimationCurveEaseInOut;
            [shutterAnimation setType:@"cameraIris"];
            [shutterAnimation setValue:@"cameraIris" forKey:@"cameraIris"];
            CALayer *cameraShutter = [[CALayer alloc]init];
            [cameraShutter setBounds:CGRectMake(0.0, 0.0, 320.0, 425.0)];
            [self.view.layer addSublayer:cameraShutter];
            [self.view.layer addAnimation:shutterAnimation forKey:@"cameraIris"];
            
        } else {
            NSLog(@"Did Capture Image");
        }
        
    }
}

#pragma mark - Device Orientation

-(CGFloat)degreesForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGFloat value;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            value = 0.0f;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            value = 180.0f;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            value = 90.0f;
            break;
        case UIInterfaceOrientationLandscapeRight:
            value = 270.0f;
            break;
        default:
            value = 0.0f;
            break;
    }
    return value;
}

-(void)simulateInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation fromInterfaceOrientation:(UIInterfaceOrientation)fromOrientation {
    
    if ([[self videoTimer] timer]) {
        return;
    }
    
    NSLog(@"%d", toInterfaceOrientation);
    
    
    _currentOrientaion = toInterfaceOrientation;
    
    //UIViewAutoresizing fixedRight = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    //UIViewAutoresizing fixedLeft = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    //UIViewAutoresizing fixedTop = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    //UIViewAutoresizing fixedBottom = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    //CGRect newTopBarFrame;
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            //newTopBarFrame = CGRectMake(HORIZONTAL_TOP_BAR_PADDING, 50, 320 - (2 * HORIZONTAL_TOP_BAR_PADDING), 44);
            //[_rightTopBarButtonShell setAutoresizingMask:fixedRight];
            //[_leftTopBarButtonShell setAutoresizingMask:fixedLeft];
            break;
            /*
             case UIInterfaceOrientationLandscapeLeft:
             [_rightTopBarButtonShell setAutoresizingMask:fixedTop];
             [_leftTopBarButtonShell setAutoresizingMask:fixedBottom];
             newTopBarFrame = CGRectMake(6, 50 + HORIZONTAL_TOP_BAR_PADDING, 44, self.view.bounds.size.height -54 - (HORIZONTAL_TOP_BAR_PADDING * 2));
             break;
             case UIInterfaceOrientationLandscapeRight:
             [_rightTopBarButtonShell setAutoresizingMask:fixedBottom];
             [_leftTopBarButtonShell setAutoresizingMask:fixedTop];
             newTopBarFrame = CGRectMake(320 - 50, 50 + HORIZONTAL_TOP_BAR_PADDING, 44, self.view.bounds.size.height -54 - (HORIZONTAL_TOP_BAR_PADDING * 2));
             
             break;
             */
        default:
            break;
    }
    
    //remoteButton.center = CGPointMake( newTopBarFrame.size.width/2, newTopBarFrame.size.height/2);
    /*
     if (!CGRectEqualToRect(newTopBarFrame, [_topButtonsBarView frame])) {
     [_topButtonsBarView setAlpha:0.0];
     [_topButtonsBarView setFrame:newTopBarFrame];
     }
     */
    //NSLog(@"%@", NSStringFromCGRect(newTopBarFrame));
    //NSLog(@"%@", NSStringFromCGPoint(remoteButton.center));
    
    
    // Technically, the interface is always in portrait
    CGFloat degreeDiff = [self degreesForInterfaceOrientation:UIInterfaceOrientationPortrait] - [self degreesForInterfaceOrientation:toInterfaceOrientation];
    
    CGFloat degreeDiff2 = [self degreesForInterfaceOrientation:UIInterfaceOrientationLandscapeRight] - [self degreesForInterfaceOrientation:toInterfaceOrientation];
    
    [UIView animateWithDuration:0.2 animations:^{
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(degreeDiff));
        
        [captureButton setTransform:rotateTransform];
        [reviewButton setTransform:rotateTransform];
        [_settingButton setTransform:rotateTransform];
        
        [_switchToVideoImage setTransform:rotateTransform];
        [_switchToCameraImage setTransform:rotateTransform];
        
        [remoteButton setTransform:rotateTransform];
        [flashButton setTransform:rotateTransform];
        [timeLabel setTransform:rotateTransform];
        [timeLabelBackground setTransform:rotateTransform];
        [cameraSwitch setTransform:rotateTransform];
        [infoButton setTransform:rotateTransform];
        
        [self.photoLibButton setTransform:rotateTransform];
        [self.HUD setTransform:rotateTransform];
        
        [_switchModeButton setTransform:rotateTransform];
        [_devicePickerView setTransform:rotateTransform];
        
        [_shortcutView setTransform:rotateTransform];
        [_shortcutView setFrame:[self frameForShortcutViewInOrientation:toInterfaceOrientation]];
        
        [self.settingView setOrientation:toInterfaceOrientation];
        [self.notifyView setOrientation:toInterfaceOrientation];
        
        [_deviceControlView setTransform:rotateTransform];
        
        [_devicePickerView setFrame:[self frameForDevicePickerInInterfaceOrientation:toInterfaceOrientation]];
        
        if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && ![_devicePickerView isFlipped]) {
            [_devicePickerView setFlipped:YES];
        }
        else if ([_devicePickerView isFlipped]) {
            [_devicePickerView setFlipped:NO];
        }
        
        
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        {
            CGAffineTransform rotateTransform2 = CGAffineTransformMakeRotation(DegreesToRadians(degreeDiff2));
            [_introImageView setTransform:rotateTransform2];
            
            //CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(90));
            
            [self.linkLabel setTransform:CGAffineTransformTranslate(rotateTransform, 0, 120.0)];
        }
        //[_topButtonsBarView setAlpha:1.0];
    }];
    
    simulatedOrientation = toInterfaceOrientation;
    
    [self performSelector:@selector(adjustButtons) withObject:nil afterDelay:0.2];
}


-(void)adjustButtons
{
    CGPoint pt = [_leftTopBarButtonShell convertPoint:flashButton.center fromView:flashButton];
    CGPoint flashPoint = [_topButtonsBarView convertPoint:pt fromView:_leftTopBarButtonShell];
    
    //NSLog(@"flashPoint %@", NSStringFromCGPoint(flashPoint));
    
    pt = [cameraView convertPoint:flashPoint fromView:_topButtonsBarView];
    
    biggerFlashButton.center = pt;
    
    
    pt = [_rightTopBarButtonShell convertPoint: cameraSwitch.center fromView:cameraSwitch];
    CGPoint switchPoint = [_topButtonsBarView convertPoint:pt fromView:_rightTopBarButtonShell];
    
    //NSLog(@"switchPoint %@", NSStringFromCGPoint(switchPoint));
    pt = [cameraView convertPoint:switchPoint fromView:_topButtonsBarView];
    
    biggerSwitchButton.center = pt;
    
    //remoteButton.center = CGPointMake((switchPoint.x - flashPoint.x)/2, switchPoint.y);
    
    //NSLog(@"remoteButton %@", NSStringFromCGPoint(remoteButton.center));
    
    biggerRemoteButton.center = _switchModeButton.center;
    
}


-(void)animate{
    switch (animationCount) {
        case 0:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_00.png"]];
            animationCount++;
            break;
        case 1:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_01.png"]];
            animationCount++;
            break;
        case 2:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_02.png"]];
            animationCount++;
            break;
        case 3:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_03.png"]];
            animationCount++;
            break;
        case 4:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_04.png"]];
            animationCount++;
            break;
        case 5:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_05.png"]];
            animationCount++;
            break;
        case 6:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_06.png"]];
            animationCount++;
            break;
        case 7:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_07.png"]];
            animationCount++;
            break;
        case 8:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_08.png"]];
            animationCount++;
            break;
        case 9:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_09.png"]];
            animationCount++;
            break;
        case 10:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_10.png"]];
            animationCount++;
            break;
        case 11:
            [_connectingImgView setImage:[UIImage imageNamed:@"device_connect_animation_11.png"]];
            animationCount = 0;
            break;
            
        default:
            break;
    }
}

-(void)interfaceChanged:(NSNotification *)notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        [self simulateInterfaceOrientation:UIInterfaceOrientationLandscapeRight fromInterfaceOrientation:_currentOrientation];
        _currentOrientation = UIInterfaceOrientationLandscapeLeft;
    }
    else if (orientation == UIDeviceOrientationLandscapeRight) {
        [self simulateInterfaceOrientation:UIInterfaceOrientationLandscapeLeft fromInterfaceOrientation:_currentOrientation];
        _currentOrientation = UIInterfaceOrientationLandscapeRight;
    }
    else if (orientation == UIDeviceOrientationPortrait) {
        [self simulateInterfaceOrientation:UIInterfaceOrientationPortrait fromInterfaceOrientation:_currentOrientation];
        _currentOrientation = UIInterfaceOrientationPortrait;
    }
    else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        [self simulateInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown fromInterfaceOrientation:_currentOrientation];
        _currentOrientation = UIInterfaceOrientationPortraitUpsideDown;
    }
    else if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown) {
        
    }
}

-(void)applicationUnloaded{
    NSLog(@"unload the gallery");
    
}

- (void)setAspectRatio:(AspectType)aspectRatio {
    NSLog(@"%f", self.view.frame.size.height);
    _aspectRatio = aspectRatio;
    
    if (self.captureMode == kCaptureModePhoto) {
        _photoAspectRatio = aspectRatio;
    }
    
    if (aspectRatio == kAspectType11) {
        [_cameraContainerView setFrame:CGRectMake(0, 0, 320, 320)];
        [_cameraContainerView setCenter:self.view.center];
        [_topbarBackgroundView setAlpha:0];
        [_bottombarBackgroundView setAlpha:0];
    } else {
        CGFloat ratioX=1, ratioY = 1;
        if (aspectRatio == kAspectType43) {
            ratioX = 3;
            ratioY = 4;
        } else if (aspectRatio == kAspectType169) {
            
            ratioX = 9;
            ratioY = 16;
        }
        
        CGFloat width = self.view.frame.size.height / ratioY * ratioX;
        
        if (width <= self.view.frame.size.width) {
            if (width > self.view.frame.size.width - 10) {
                width = self.view.frame.size.width;
            }
            
            [_bottombarBackgroundView setAlpha:0.7];
            
            [_cameraContainerView setFrame:CGRectMake((self.view.bounds.size.width - width) / 2, 0, width, self.view.bounds.size.height)];
            [_topbarBackgroundView setAlpha:0.7];
        } else {
            CGFloat height = self.view.frame.size.width / ratioX * ratioY;
            
            if (height > self.view.frame.size.height - 10) {
                height = self.view.frame.size.height;
            }
            
            if ((self.view.bounds.size.height - height) / 2 < _topbarBackgroundView.bounds.size.height) {
                [_bottombarBackgroundView setAlpha:0.7];
            } else {
                [_topbarBackgroundView setAlpha:0];
                [_bottombarBackgroundView setAlpha:0];
            }
            
            [_cameraContainerView setFrame:CGRectMake(0, (self.view.bounds.size.height - height) / 2, self.view.bounds.size.width, height)];
        }
    }
    
    [self resetGripView];
}

- (void)setGridType:(GridType)gridType {
    _gridType = gridType;
    [self resetGripView];
}

- (void)resetGripView {
    if (self.gridType == kGridTypeNone) {
        [_gridBGView setImage:nil];
    } else if (self.gridType == kGridTypeSprial) {
        if (self.aspectRatio == kAspectType11) {
            [_gridBGView setImage:nil];
            _gridType = kGridTypeNone;
        } else if (self.aspectRatio == kAspectType43) {
            [_gridBGView setImage:[UIImage imageNamed:@"spiral_4_3"]];
        } else {
            [_gridBGView setImage:[UIImage imageNamed:@"spiral_16_9"]];
        }
    } else if (self.gridType == kGridTypeTriangle) {
        if (self.aspectRatio == kAspectType11) {
            [_gridBGView setImage:nil];
            _gridType = kGridTypeNone;
        } else if (self.aspectRatio == kAspectType43) {
            [_gridBGView setImage:[UIImage imageNamed:@"triangle_4_3"]];
        } else {
            [_gridBGView setImage:[UIImage imageNamed:@"triangle_16_9"]];
        }
    } else if (self.gridType == kGridTypeSquare) {
        if (self.aspectRatio == kAspectType11) {
            [_gridBGView setImage:[UIImage imageNamed:@"grid_1_1"]];
        } else if (self.aspectRatio == kAspectType43) {
            [_gridBGView setImage:[UIImage imageNamed:@"grid_4_3"]];
        } else {
            [_gridBGView setImage:[UIImage imageNamed:@"grid_16_9"]];
        }
    }
}

- (void)resetSCN {
    if ([Global hideIndicator]) {
        [_scnButton setHidden:YES];
    } else {
        [_scnButton setHidden:NO];
    }
    
    GPUImageWhiteBalanceFilter *whiteFilter = (GPUImageWhiteBalanceFilter *)self.whiteBalanceFilter;
    GPUImageExposureFilter *exposureFilter = (GPUImageExposureFilter *)self.exposureFilter;
    
    if (whiteFilter.temperature == 5000 && exposureFilter.exposure == 0) {        
        [_scnButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_scnButton setTitle:@"AUTO" forState:UIControlStateNormal];
    } else {
        [_scnButton setTitleColor:[UIColor colorWithRed:255.0/255 green:21.0/255 blue:9.0/255 alpha:1.0] forState:UIControlStateNormal];
        [_scnButton setTitle:@"SCN" forState:UIControlStateNormal];
    }
}

- (void)resetGeoTag {
    if ([Global hideIndicator]) {
        [_geoButton setHidden:YES];
    } else {
        [_geoButton setHidden:NO];
    }
    
    if ([Global showGeoTagging]) {
        [_geoButton setSelected:YES];
    } else {
        [_geoButton setSelected:NO];
    }
}

- (void)resetLeftMode {
        NSLog(@"%f", self.view.frame.size.height);
        
        if ([Global leftMode]) {
            [_topButtonsBarView setFrame:CGRectMake(0, self.view.bounds.size.height - _topButtonsBarView.bounds.size.height, 320, _topButtonsBarView.bounds.size.height)];
            [_bottomBar setFrame:CGRectMake(0, 0, 320, _bottomBar.bounds.size.height)];
            
            _settingContainView.transform = CGAffineTransformMakeScale(-1, 1);
            _settingContainView.transform = CGAffineTransformRotate(_settingContainView.transform, M_PI);
            
            for (UIView *subview in _settingView.subviews) {
                subview.transform = CGAffineTransformMakeScale(-1, 1);
                subview.transform = CGAffineTransformRotate(subview.transform, M_PI);
            }
            
            for (UIView *subview in _notifyView.subviews) {
                subview.transform = CGAffineTransformMakeScale(-1, 1);
                subview.transform = CGAffineTransformRotate(subview.transform, M_PI);
            }
            
            
        } else {
            NSLog(@"%f, %f, %f", self.view.bounds.size.height, _topButtonsBarView.bounds.size.height, _topButtonsBarView.bounds.size.height);
            
            [_bottomBar setFrame:CGRectMake(0, self.view.frame.size.height - _bottomBar.bounds.size.height, 320, _bottomBar.bounds.size.height)];
            [_topButtonsBarView setFrame:CGRectMake(0, 0, 320, _topButtonsBarView.bounds.size.height)];
            
            _settingContainView.transform = CGAffineTransformIdentity;
            
            for (UIView *subview in _settingView.subviews) {
                subview.transform =CGAffineTransformIdentity;
            }
            
            for (UIView *subview in _notifyView.subviews) {
                subview.transform =CGAffineTransformIdentity;
            }
        }
    
}

- (void)resetStorageMemory {
    if ([Global hideIndicator]) {
        [_storageButton setHidden:YES];
    } else {
        [_storageButton setHidden:NO];
    }
    
    uint64_t availableBytes = [ImageCaptureViewController availableDiskSpaceInBytes];
    [self setStorageLabel:availableBytes];
}

- (void)resetSettingView {
    
}

- (void)decreaseExposure {
    GPUImageExposureFilter *filter = (GPUImageExposureFilter *)self.exposureFilter;
    
    if (filter.exposure == -2) {
        filter.exposure = 2;
    } else if (filter.exposure == -1.5) {
        filter.exposure = -2;
    } else if (filter.exposure == -1) {
        filter.exposure = -1.5;
    } else if (filter.exposure == -0.5) {
        filter.exposure = -1;
    } else if (filter.exposure == 0) {
        filter.exposure = -0.5;
    } else if (filter.exposure == 0.5) {
        filter.exposure = 0;
    } else if (filter.exposure == 1.0) {
        filter.exposure = 0.5;
    } else if (filter.exposure == 1.5) {
        filter.exposure = 1.0;
    } else if (filter.exposure == 2) {
        filter.exposure = 1.5;
    } else {
        filter.exposure = -2;
    }
    
    [self resetSCN];
}

- (void)increaseExposure {
    GPUImageExposureFilter *filter = (GPUImageExposureFilter *)self.exposureFilter;
    
    if (filter.exposure == -2) {
        filter.exposure = -1.5;
    } else if (filter.exposure == -1.5) {
        filter.exposure = -1;
    } else if (filter.exposure == -1) {
        filter.exposure = -0.5;
    } else if (filter.exposure == -0.5) {
        filter.exposure = 0;
    } else if (filter.exposure == 0) {
        filter.exposure = 0.5;
    } else if (filter.exposure == 0.5) {
        filter.exposure = 1.0;
    } else if (filter.exposure == 1.0) {
        filter.exposure = 1.5;
    } else if (filter.exposure == 1.5) {
        filter.exposure = 2;
    } else if (filter.exposure == 2) {
        filter.exposure = -2;
    } else {
        filter.exposure = -2;
    }
    
    [self resetSCN];
}

- (void)increaseWhiteBalance {
    GPUImageWhiteBalanceFilter *filter = (GPUImageWhiteBalanceFilter *)self.whiteBalanceFilter;
    
    if (filter.temperature == 5000) {
        [filter setTemperature:1000];
        [filter setTint:21];
    } else if (filter.temperature == 1000) {
        [filter setTemperature:2000];
        [filter setTint:21];
    } else if (filter.temperature == 2000) {
        [filter setTemperature:3000];
        [filter setTint:0];
    } else if (filter.temperature == 3000) {
        [filter setTemperature:4000];
        [filter setTint:21];
    } else if (filter.temperature == 4000) {
        [filter setTemperature:5500];
        [filter setTint:10];
    } else if (filter.temperature == 5500) {
        [filter setTemperature:6500];
        [filter setTint:10];
    } else if (filter.temperature == 6500) {
        [filter setTemperature:7000];
        [filter setTint:10];
    } else if (filter.temperature == 7000) {
        [filter setTemperature:8000];
        [filter setTint:10];
    } else if (filter.temperature == 8000) {
        [filter setTemperature:9000];
        [filter setTint:10];
    } else if (filter.temperature == 9000) {
        [filter setTemperature:10000];
        [filter setTint:10];
    } else if (filter.temperature == 10000) {
        [filter setTemperature:5000];
        [filter setTint:0];
    } else {
        [filter setTemperature:5000];
        [filter setTint:0];
    }
    
    [self resetSCN];
}

- (void)decreaseWhiteBalance {
    GPUImageWhiteBalanceFilter *filter = (GPUImageWhiteBalanceFilter *)self.whiteBalanceFilter;
    
    if (filter.temperature == 5000) {
        [filter setTemperature:10000];
        [filter setTint:10];
    } else if (filter.temperature == 1000) {
        [filter setTemperature:5000];
        [filter setTint:0];
    } else if (filter.temperature == 2000) {
        [filter setTemperature:1000];
        [filter setTint:21];
    } else if (filter.temperature == 3000) {
        [filter setTemperature:2000];
        [filter setTint:21];
    } else if (filter.temperature == 4000) {
        [filter setTemperature:3000];
        [filter setTint:0];
    } else if (filter.temperature == 5500) {
        [filter setTemperature:4000];
        [filter setTint:21];
    } else if (filter.temperature == 6500) {
        [filter setTemperature:5500];
        [filter setTint:10];
    } else if (filter.temperature == 7000) {
        [filter setTemperature:6500];
        [filter setTint:10];
    } else if (filter.temperature == 8000) {
        [filter setTemperature:7000];
        [filter setTint:10];
    } else if (filter.temperature == 9000) {
        [filter setTemperature:8000];
        [filter setTint:10];
    } else if (filter.temperature == 10000) {
        [filter setTemperature:9000];
        [filter setTint:10];
    } else {
        [filter setTemperature:5000];
        [filter setTint:0];
    }
    
    [self resetSCN];
}

- (void)dismissPreviewImage {
    [self.previewVC dismissViewControllerAnimated:YES completion:^{
        self.previewVC = nil;
    }];
}

- (void)showPreviewImage {
    if (self.lastCapturedImage) {
        PreviewViewController *previewVC = [[PreviewViewController alloc] init];
        previewVC.image = self.lastCapturedImage;
        UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:previewVC];
        previewVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissPreviewImage)];
        previewVC.title = @"Preview";
        [self presentViewController:navigationVC animated:YES completion:NULL];
        self.previewVC = previewVC;
    }
}

- (void)showWhiteBalanceView {
    if (self.settingView) {
        if (self.settingView.subMenuIndex != 2) {
            [self.settingView tapWhiteBalance:nil];
        } else {
            [self.settingView tapWhiteBalance:nil];
            [self.settingView tapWhiteBalance:nil];
        }
    } else {
        if (self.notifyView) {
            [self.notifyView removeFromSuperview];
            self.notifyView = nil;
        }
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"SettingMenuView" owner:self options:nil];
        SettingMenuView *settingsView = nibs.firstObject;
        settingsView.delegate = self;
        [settingsView setFrame:_settingContainView.bounds];
        [_settingContainView addSubview:settingsView];
        self.notifyView = settingsView;
        [_settingContainView setHidden:NO];
        [settingsView setOrientation:_currentOrientaion];
        
        [self resetLeftMode];
        [settingsView tapWhiteBalance:nil];
        [settingsView.menuView setHidden:YES];
        
        CGRect settingFrame = settingsView.frame;
        settingFrame.origin.y = 0;
        [settingsView setFrame:settingFrame];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.notifyView == settingsView) {
                [settingsView removeFromSuperview];
                
                self.settingView = nil;
                [_settingContainView setHidden:YES];
            }
        });
    }
}

- (void)showExposureView {
    if (self.settingView) {
        if (self.settingView.subMenuIndex != 1) {
            [self.settingView tapExposure:nil];
        } else {
            [self.settingView tapExposure:nil];
            [self.settingView tapExposure:nil];
        }
    } else {
        if (self.notifyView) {
            [self.notifyView removeFromSuperview];
            self.notifyView = nil;
        }
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"SettingMenuView" owner:self options:nil];
        SettingMenuView *settingsView = nibs.firstObject;
        settingsView.delegate = self;
        [settingsView setFrame:_settingContainView.bounds];
        [_settingContainView addSubview:settingsView];
        self.notifyView = settingsView;
        [_settingContainView setHidden:NO];
        [settingsView setOrientation:_currentOrientaion];
        
        [self resetLeftMode];
        [settingsView tapExposure:nil];
        [settingsView.menuView setHidden:YES];
        
        CGRect settingFrame = settingsView.frame;
        settingFrame.origin.y = 0;
        [settingsView setFrame:settingFrame];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.notifyView == settingsView) {
                [settingsView removeFromSuperview];
                
                self.settingView = nil;
                [_settingContainView setHidden:YES];
            }
        });
    }
}

- (void)showGridSettingView {
    if (self.settingView) {
        if (self.settingView.subMenuIndex != 3) {
            [self.settingView tapGrid:nil];
        } else {
            [self.settingView tapGrid:nil];
            [self.settingView tapGrid:nil];
        }
    } else {
        if (self.notifyView) {
            [self.notifyView removeFromSuperview];
            self.notifyView = nil;
        }
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"SettingMenuView" owner:self options:nil];
        SettingMenuView *settingsView = nibs.firstObject;
        settingsView.delegate = self;
        [settingsView setFrame:_settingContainView.bounds];
        [_settingContainView addSubview:settingsView];
        self.notifyView = settingsView;
        [_settingContainView setHidden:NO];
        [settingsView setOrientation:_currentOrientaion];
        
        [self resetLeftMode];
        [settingsView tapGrid:nil];
        [settingsView.menuView setHidden:YES];
        
        CGRect settingFrame = settingsView.frame;
        settingFrame.origin.y = 0;
        [settingsView setFrame:settingFrame];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.notifyView == settingsView) {
                [settingsView removeFromSuperview];
                
                self.settingView = nil;
                [_settingContainView setHidden:YES];
            }
        });
    }
}

#pragma mark - Geo Location

- (void)resetGeoLocation {
    
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    
    self.locationRequestID = [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyCity timeout:self.timeout delayUntilAuthorized:YES block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
        
        self.currentLocation = currentLocation;
        
    }];
}

#pragma mark - Camera Configuration

- (void)setupCamera {
    self.stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    
    _stillCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
    _stillCamera.horizontallyMirrorFrontFacingCamera = NO;
    _stillCamera.horizontallyMirrorRearFacingCamera = NO;
    
    self.filter = [[GPUImageFilterGroup alloc] init];
    
    GPUImageWhiteBalanceFilter *whiteBalance = [[GPUImageWhiteBalanceFilter alloc] init];
    [(GPUImageFilterGroup *)self.filter addFilter:whiteBalance];
    self.whiteBalanceFilter = whiteBalance;
    
    GPUImageExposureFilter *exposureFilter = [[GPUImageExposureFilter alloc] init];
    [(GPUImageFilterGroup *)self.filter addFilter:exposureFilter];
    [whiteBalance addTarget:exposureFilter];
    self.exposureFilter = exposureFilter;
    
    [(GPUImageFilterGroup *)self.filter setInitialFilters:[NSArray arrayWithObject:whiteBalance]];
    [(GPUImageFilterGroup *)self.filter setTerminalFilter:exposureFilter];
    
    [_stillCamera addTarget:self.filter];
    
    GPUImageView *filterView = (GPUImageView *)cameraPreview;
    [self.filter addTarget:filterView];
    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    NSError *error = nil;
    
    // flash
    if ([_stillCamera.inputCamera isFlashAvailable]){
        flashStatus = FLASH_AUTO;
        [_stillCamera.inputCamera lockForConfiguration:&error];
        if (error){
            NSLog(@"Error:%@", error);
        }
        [_stillCamera.inputCamera setFlashMode:AVCaptureFlashModeAuto];
    } else {
        flashStatus = FLASH_UNSUPPORTED;
        [self flashButtonIsHidden:YES];
    }
    
    [_stillCamera addAudioInputsAndOutputs];
    [_stillCamera startCameraCapture];
    
    [self.stillCamera.photoOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(GripShootCaptureStillImageIsCapturingStillImageObserverContext)];
}

- (AVCaptureDevice *)frontCamera{
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices){
        if (device.position == AVCaptureDevicePositionFront){
            captureDevice = device;
            break;
        }
    }//  couldn't find one on the front, so just get the default video
    if ( ! captureDevice){
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return captureDevice;
}

- (AVCaptureDevice *)backCamera{
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices){
        if (device.position == AVCaptureDevicePositionBack){
            captureDevice = device;
            break;
        }
    }
    //  couldn't find one on the front, so just get the default video device.
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

#pragma mark - Capture

- (void)configureMovieWriter {
    /*
     if (_movieWriter) {
     [_filter removeTarget:_movieWriter];
     self.stillCamera.audioEncodingTarget = nil;
     _movieWriter = nil;
     }
     
     CGSize recordingSize;
     
     if (self.aspectRatio == kAspectType11) {
     recordingSize = CGSizeMake(720, 720);
     } else if (self.aspectRatio == kAspectType43) {
     recordingSize = CGSizeMake(720, 960);
     } else {
     recordingSize = CGSizeMake(720, 1280);
     }
     
     NSURL *movieURL = [VideoDevice makeTemporaryVideoUrl];
     [[NSFileManager defaultManager] removeItemAtURL:movieURL error:nil];
     
     self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720, 1280) recordingSize:recordingSize];
     
     self.movieWriter.encodingLiveVideo = YES;
     [self.filter addTarget:self.movieWriter];
     self.stillCamera.audioEncodingTarget = self.movieWriter;
     */
}

- (void)stopRecordingVideo {
    if (_recordingVideo && self.captureButton.selected) {
        
        [videoTimer stopTimer];
        
        if (_videoRecordingTimer) {
            [_videoRecordingTimer invalidate];
            _videoRecordingTimer = nil;
        }
        
        //********
        
        [_filter removeTarget:_movieWriter];
        _stillCamera.audioEncodingTarget = nil;
        
        //*********
        
        timeLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        timeLabel.textColor = [UIColor whiteColor];
        
        NSURL *movieURL = _movieWriter.movieURL;
        
        [_movieWriter finishRecordingWithCompletionHandler:^{
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:movieURL]) {
                [library writeVideoAtPathToSavedPhotosAlbum:movieURL
                                            completionBlock:^(NSURL *assetURL, NSError *error){
                                                NSLog(@"Video saved in Assets");
                                                [[NSFileManager defaultManager] removeItemAtURL:movieURL error:nil];
                                                [self resetStorageMemory];
                                            }];
            }
        }];
        
        self.captureButton.selected = NO;
        [self cameraSwitchIsHidden:NO];
        _recordingVideo = NO;
        
        [self startMotionUpdates];
        
        //        [_filter removeTarget:cameraPreview];
        //        [self configureMovieWriter];
        //        [_filter addTarget:cameraPreview];
        
    }
}

- (void)startRecordingVideo {
    if (!_recordingVideo) {
        _recordingVideo = YES;
        
        [self videoTimerIsHidden:NO];
        [self cameraSwitchIsHidden:YES];
        [self.videoTimer startTimer];
        
        //********
        
        NSURL *movieURL = [VideoDevice makeTemporaryVideoUrl];
        [[NSFileManager defaultManager] removeItemAtURL:movieURL error:nil];
        
        CGSize recordingSize;
        
        if (self.aspectRatio == kAspectType11) {
            recordingSize = CGSizeMake(720, 720);
        } else if (self.aspectRatio == kAspectType43) {
            recordingSize = CGSizeMake(720, 960);
        } else {
            recordingSize = CGSizeMake(720, 1280);
        }
        
        self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:self.stillCamera.inputSize recordingSize:self.stillCamera.inputSize];
        
        
        // Set geo location info
        
        if ([Global showGeoTagging] && self.currentLocation) {
            
            NSArray *existingMetadataArray = self.movieWriter.assetWriter.metadata;
            NSMutableArray *newMetadataArray = nil;
            if (existingMetadataArray) {
                newMetadataArray = [existingMetadataArray mutableCopy];
            } else {
                newMetadataArray = [[NSMutableArray alloc] init];
            }
            
            CLLocationCoordinate2D location = self.currentLocation.coordinate;
            
            AVMutableMetadataItem *mutableItemLocation  = [[AVMutableMetadataItem alloc] init];
            mutableItemLocation.keySpace                = AVMetadataKeySpaceCommon;
            mutableItemLocation.key                     = AVMetadataCommonKeyLocation;
            mutableItemLocation.value                   = [NSString stringWithFormat:@"%+08.4lf%+09.4lf/", location.latitude, location.longitude];
            
            AVMutableMetadataItem *mutableItemModel     = [[AVMutableMetadataItem alloc] init];
            mutableItemModel.keySpace                   = AVMetadataKeySpaceCommon;
            mutableItemModel.key                        = AVMetadataCommonKeyModel;
            mutableItemModel.value                      = [[UIDevice currentDevice] model];
            
            [newMetadataArray addObject:mutableItemLocation];
            [newMetadataArray addObject:mutableItemModel];
            
            self.movieWriter.metaData = newMetadataArray;
        }
        
        self.movieWriter.encodingLiveVideo = YES;
        [self.filter addTarget:self.movieWriter];
        self.stillCamera.audioEncodingTarget = self.movieWriter;
        
        //********
        
        UIColor *timeColor = [UIColor colorWithRed:237.0/255 green:28.0/255 blue:36.0/255 alpha:1.0];
        timeLabel.layer.borderColor = timeColor.CGColor;
        timeLabel.textColor = timeColor;
        
        self.captureButton.selected = YES;
        _videoRecordingTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(videoTimerDidFire) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_videoRecordingTimer forMode:NSDefaultRunLoopMode];
        [self stopAutoFocus];
        
        
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        
        if ([self.stillCamera cameraPosition] == AVCaptureDevicePositionBack) {
            switch (deviceOrientation) {
                case UIDeviceOrientationPortrait:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformMakeRotation(M_PI_2)];
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformIdentity];
                    break;
                case UIDeviceOrientationLandscapeRight:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformMakeRotation(M_PI)];
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformMakeRotation(-M_PI_2)];
                    break;
                default:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformIdentity];
                    break;
            }
        } else {
            switch (deviceOrientation) {
                case UIDeviceOrientationPortrait:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformMakeRotation(-M_PI_2)];
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformIdentity];
                    break;
                case UIDeviceOrientationLandscapeRight:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformMakeRotation(M_PI)];
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformMakeRotation(M_PI_2)];
                    break;
                default:
                    [self.movieWriter startRecordingInOrientation:CGAffineTransformIdentity];
                    break;
            }
        }
        
    }
    
}

- (NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return (__bridge_transfer NSString *)uuidStringRef;
}

- (void)capturePhoto {
    self.captureButton.userInteractionEnabled = NO;
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    BOOL frontCam = usingFrontCamera;
    
    [self.stillCamera capturePhotoAsImageProcessedUpToFilter:_filter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        self.stillCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
        [self.filter addTarget:self.cameraPreview];
        
        self.captureButton.selected = NO;
        self.captureButton.userInteractionEnabled = YES;
        
        if ([NSThread isMainThread]) {
            NSLog(@"Main Thread");
        }

        dispatch_async(_imageProcessQueue, ^{
        
            // Save to assets library
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            
            NSMutableDictionary* metadata = [NSMutableDictionary dictionaryWithDictionary:self.stillCamera.currentCaptureMetadata];
            
            
            // Set geo location info
            
            if ([Global showGeoTagging] && self.currentLocation) {
                CLLocation *location = self.currentLocation;
                NSMutableDictionary *gps = [NSMutableDictionary dictionary];
                // GPS tag version
                [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
                
                // Time and date must be provided as strings, not as an NSDate object
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
                [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
                
                // Latitude
                [gps setObject: (location.coordinate.latitude < 0) ? @"S" : @"N"
                        forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
                [gps setObject:[NSNumber numberWithDouble:fabs(location.coordinate.latitude)]
                        forKey:(NSString *)kCGImagePropertyGPSLatitude];
                
                // Longitude
                [gps setObject: (location.coordinate.longitude < 0) ? @"W" : @"E"
                        forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
                [gps setObject:[NSNumber numberWithDouble:fabs(location.coordinate.longitude)]
                        forKey:(NSString *)kCGImagePropertyGPSLongitude];
                
                // Altitude
                if (!isnan(location.altitude)){
                    // NB: many get this wrong, it is an int, not a string:
                    [gps setObject:[NSNumber numberWithInt: location.altitude >= 0 ? 0 : 1]
                            forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
                    [gps setObject:[NSNumber numberWithDouble:fabs(location.altitude)]
                            forKey:(NSString *)kCGImagePropertyGPSAltitude];
                }
                
                // Speed, must be converted from m/s to km/h
                if (location.speed >= 0){
                    [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
                    [gps setObject:[NSNumber numberWithDouble:location.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
                }
                
                // Heading
                if (location.course >= 0){
                    [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
                    [gps setObject:[NSNumber numberWithDouble:location.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
                }
                
                metadata[(__bridge NSString*)kCGImagePropertyGPSDictionary] = gps;
            }
            
            
            
            UIImageOrientation imageOrientation = UIImageOrientationUp;
            metadata[(__bridge NSString*)kCGImagePropertyOrientation] = @(imageOrientation);
            
            // Get image size
            
            CGFloat rateX, rateY;
            CGFloat imageWidth, imageHeight;
            
            switch (self.aspectRatio) {
                case kAspectType43:
                    rateX = 4;
                    rateY = 3;
                    break;
                case kAspectType169:
                    rateX = 16;
                    rateY = 9;
                    break;
                case kAspectType11:
                    rateX = 1;
                    rateY = 1;
                    break;
                default:
                    rateX = 4;
                    rateY = 3;
                    break;
            }
            
            if (processedImage.size.width > processedImage.size.height) {
                if (processedImage.size.width / rateX > processedImage.size.height / rateY) {
                    imageWidth = processedImage.size.height / rateY * rateX;
                    imageHeight = processedImage.size.height;
                } else {
                    imageWidth = processedImage.size.width;
                    imageHeight = processedImage.size.width / rateX * rateY;
                }
            } else {
                if (processedImage.size.width / rateY > processedImage.size.height / rateX) {
                    imageWidth = processedImage.size.height / rateX * rateY;
                    imageHeight = processedImage.size.height;
                } else {
                    imageWidth = processedImage.size.width;
                    imageHeight = processedImage.size.width / rateY * rateX;
                }
            }
            
            if (imageWidth > imageHeight) {
                CGFloat temp = imageWidth;
                imageWidth = imageHeight;
                imageHeight = temp;
            }
            
            
            @autoreleasepool {
                
                UIImage *croppedImg = nil;
                
                if (deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight) {

                    croppedImg = [processedImage imageByScalingAndCroppingForSize:CGSizeMake(imageHeight, imageWidth)];

                    if (frontCam) {
                        CIImage *c = [[CIImage alloc] initWithImage:croppedImg];
                        // Apply transform
                        c = [c imageByApplyingOrientation:UIImageOrientationLeft];
                        c = [c imageByApplyingTransform:CGAffineTransformMakeScale(1, -1)];
                        c = [c imageByApplyingTransform:CGAffineTransformMakeTranslation(0, c.extent.size.height)];
                        
                        // Convert back to UIImage
                        CIContext *context = [CIContext contextWithOptions:nil];
                        CGImageRef rotatedImage = [context createCGImage:c fromRect:c.extent];
                        croppedImg = [UIImage imageWithCGImage:rotatedImage];
                        
                        c = nil;
                        context = nil;
                        CGImageRelease(rotatedImage);
                        rotatedImage = nil;
                    }
                } else {
                    croppedImg = [processedImage imageByScalingAndCroppingForSize:CGSizeMake(imageWidth, imageHeight)];
                }
                
                [library writeImageDataToSavedPhotosAlbum:UIImageJPEGRepresentation(croppedImg, 0.5) metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error2)
                 {
                     if (error2) {
                         NSLog(@"ERROR: the image failed to be written");
                     }
                     else {
                         NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
                     }
                     
                     runOnMainQueueWithoutDeadlocking(^{
                         [[NSNotificationCenter defaultCenter] postNotificationName:@"FinishedSavingImage" object:self];
                         [self resetStorageMemory];
                     });
                 }];
                
                self.lastCapturedImage = croppedImg;
            }
        });
    }];
}

#pragma mark - User input events

- (void)displayPickerForGroup:(ALAssetsGroup *)group
{
    QBAssetsCollectionViewController *imagePicker = [[QBAssetsCollectionViewController alloc] initWithCollectionViewLayout:[QBAssetsCollectionViewLayout layout]];
    imagePicker.filterType = QBImagePickerControllerFilterTypeNone;
    imagePicker.allowsMultipleSelection = NO;
    imagePicker.assets = self.assets;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePicker];
    [self presentViewController:navigationController animated:YES completion:nil];
}



- (IBAction)photoLibraryPressed:(id)sender
{
    
    if (_recordingVideo)
        return;
    
    //[self startZoomingIn];
    /*
     if (self.assetLibrary == nil)
     self.assetLibrary = [[ALAssetsLibrary alloc] init];
     
     NSMutableArray *groups = [NSMutableArray array];
     [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
     if (group) {
     [groups addObject:group];
     } else {
     // this is the end
     [self displayPickerForGroup:[groups objectAtIndex:0]];
     }
     } failureBlock:^(NSError *error) {
     //self.chosenImages = nil;
     UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
     [alert show];
     
     NSLog(@"A problem occured %@", [error description]);
     // an error here means that the asset groups were inaccessable.
     // Maybe the user or system preferences refused access.
     }];*/
    
//    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
//    imagePicker.delegate = self;
//    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//    imagePicker.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
//    [self presentViewController:imagePicker animated:YES completion:NULL];
    
    
    QBAssetsCollectionViewController *imagePicker = [[QBAssetsCollectionViewController alloc] initWithCollectionViewLayout:[QBAssetsCollectionViewLayout layout]];
    imagePicker.filterType = QBImagePickerControllerFilterTypeNone;
    imagePicker.allowsMultipleSelection = NO;
    imagePicker.assets = self.assets;
    imagePicker.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePicker];
    [self presentViewController:navigationController animated:YES completion:nil];
 
}

- (void)handleSwipeRightFrom:(UIGestureRecognizer*)recognizer
{
    NSLog(@"swipe right");
    
    if (!cameraView.userInteractionEnabled)
        return;
    
    if (_recordingVideo)
        return;
    
    
    self.photos =[[NSMutableArray alloc] init];
    
    for (ALAsset *asset in self.assets) {
        
        //NSLog(@"%@", [asset.defaultRepresentation.url absoluteString]);
        
        [self.photos addObject:[MWPhoto photoWithURL:asset.defaultRepresentation.url]];
    }
    
    
    if (self.assets.count > 0)
    {
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.displayNavArrows = NO;
        browser.wantsFullScreenLayout = YES;
        browser.zoomPhotosToFill = YES;
        //browser.interfaceOrientation = _currentOrientation;
        
        [browser setCurrentPhotoIndex:self.photos.count-1];
        
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
//        nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:nc animated:NO completion:nil];
    }
    
    /*
     if (_zoomTimer == nil)
     [self startZoomingIn];
     else
     [self stopZoomingIn];
     */
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize sourceImage:(UIImage*) si{
    
    UIImage *sourceImage = si;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat sf = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            sf = widthFactor;
        else
            sf = heightFactor;
        
        scaledWidth  = width * sf;
        scaledHeight = height * sf;
        
        // center the image
        
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    
    return newImage ;
}


- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       MWPhoto* photo = (MWPhoto*)[notification object];
                       
                       if ([photo.photoURL.absoluteString isEqualToString:self.lastPhoto.photoURL.absoluteString])
                       {
                           UIImage* img = [self imageByScalingProportionallyToSize:CGSizeMake(176, 176) sourceImage:[photo underlyingImage]];
                           [self.photoLibButton setImage:img forState:UIControlStateNormal];
                           NSLog(@"set button image");
                       }
                       else
                           NSLog(@"ignore image");
                   });
    
    
    
}

-(void)getLastPhoto
{
    NSLog(@"getLastPhoto called");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Process assets
        void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            
            
            if (result != nil) {
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto])
                {
                    //[assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                    
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    
                    NSURL *url = result.defaultRepresentation.url;
                    [_assetLibrary assetForURL:url
                                   resultBlock:^(ALAsset *asset)
                     {
                         if (asset) {
                             
                             NSLog(@"got last photo %d", index);
                             
                             [self.assets addObject:asset];
                             self.lastPhoto = [MWPhoto photoWithURL:url];
                             [self.lastPhoto performSelectorOnMainThread:@selector(loadUnderlyingImageAndNotify) withObject:nil waitUntilDone:YES];
                             
                             dispatch_semaphore_signal(sema);
                             *stop = YES;
                             
                             
                         }
                     }
                                  failureBlock:^(NSError *error){
                                      NSLog(@"operation was not successfull!");
                                  }];
                    
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    
                }
                else
                {
                    NSLog(@"not a photo");
                }
            }
        };
        
        // Process groups
        void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
            if (group != nil) {
                
                NSLog(@"total assets from last photo %d", group.numberOfAssets);
                
                NSIndexSet* is = [NSIndexSet indexSetWithIndex:group.numberOfAssets-1 ];
                [group enumerateAssetsAtIndexes:is options:NSEnumerationConcurrent usingBlock:assetEnumerator];
            }
        };
        
        // Process!
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                         usingBlock:assetGroupEnumerator
                                       failureBlock:^(NSError *error) {
                                           NSLog(@"There is an error");
                                       }];
        
        
    });
}

- (void)loadAssets {
    
    
    if (self.HUD == nil)
    {
        self.HUD = [MBProgressHUD showHUDAddedTo:cameraView animated:YES];
    }
    else
    {
        [self.HUD show:YES];
    }
    
    self.HUD.labelText = @"Loading ...";
    
    [cameraView setUserInteractionEnabled:NO];
    
    // Initialise
    self.assets = [NSMutableArray new];
    
    __block int totalAssets = 0;
    __block int lastIndex = -1;
    __block NSURL* lastIndexURL = nil;
    
    if (self.assetLibrary == nil)
        self.assetLibrary = [[ALAssetsLibrary alloc] init];
    
    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    
    // Run in the background as it takes a while to get all assets from the library
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
        //NSMutableArray *assetURLDictionaries = [[NSMutableArray alloc] init];
        
        // Process assets
        void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            
            
            if (result != nil)
            {
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto])
                {
                    
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    
                    //[assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                    NSURL *url = result.defaultRepresentation.url;
                    [_assetLibrary assetForURL:url
                                   resultBlock:^(ALAsset *asset) {
                                       if (asset) {
                                           
                                           //NSLog(@"adding %d", index);
                                           lastIndex = index;
                                           lastIndexURL = url;
                                           
                                           [self.assets addObject:asset];
                                           
                                           
                                           dispatch_semaphore_signal(sema);
                                       }
                                   }
                                  failureBlock:^(NSError *error){
                                      NSLog(@"operation was not successfull!");
                                      dispatch_semaphore_signal(sema);
                                  }];
                    
                    //NSLog(@"end %d", index);
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    
                }
                else
                {
                    //NSLog(@"not photo %d", index);
                }
            }
            else
            {
                //NSLog(@"result = nil %d", index);
                dispatch_semaphore_signal(sema2);
            }
            
            //NSLog(@"enumerate");
        };
        
        // Process groups
        void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
            if (group != nil) {
                
                totalAssets = group.numberOfAssets;
                NSLog(@"total assets %d", totalAssets);
                [group enumerateAssetsUsingBlock:assetEnumerator];
                [assetGroups addObject:group];
                //NSLog(@"group count %d", assetGroups.count);
            }
        };
        
        // Process!
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                         usingBlock:assetGroupEnumerator
                                       failureBlock:^(NSError *error) {
                                           
                                           dispatch_async(dispatch_get_main_queue(),
                                                          ^{
                                                              
                                                              
                                                              if (error.code == -3311)
                                                              {
                                                                  
                                                                  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                                                                  
                                                                  UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please allow GRIP&SHOOT to access your Photos and Microphone. Go to Settings -> Privacy -> Microphone AND Photos to allow access." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                                                                  [av show];
                                                              }
                                                              
                                                              
                                                              [self.HUD hide:YES];
                                                              [cameraView setUserInteractionEnabled:YES];
                                                          });
                                           
                                           
                                           
                                           
                                           NSLog(@"There is an error %d %@ ", error.code, error.localizedDescription);
                                       }];
        
        
        dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);
        //NSLog(@"moving on");
        
        if (lastIndex > -1)
        {
            NSLog(@"last photo from load assets %d", lastIndex);
            
            self.lastPhoto = [MWPhoto photoWithURL:lastIndexURL];
            
            [self.lastPhoto performSelectorOnMainThread:@selector(loadUnderlyingImageAndNotify) withObject:nil waitUntilDone:NO];
            
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               [self.HUD hide:YES];
                               [cameraView setUserInteractionEnabled:YES];
                               
                               NSLog(@"Finished loading all photos");
                           });
            
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               [self.HUD hide:YES];
                               [cameraView setUserInteractionEnabled:YES];
                               NSLog(@"No photos");
                           });
        }
        
        
        
    });
    
}




-(void)_hidePopover {
    
    [_devicePickerView setAlpha:0.0];
    [self setShowingPopover:NO];
    
    /*
     [UIView animateWithDuration:0.12 animations:^{
     [_devicePickerView setAlpha:0.0];
     } completion:^(BOOL finished) {
     [self setShowingPopover:NO];
     }];*/
}

-(void)_showPopover {
    
    
    [self setShowingPopover:YES];
    [_devicePickerView setAlpha:1.0];
    
    /*
     [UIView animateWithDuration:0.12 animations:^{
     [_devicePickerView setAlpha:1.0];
     } completion:^(BOOL finished) {
     
     }];
     */
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self isShowingPopover]) {
        [self _hidePopover];
    }
}

- (void)setStorageLabel:(uint64_t)availableBytes {
    double GBytes = availableBytes / 1024.0 / 1024.0 / 1024.0 - 0.2;
    [_storageButton setTitle:[NSString stringWithFormat:@"%.2f GB", GBytes] forState:UIControlStateNormal];
    
}

-(void)videoTimerDidFire {
    if (videoCaptureBlinkFlag) {
        captureButton.selected = YES;
    }
    else {
        captureButton.selected = NO;
    }
    
    videoCaptureBlinkFlag = !videoCaptureBlinkFlag;
    
    uint64_t availableBytes = [ImageCaptureViewController availableDiskSpaceInBytes];
    [self setStorageLabel:availableBytes];
    
    BOOL isDiskSpaceAvailable = availableBytes > VideoRequiredMinimumDiskSpaceInBytes;
    
    if (!isDiskSpaceAvailable) {
        NSLog(@"%llu", VideoRequiredMinimumDiskSpaceInBytes - [ImageCaptureViewController availableDiskSpaceInBytes]);
        [self takePhoto:nil];
    } else {
        NSLog(@"%llu", [ImageCaptureViewController availableDiskSpaceInBytes] - VideoRequiredMinimumDiskSpaceInBytes);
    }
}

-(void)setZoom:(float)scaleFlag{
    scaleType = scaleFlag;
}

-(void)setFlashMode:(int)mode {
    if (mode == FLASH_OFF) {
        flashStatus = FLASH_OFF;
        
        if ([self.stillCamera.inputCamera hasFlash]) {
            [self.stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOff];
        }
        
        if ([self.stillCamera.inputCamera hasTorch]) {
            [self.stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        }
        
        [flashButton setImage:[UIImage imageNamed:@"flash_off.png"] forState:UIControlStateNormal];
        [flashButton setImage:[UIImage imageNamed:@"flash_off_selected.png"] forState:UIControlStateHighlighted];
        [self turnFlash:NO];
    }
    else if (mode == FLASH_ON) {
        flashStatus = FLASH_ON;
        
        if ([self.stillCamera.inputCamera hasFlash]) {
            [self.stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
        }
        
        if ([self.stillCamera.inputCamera hasTorch] && _captureMode == kCaptureModeVideo) {
            [self.stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        }
        
        [flashButton setImage:[UIImage imageNamed:@"flash_on.png"] forState:UIControlStateNormal];
        [flashButton setImage:[UIImage imageNamed:@"flash_on_selected.png"] forState:UIControlStateHighlighted];
        [self turnFlash:NO];
    }
    else if (mode == FLASH_AUTO) {
        flashStatus = FLASH_AUTO;
        
        if ([self.stillCamera.inputCamera hasFlash]) {
            [self.stillCamera.inputCamera setFlashMode:AVCaptureFlashModeAuto];
            [self.stillCamera.inputCamera setFlashMode:AVCaptureFlashModeAuto];
        }
        
        if ([self.stillCamera.inputCamera hasTorch] && _captureMode == kCaptureModeVideo) {
            [self.stillCamera.inputCamera setTorchMode:AVCaptureTorchModeAuto];
        }
        
        [flashButton setImage:[UIImage imageNamed:@"flash_auto.png"] forState:UIControlStateNormal];
        [flashButton setImage:[UIImage imageNamed:@"flash_auto_selected.png"] forState:UIControlStateHighlighted];
        [self turnFlash:NO];
    }
    else if (mode == FLASH_LIGHT) {
        flashStatus = FLASH_LIGHT;
        
        if ([self.stillCamera.inputCamera hasFlash]) {
            [self.stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOff];
        }
        
        if ([self.stillCamera.inputCamera hasTorch]) {
            [self.stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        }
        [flashButton setImage:[UIImage imageNamed:@"flash_light_selected.png"] forState:UIControlStateNormal];
        [flashButton setImage:[UIImage imageNamed:@"flash_light_selected.png"] forState:UIControlStateHighlighted];
        
        [self turnFlash:YES];
    }
}

- (void)turnFlash:(BOOL)on {
    if (self.stillCamera.cameraPosition == AVCaptureDevicePositionBack) {
        // check if flashlight available
        
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            if ([device hasTorch] && [device hasFlash]){
                
                [device lockForConfiguration:nil];
                
                if (on && flashStatus == FLASH_LIGHT) {
                    [device setTorchMode:AVCaptureTorchModeOn];
                    
                    [flashButton setImage:[UIImage imageNamed:@"flash_light_selected.png"] forState:UIControlStateNormal];
                } else {
                    [device setTorchMode:AVCaptureTorchModeOff];
                }
                
                [device unlockForConfiguration];
            }
        }
    }
}

-(IBAction)flashSwitch:(id)sender{
    
    NSLog(@"flash switch");
    
    if (_captureMode == kCaptureModePhoto) {
        if (flashStatus == FLASH_AUTO) {
            [self setFlashMode:FLASH_ON];
        } else if (flashStatus == FLASH_ON) {
            [self setFlashMode:FLASH_OFF];
        } else if (flashStatus == FLASH_OFF) {
            [self setFlashMode:FLASH_LIGHT];
        } else if (flashStatus == FLASH_LIGHT) {
            [self setFlashMode:FLASH_AUTO];
        } else if (flashStatus == FLASH_UNSUPPORTED) {
            NSLog(@"The flash is not supported (this should not be possible)");
        }
    } else {
        if (flashStatus == FLASH_OFF) {
            [self setFlashMode:FLASH_LIGHT];
        } else {
            [self setFlashMode:FLASH_OFF];
        }
    }
    

}

-(void) initVideoDevice
{
    [self setScaleFactor:1.0];
    [self zoomToCurrentScaleFactor];
    
    [self setVideoMode];
    
    AVCaptureSession *session = self.stillCamera.captureSession;
    
    [session beginConfiguration];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    [session commitConfiguration];
    
    if ([self.stillCamera.inputCamera hasTorch]) {
        if (flashStatus == FLASH_AUTO) {
            [self.stillCamera.inputCamera setTorchMode:AVCaptureTorchModeAuto];
        }
        else if (flashStatus == FLASH_ON) {
            [self.stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        }
        else {
            [self.stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        }
    }
    
    if (self.stillCamera.inputCamera && [self.stillCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        [self.stillCamera.inputCamera lockForConfiguration:nil];
        /*
         if ([avCaptureDevice respondsToSelector:@selector(setFocusMode:)])
         {
         avCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
         }*/
        /*
         if ([avCaptureDevice respondsToSelector:@selector(isSmoothAutoFocusSupported)])
         {
         if (avCaptureDevice.isSmoothAutoFocusSupported)
         {
         if ([avCaptureDevice respondsToSelector:@selector(setSmoothAutoFocusEnabled:)])
         {
         avCaptureDevice.smoothAutoFocusEnabled = YES;
         }
         }
         }
         */
        [self.stillCamera.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [self.stillCamera.inputCamera unlockForConfiguration];
    }
    
    
    /*
     CGFloat newWidth = cameraPreview.bounds.size.height / 16 * 9;
     captureVideoPreviewLayer.frame = CGRectMake((cameraPreview.bounds.size.width / 2) - (newWidth / 2), cameraPreview.bounds.origin.y, newWidth, cameraPreview.bounds.size.height);
     */
    
    
    /*
     
     captureVideoPreviewLayer.frame = [cameraPreview bounds];
     
     captureVideoPreviewLayer.frame = r;
     */
    
    CGRect r = [cameraPreview bounds];
    //r.origin.y = -45;
    r.size.height = (16.0*r.size.width)/9.0;
    
    self.topDummyView.hidden = YES;
    self.bottomDummyView.hidden = YES;
}

-(void) positionPreviewForPhoto
{
    CGRect r = [cameraPreview bounds];
    
    //NSLog(@"Camera Preview Bou,.nds %@", NSStringFromCGRect(r));
    
    float middleSpace =  (_bottomBar.frame.origin.y) -(_topButtonsBarView.frame.origin.y + _topButtonsBarView.frame.size.height);
    
    r.size.height = (4.0*r.size.width)/3.0;
    r.origin.y = (middleSpace-r.size.height)/2.0 - cameraView.frame.origin.y+5;
    //    captureVideoPreviewLayer.frame = r;
    
    CGRect rr = self.topDummyView.frame;
    rr.size.height = r.origin.y;
    self.topDummyView.frame = rr;
    self.topDummyView.hidden = NO;
    
    rr = self.bottomDummyView.frame;
    
    rr.origin.y = r.origin.y + r.size.height - cameraView.frame.origin.y;
    rr.size.height = self.view.frame.size.height - rr.origin.y;
    self.bottomDummyView.frame = rr;
    self.bottomDummyView.hidden = NO;
    //NSLog(@"preview frame %@", NSStringFromCGRect(r));
}

#pragma mark - Table Methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    //I have a static list of section titles in SECTION_ARRAY for reference.
    //Obviously your own section title code handles things differently to me.
    return @"Tap Grip I.D.";
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[EMConnectionManager sharedManager] connectedDevice]) {
        return [[self devices] count] + 1;
    }
    return [[self devices] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"DeviceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    EMDeviceBasicDescription *device = nil;
    if ([[EMConnectionManager sharedManager] connectedDevice] && indexPath.row == 0) {
        device = [[EMConnectionManager sharedManager] connectedDevice];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else if ([[EMConnectionManager sharedManager] connectedDevice]) {
        [[self devices] objectAtIndex:indexPath.row - 1];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    else {
        if (indexPath.row >= [[self devices] count]) {
            device = nil;
        }
        else {
            device = [[self devices] objectAtIndex:indexPath.row];
        }
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    [[cell textLabel] setText:[device name]];
    cell.indentationLevel = 2;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //[[EMConnectionManager sharedManager] disconnectWithSuccess:nil onFail:nil];
    
    NSLog(@"connection state :%d", [[EMConnectionManager sharedManager] connectionState]);
    if ([[EMConnectionManager sharedManager] connectionState] != EMConnectionStateDisconnected)
    {
        if ([[EMConnectionManager sharedManager] connectionState] != EMConnectionStateTimeout)
            return;
    }
    
    [[EMConnectionListManager sharedManager] stopUpdating];
    [[EMConnectionManager sharedManager] connectDevice:[[self devices] objectAtIndex:indexPath.row] onSuccess:^{
        
    } onFail:^(NSError *error) {
        NSLog(@"Failed to connect to board");
        [[EMConnectionListManager sharedManager] startUpdating];
    }];
}

#pragma mark - Video Timer Delegate

-(void)updateTimer:(int)seconds{
    int minutes = (seconds / 60);
    seconds = seconds - (minutes * 60);
    
    //if has to add a 0 before number of hours/minutes/seconds
    NSString *minutesComplement = ((minutes / 10) > 0) ? @"" : @"0";
    NSString *secondsComplement = ((seconds / 10) > 0) ? @"" : @"0";
    
    self.timeLabel.text = [NSString stringWithFormat:@"%@%d:%@%d", minutesComplement, minutes, secondsComplement, seconds];
}

-(void)setPhotoMode{
    _captureMode = kCaptureModePhoto;
    
    CGRect currentFrame = [[self cameraSlider] frame];
    [UIView animateWithDuration:0.25 animations:^(){
        self.cameraSlider.frame = CGRectMake(243, currentFrame.origin.y, 26, 7);
    }];
    
    [self.captureButton setImage:[UIImage imageNamed:@"capture_btn_selected"] forState:UIControlStateHighlighted];
    [self.captureButton setImage:[UIImage imageNamed:@"capture_btn_selected"] forState:UIControlStateSelected];
    
    [self videoTimerIsHidden:YES];
    
    [self setFlashMode:FLASH_AUTO];
    [self setAspectRatio:_photoAspectRatio];
}

-(void)setVideoMode{
    
    _captureMode = kCaptureModeVideo;
    CGRect currentFrame = [[self cameraSlider] frame];
    [UIView animateWithDuration:0.25 animations:^(){
        self.cameraSlider.frame = CGRectMake(281, currentFrame.origin.y, 26, 7);
    }];
    
    [self.captureButton setImage:[UIImage imageNamed:@"capture_btn_video"] forState:UIControlStateHighlighted];
    [self.captureButton setImage:[UIImage imageNamed:@"capture_btn_video"] forState:UIControlStateSelected];
    [self.captureButton setSelected:NO];
    [self.captureButton setHighlighted:NO];
    
    [self videoTimerIsHidden:NO];
    
    [self setFlashMode:FLASH_OFF];
    
    [self setAspectRatio:kAspectType169];
    
}

-(void)flashButtonIsHidden:(Boolean)hide{
    if (flashStatus == FLASH_UNSUPPORTED) {
        [flashButton setHidden:YES];
    } else {
        
        if ((!hide) && (!usingFrontCamera))
            [flashButton setHidden:hide];
    }
}

-(void)videoTimerIsHidden:(Boolean)hide{
    if (hide) {
        [self.timeLabel setHidden:YES];
        [self.timeLabelBackground setHidden:YES];
    } else {
        [self.timeLabelBackground setHidden:NO];
        [self.timeLabel setHidden:NO];
        [self updateTimer:0];
    }
}

-(void)cameraSwitchIsHidden:(Boolean)hide{
    [cameraSwitch setHidden:hide];
    [_switchModeButton setHidden:hide];
}

-(VideoTimer *)getCurrentVideoTimer{
    return self.videoTimer;
}

-(CALayer *)cameraPreviewLayer{
    return self.cameraPreview.layer;
}

-(CALayer *)shutterLayer{
    return [self.shutterView layer];
}

#pragma mark - Image Picker Delegate

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:NO completion:NULL];
    MediaViewController *viewController = [[MediaViewController alloc] initWithNibName:@"MediaView" bundle:[NSBundle mainBundle]];
//    [viewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:viewController animated:NO completion:NULL];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        [viewController setImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    }
    else {
        [viewController loadVideoAtURL:[info objectForKey:UIImagePickerControllerMediaURL]];
    }
}

#pragma mark - Gestures Recognizer

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    
    if ([self.stillCamera.inputCamera respondsToSelector:@selector(setVideoZoomFactor:)])
    {
        CGFloat currentScale = self.stillCamera.inputCamera.videoZoomFactor;
        
        if (currentScale * recognizer.scale < 1.0) {
            [self.stillCamera.inputCamera lockForConfiguration:nil];
            self.stillCamera.inputCamera.videoZoomFactor = 1;
            self.scaleFactor = 1;
            [self.stillCamera.inputCamera unlockForConfiguration];
            return;
        }
        
        if (currentScale * recognizer.scale >= 5.0) {
            return;
        }
        
        [self.stillCamera.inputCamera lockForConfiguration:nil];
        self.scaleFactor = self.scaleFactor * recognizer.scale;
        self.stillCamera.inputCamera.videoZoomFactor = [self scaleFactor];
        recognizer.scale = 1;
        [self.stillCamera.inputCamera unlockForConfiguration];
    }
    
    
}

-(void)tapToFocus:(UITapGestureRecognizer *)singleTap
{
    if (self.settingView) {
        [self tapSetting:nil];
    } else {
        CGPoint tappedPoint = [singleTap locationInView:self.cameraPreview];
        CGPoint focusingPoint = [VisionUtility convertToPointOfInterestFromViewCoordinates:tappedPoint inFrame:self.cameraPreview.bounds orientation:_currentOrientation];
        
        if ([self setInterestFocusPoint:focusingPoint]) {
            
            ///////////////////////////
            // Showing target market //
            ///////////////////////////
            
            if (_captureMode != kCaptureModeVideo)
            {
                CGRect frame = self.focusMarkView.frame;
                frame.size.width = frame.size.height = FOCUS_MARK_SIZE;
                self.focusMarkView.frame = frame;
                self.focusMarkView.layer.borderWidth = 1.0f;
            }
            else
            {
                CGRect frame = self.focusMarkView.frame;
                frame.size.width = frame.size.height = FOCUS_MARK_SIZE;
                self.focusMarkView.frame = frame;
                self.focusMarkView.layer.borderWidth = 1.0f;
            }
            
            self.focusMarkView.alpha = 1;
            self.focusMarkView.center = tappedPoint;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:1.0f];
            
            self.focusMarkView.alpha = 0;
            
            [UIView commitAnimations];
            
            // Start motion detection...
            isAutoFocusing = NO;
            [self startMotionUpdates];
        }
    }
    
}

/**
 * Initialization for Auto Focus
 */
- (void)setAutoFocus
{
    AVCaptureDevice *currentDevice = self.stillCamera.inputCamera;
    
    if (currentDevice && [currentDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]
        /* &&
         [currentDevice respondsToSelector:@selector(isSmoothAutoFocusSupported)] &&
         currentDevice.isSmoothAutoFocusSupported &&
         [currentDevice respondsToSelector:@selector(setSmoothAutoFocusEnabled:)]*/) {
             
             NSError *error = nil;
             [currentDevice lockForConfiguration:&error];
             if (!error) {
                 //currentDevice.smoothAutoFocusEnabled = YES;
                 [currentDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                 [currentDevice unlockForConfiguration];
                 isAutoFocusing = YES;
             }
         }
}

- (void)stopAutoFocus
{
    AVCaptureDevice *currentDevice = self.stillCamera.inputCamera;
    if (currentDevice && [currentDevice isFocusModeSupported:AVCaptureFocusModeLocked]) {
        
        NSError *error = nil;
        [currentDevice lockForConfiguration:&error];
        if (!error) {
            [currentDevice setFocusMode:AVCaptureFocusModeLocked];
            [currentDevice unlockForConfiguration];
            isAutoFocusing = NO;
        }
    }
}

/**
 * Set interest focus point
 */
- (BOOL)setInterestFocusPoint:(CGPoint)point
{
    AVCaptureDevice *currentDevice = self.stillCamera.inputCamera;;
    if ([currentDevice isFocusPointOfInterestSupported] && [currentDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        NSError *error = nil;
        [currentDevice lockForConfiguration:&error];
        if (!error) {
            [currentDevice setFocusPointOfInterest:point];
            [currentDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [currentDevice unlockForConfiguration];
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Motion
- (void)initMotionManager
{
    motionManager = [[CMMotionManager alloc] init];
    if (!motionManager.accelerometerAvailable) {
        NSLog(@"没有加速计");
    }
    
    motionManager.accelerometerUpdateInterval = 0.02; // 告诉manager，更新频率是100Hz
}

- (void)startMotionUpdates
{
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *latestAcc, NSError *error)
     {
         float acelerometer = latestAcc.acceleration.x * latestAcc.acceleration.x + latestAcc.acceleration.y * latestAcc.acceleration.y + latestAcc.acceleration.z * latestAcc.acceleration.z;
         
         if (acelerometer > MOTION_THRESHOLD && !isAutoFocusing && !_recordingVideo) {
             
             NSLog(@"AutoFocusMode: Enabled!");
             [self setAutoFocus];
             [motionManager stopAccelerometerUpdates];
         }
     }];
}

#pragma mark - Memory

+ (void)showMemoryWarning {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Memory Storage Low" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
}

+ (void)checkDeviceStorage {
    long long availableSpace = [ImageCaptureViewController availableDiskSpaceInBytes];
    BOOL isDiskSpaceAvailable = availableSpace > RequiredMinimumDiskSpaceInBytes;
    
    if (!isDiskSpaceAvailable) {
        [ImageCaptureViewController showMemoryWarning];
    } else {

    }
}


+ (uint64_t)availableDiskSpaceInBytes
{
    uint64_t totalFreeSpace = 0;
    
    __autoreleasing NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    }
    
    return totalFreeSpace;
}

#pragma mark - SettingMenu Delegate

- (void)willShowSettingView {
    SettingViewController *settingVC = [[SettingViewController alloc] init];
    self.settingVC = settingVC;
    settingVC.delegate = self;
    OrientNavigationVC *navigationVC = [[OrientNavigationVC alloc] initWithRootViewController:settingVC];
    [navigationVC.navigationBar setHidden:YES];
    
    [self presentViewController:navigationVC animated:YES completion:^{
        
    }];
}

#pragma mark - SettingViewController Delegate

- (void)didDismissViewController:(SettingViewController *)settingVC {
    self.settingVC = nil;
}

@end
