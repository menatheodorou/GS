//
//  VideoTimerDelegate.h
//  ZetaCamera
//
//  Created by benjamin michel on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VideoTimerDelegate <NSObject>

@required
/**
 the timer changed, thus the display has to be updated
 @param seconds
 @returns void
 @exception none
 */
- (void)updateTimer:(int)seconds;
@end
