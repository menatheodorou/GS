//
//  PhotoDevice.h
//  ZetaCamera
//
//  Created by benjamin michel on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CaptureDevice.h"

@interface PhotoDevice : NSObject <CaptureDevice>
@property (nonatomic, getter = isUsingFrontCamera) BOOL usingFrontCamera;

@end
