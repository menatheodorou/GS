//
//  VisionUtility.m
//  Momentz
//
//  Created by Momentz, Inc. on 2/3/14.
//  Copyright (c) 2014 Momentz, Inc. All rights reserved.
//

#import "VisionUtility.h"

@implementation VisionUtility

+ (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates inFrame:(CGRect)frame orientation:(UIInterfaceOrientation)orientation
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = frame.size;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            viewCoordinates = CGPointMake(frameSize.width - viewCoordinates.x, frameSize.height - viewCoordinates.y);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            viewCoordinates = CGPointMake(viewCoordinates.y, frameSize.width - viewCoordinates.x);
            frameSize = CGSizeMake(frameSize.height, frameSize.width);
            break;
        case UIInterfaceOrientationLandscapeRight:
            viewCoordinates = CGPointMake(frameSize.height - viewCoordinates.y, viewCoordinates.x);
            frameSize = CGSizeMake(frameSize.height, frameSize.width);
            break;
        default:
            break;
    }

    CGSize apertureSize = CGSizeMake(CGRectGetHeight(frame), CGRectGetWidth(frame));
    if (!CGSizeEqualToSize(apertureSize, CGSizeZero)) {
        CGPoint point = viewCoordinates;
        CGFloat apertureRatio = apertureSize.height / apertureSize.width;
        CGFloat viewRatio = frameSize.width / frameSize.height;
        CGFloat xc = .5f;
        CGFloat yc = .5f;
        
        
        if (viewRatio > apertureRatio) {
            CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
            xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
            yc = (frameSize.width - point.x) / frameSize.width;
        } else {
            CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
            yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
            xc = point.y / frameSize.height;
        }
        
        pointOfInterest = CGPointMake(xc, yc);
    }
    
    return pointOfInterest;
}

#pragma mark - Camera device

+ (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
    
	return nil;
}

+ (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0)
        return [devices objectAtIndex:0];
    
    return nil;
}

#pragma mark - memory

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

@end

#pragma mark - NSString Extras

@implementation NSString (ExtraDate)

+ (NSString *)formattedTimestampStringFromDate:(NSDate *)date
{
    if (!date)
        return nil;
    
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
        [dateFormatter setLocale:[NSLocale autoupdatingCurrentLocale]];
    });
    
    return [dateFormatter stringFromDate:date];
}

@end
