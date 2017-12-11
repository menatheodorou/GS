//
//  CaptureDevice.h
//  ZetaCamera
//
//  Created by benjamin michel on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureDelegate.h"

@protocol CaptureDevice <NSObject>

@optional

/**
 When the user clicks on the flash button
 @param void
 @returns void
 @exception none
 */
-(void)clickFlash;

@required

/**
 When the user clicks on the Capture button
 @param void
 @returns void
 @exception none
 */
-(void)clickCapture:(float)scaleImg orientation:(UIInterfaceOrientation)orientation;


/**
 Initialize the device by passing it its delegate
 @param capture delegate
 @returns id
 @exception none
 */
-(id)initWithCaptureDelegate:(id<CaptureDelegate>)delegate;

/**
 when the user activated the device
 @param Boolean
 @returns void
 @exception none
 */
-(void)activateDevice:(Boolean)activated;

@end
