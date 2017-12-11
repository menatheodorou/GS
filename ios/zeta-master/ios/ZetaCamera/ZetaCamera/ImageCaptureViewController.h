//
//  ImageCaptureViewController.h
//  ZetaCamera
//
//  Created by benjamin michel on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMResourceValue.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoTimerDelegate.h"
#import "CaptureDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MBProgressHUD.h"
#import <CoreMotion/CoreMotion.h>
#import "GPUImage.h"

typedef enum {
    kAspectType43,
    kAspectType169,
    kAspectType11
}AspectType;

typedef enum {
    kGridTypeNone,
    kGridTypeSquare,
    kGridTypeSprial,
    kGridTypeTriangle
}GridType;

typedef enum {
    kCaptureModeVideo,
    kCaptureModePhoto
}CaptureMode;

@class SettingMenuView;

@interface ImageCaptureViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, VideoTimerDelegate, MWPhotoBrowserDelegate>{
    
    
    IBOutlet UIButton *reviewButton;
    IBOutlet GPUImageView *cameraPreview;
    IBOutlet UIButton *videoSwitchButton;
    IBOutlet UIButton *captureButton;
    IBOutlet UILabel *timeLabel;
    IBOutlet UIButton *flashButton;
    IBOutlet UIButton *remoteButton;
    IBOutlet UIButton *infoButton;
    
    IBOutlet UIButton *biggerFlashButton;
    IBOutlet UIButton *biggerRemoteButton;
    IBOutlet UIButton *biggerSwitchButton;
    
    
    IBOutlet UIView         *_cameraContainerView;  // Used for flip camer on front camera
    __weak IBOutlet UIView *_cameraRotateView;
    IBOutlet UIView         *cameraView;
    IBOutlet UIImageView    *_gridBGView;
    
    IBOutlet UIView *shutterView;
    IBOutlet UIView         *_topButtonsBarView;
    IBOutlet UIImageView    *_topbarBackgroundView;
    IBOutlet UIButton       *_settingButton;
    
    IBOutlet UIView         *_bottomBar;
    IBOutlet UIImageView    *_bottombarBackgroundView;
    
    IBOutlet UIView         *_settingContainView;
    
    IBOutlet UIImageView *_switchToCameraImage;
    IBOutlet UIImageView *_switchToVideoImage;
    
    IBOutlet UIView *_leftTopBarButtonShell;
    IBOutlet UIView *_rightTopBarButtonShell;
    
    IBOutlet UIButton   *_geoButton;
    IBOutlet UIButton   *_scnButton;
    IBOutlet UIButton   *_storageButton;
    
    IBOutlet UIView     *_introView;
    IBOutlet UIImageView *_introImageView;
    IBOutlet UIButton   *_logoButton;
    IBOutlet UIButton   *_skipConnectionButton;
    IBOutlet UIImageView    *_connectingImgView;
    IBOutlet UIView     *_deviceControlView;
    
    IBOutlet UIView     *_shortcutView;
        NSTimer *_videoRecordingTimer;
    
    UIInterfaceOrientation _currentOrientation;
    float scaleFactor;
    
    NSTimer *_zoomTimer;
    
    __block EMResourceValue *_zoomInValue;
    __block EMResourceValue *_zoomOutValue;
    
    ///////////////////
    //Motion Detection
    ///////////////////
    CMMotionManager *motionManager;
    BOOL isAutoFocusing;
}

@property (atomic, strong) ALAssetsLibrary *assetLibrary;
@property (atomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) MBProgressHUD* HUD;
@property (nonatomic, assign) BOOL recordingVideo;



@property float scaleFactor;


@property (nonatomic, strong) IBOutlet UIView *topDummyView;
@property (nonatomic, strong) IBOutlet UIView *bottomDummyView;


@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *whiteBalanceFilter;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *exposureFilter;

@property (nonatomic, assign) AspectType aspectRatio;
@property (nonatomic, assign) AspectType photoAspectRatio;
@property (nonatomic, assign) GridType gridType;
@property (nonatomic, assign) UIInterfaceOrientation currentOrientaion;
@property (nonatomic, assign) CaptureMode captureMode;

@property (nonatomic, strong) SettingMenuView *settingView;
@property (nonatomic, strong) SettingMenuView *notifyView;


/**
 the gallery button
 */
@property (nonatomic, strong) IBOutlet UIButton *reviewButton;

/**
 the preview view
 */
@property (nonatomic, strong) IBOutlet GPUImageView *cameraPreview;

/**
 The button to switch from video to photo
 */
@property (nonatomic, strong) IBOutlet UIButton *videoSwitchButton;

/**
 The button to capture video/photo
 */
@property (nonatomic, strong) IBOutlet UIButton *captureButton;

/**
 The label where we display the time
 */
@property (nonatomic, strong) IBOutlet UILabel *timeLabel;

/**
 The flash button
 */
@property (nonatomic, strong) IBOutlet UIButton *flashButton;

/**
 the Camera switch button
 */
@property (nonatomic, strong) IBOutlet UIButton *cameraSwitch;

/**
 the Camera switch slider image
 */
@property (nonatomic, strong) IBOutlet UIImageView *cameraSlider;

/**
 the Time label background
 */
@property (nonatomic, strong) IBOutlet UIImageView *timeLabelBackground;

/**
 the Remote button
 */
@property (nonatomic, strong) IBOutlet UIButton *remoteButton;


//Photo Lib button
@property (nonatomic, strong) IBOutlet UIButton *photoLibButton;

@property (nonatomic, strong) IBOutlet UILabel *linkLabel;

@property (nonatomic, strong) NSArray *devices;

// Focuse Mark
@property (nonatomic, retain) UIView *focusMarkView;


- (void)setZoom:(float)scaleFlag;
- (void)resetSCN;

/**
 the shutter view
 */
@property (nonatomic, strong) IBOutlet UIView *shutterView;

/**
 The action of taking a photo
 @param sender
 @returns IBAction
 @exception none
 */
-(IBAction)takePhoto:(id)sender;

/**
 Change the flash settings
 @param sender
 @returns IBAction
 @exception none
 */
-(IBAction)flashSwitch:(id)sender;

/**
 Change the active camera
 @param sender
 @returns IBAction
 @exception none
 */
-(IBAction)cameraSwitch:(id)sender;

/**
 switch photo/video
 @param void
 @returns IBAction
 @exception none
 */
-(IBAction)switchVideo:(id)sender;

/**
 Unload the data when leaving the view
 @param void
 @returns void
 @exception none
 */
-(void)applicationUnloaded;

-(IBAction)infoButtonPressed:(id)sender;

- (void)stopRecordingVideo;

-(void)startZoomingIn;
-(void)stopZoomingIn;

-(void)startZoomingOut;
-(void)stopZoomingOut;

- (void)rotateGridView;

-(IBAction)deviceButtonPressed:(id)sender;

-(IBAction)reviewButtonPressed:(id)sender;

- (IBAction)handleSwipeRightFrom:(UIGestureRecognizer*)recognizer;

- (IBAction)photoLibraryPressed:(id)sender;

- (IBAction)tapSetting:(id)sender;

@end
