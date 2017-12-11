//
//  VideoTimer.h
//  ZetaCamera
//
//  Created by benjamin michel on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoTimerDelegate.h"

@interface VideoTimer : NSObject

@property (nonatomic, strong) NSTimer *timer;

/**
 initialize the video timer with the given controller
 @param controller
 @returns VideoTimer
 @exception none
 */
-(id)initWithController:(id<VideoTimerDelegate>)controller;

/**
 will start the timer from zero
 @param void
 @returns void
 @exception none
 */
-(void)startTimer;


/**
 stop the timer
 @param void
 @returns void
 @exception none
 */
-(void)stopTimer;

@end
