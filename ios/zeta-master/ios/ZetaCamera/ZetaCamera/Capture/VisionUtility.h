//
//  VisionUtility.h
//  Momentz
//
//  Created by Momentz, Inc. on 2/3/14.
//  Copyright (c) 2014 Momentz, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VisionUtility : NSObject

+ (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates inFrame:(CGRect)frame orientation:(UIInterfaceOrientation)orientation;

+ (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

+ (uint64_t)availableDiskSpaceInBytes;

@end

@interface NSString (ExtraDate)

+ (NSString *)formattedTimestampStringFromDate:(NSDate *)date;

@end
