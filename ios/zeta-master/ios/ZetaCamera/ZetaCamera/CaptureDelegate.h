//
//  CaptureDelegate.h
//  ZetaCamera
//
//  Created by benjamin michel on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoTimer.h"

@protocol CaptureDelegate <NSObject>

@optional

@required

/**
 Sets the capture screen into Photo mode
 @returns void
 @exception none
 */
-(void)setPhotoMode;

/**
 Sets the capture screen into Video mode
 @returns void
 @exception none
 */
-(void)setVideoMode;

/**
 showing or hiding the flash button
 @param boolean
 @returns void
 @exception none
 */
-(void)flashButtonIsHidden:(Boolean)hide;

/**
 showing or hiding the timer
 @param boolean
 @returns void
 @exception none
 */
-(void)videoTimerIsHidden:(Boolean)hide;

/**
 showing or hiding the camera switch
 @param boolean
 @returns void
 @exception none
 */
-(void)cameraSwitchIsHidden:(Boolean)hide;

/**
 returns the instance of the video timer
 @param void
 @returns VideoTimer
 @exception none
 */
-(VideoTimer *)getCurrentVideoTimer;

/**
 Add Capture output
 @param (AVCaptureOutput *)
 @returns void
 @exception none
 */
-(void)addCaptureOutput:(AVCaptureOutput *)captureOutput;

/**
 gives the layer of the camera preview
 @param void
 @returns CALayer *
 @exception none
 */
-(CALayer *)cameraPreviewLayer;


/**
 get shutter layer
 @param void
 @returns CALayer
 @exception none
 */
-(CALayer *)shutterLayer;

@end
