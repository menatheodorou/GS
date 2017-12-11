//
//  VideoTimer.m
//  ZetaCamera
//
//  Created by benjamin michel on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VideoTimer.h"

@interface VideoTimer(){
    
}

/**
 the delegate
 */
@property (nonatomic, strong) id<VideoTimerDelegate> controllerDelegate;


/**
 The time elapsed in seconds
 */
@property (nonatomic) NSInteger seconds;

/**
 Method triggered each seconds
 */
-(void)updateTime;

/**
 updating the time with a given number of secconds
 @param seconds
 @returns void
 @exception none
 */
-(void)updateTimeWithSeconds:(NSInteger)sec;

@end

@implementation VideoTimer

@synthesize controllerDelegate, timer, seconds;

-(id)initWithController:(id<VideoTimerDelegate>)controller{
    
    self = [super init];
    if (self){
        self.controllerDelegate = controller;
    }
    return self;
}

-(void)startTimer{
    self.seconds = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
}

-(void)stopTimer{
    [self.timer invalidate];
    [self setTimer:nil];
    [self updateTimeWithSeconds:0];
}
 

-(void)updateTime{
    seconds++;
    [self updateTimeWithSeconds:seconds];
}

-(void)updateTimeWithSeconds:(NSInteger)sec{
    [self.controllerDelegate updateTimer:sec];
}
                      
                      



@end
