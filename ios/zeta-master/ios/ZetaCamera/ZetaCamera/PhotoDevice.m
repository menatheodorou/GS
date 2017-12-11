//
//  PhotoDevice.m
//  ZetaCamera
//
//  Created by benjamin michel on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PhotoDevice.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "CaptureDelegate.h"
#import <ImageIo/CGImageProperties.h>
#import "UIImage+ImageCrop.h"
#import "PhotoEffect.h"
#import "Global.h"

//Maximal number of photos concurrently saving
#define MAX_SAVING 2
//Current number of photos concurrently saving
static int currentlySaving;

@interface PhotoDevice(){
    bool okToSnap;
    
    ALAssetsLibrary *assetLibrary;
    
    int count;
    int savedCount;
}

/**
 The delegate for showing output and showing user events
 */
@property (nonatomic, strong) id<CaptureDelegate> delegate;

/**
 Output for the image
 */
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;

/**
 save the image in the library
 @param UIImage
 @returns void
 @exception none
 */
//+(void)saveImage:(UIImage *)image;

@end

@implementation PhotoDevice

@synthesize delegate, imageOutput;
@synthesize usingFrontCamera;

#pragma mark - Capture Device Protocol implementations

-(id)initWithCaptureDelegate:(id<CaptureDelegate>)del{
    if (self = [super init]){
        self.delegate = del;
        
        self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
        [self.imageOutput setOutputSettings:[[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil]];
        [self.delegate addCaptureOutput:self.imageOutput];
        
        [imageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionInitial context:NULL];
        
    }
    currentlySaving = 0;
    //okToSnap = true;
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([imageOutput isCapturingStillImage]) {
        CATransition *animation = [CATransition animation];
        animation.delegate = self;
        animation.duration = 0.4;
        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        animation.type = @"cameraIris";
        [[self.delegate shutterLayer] addAnimation:animation forKey:nil];
    }
}

-(void)activateDevice:(Boolean)activate{
    if (activate) {
        [self.delegate setPhotoMode];
        [self.delegate flashButtonIsHidden:NO];
        [self.delegate videoTimerIsHidden:YES];
    } else {
        //do nothing
    }
}

// utility routing used during image capture to set up capture orientation

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = (AVCaptureVideoOrientation) deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}


-(void)clickCapture:(float)scaleImg orientation:(UIInterfaceOrientation)orientation {
    //getting the effective video connection
    
    AVCaptureConnection *videoConnection = nil;
    
    if (!videoConnection) {
        for (AVCaptureConnection *connection in imageOutput.connections){
            for (AVCaptureInputPort *port in [connection inputPorts]){
                if ([[port mediaType] isEqual:AVMediaTypeVideo] ){
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection) { break; }
        }
        
    }

    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:avcaptureOrientation];
    }

    [videoConnection setVideoScaleAndCropFactor:scaleImg];
    
    [imageOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG
                                                                    forKey:AVVideoCodecKey]];
    
    [imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
            
            count++;
            
            NSLog(@"Capture %d", count);
            
            //NSDate *start = [NSDate date];
            //load the image
        
            /*
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            if (scaleImg > 1.0) {
                if ([self isUsingFrontCamera] && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
                    image = [image standardImageFromCurrentScale:scaleImg additionalRotation:180];
                }
                else {
                    image = [image standardImageFromCurrentScale:scaleImg];
                }
            }
            */
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        
        UIImage *capturedImg = [UIImage imageWithData:jpegData];
        UIImage *filteredImg = [[PhotoEffect sharedInstance] filterImage:capturedImg filter:[Global photoFilterType]];
        jpegData = UIImageJPEGRepresentation(filteredImg, 0.5);
        
        /*
            if (image != nil) {
                if (!assetLibrary) {
                    assetLibrary = [[ALAssetsLibrary alloc] init];
                }
                UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
                ALAssetOrientation assetOrientation = (ALAssetOrientation)[image imageOrientation];
                
                
                if (deviceOrientation == UIDeviceOrientationFaceUp || deviceOrientation == UIDeviceOrientationFaceDown) {
                    if (orientation == UIInterfaceOrientationPortrait) {
                        assetOrientation = ALAssetOrientationRight;
                    }
                    else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                        assetOrientation = ALAssetOrientationLeft;
                    }
                    else if (orientation == UIInterfaceOrientationLandscapeRight) {
                        assetOrientation = ALAssetOrientationDown;
                    }
                 
                }
                */
                
                
            if (!assetLibrary) {
                assetLibrary = [[ALAssetsLibrary alloc] init];
            }
        
            CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    __block UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                        identifier = UIBackgroundTaskInvalid;
                    }];
                    
                    [assetLibrary writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
                        
                        savedCount++;
                        NSLog(@"Saved %d", savedCount);
                        
                        //NSDate *end = [NSDate date];
                        //NSTimeInterval interval = [end timeIntervalSinceDate:start];
                        //NSLog(@"Done %f", interval);
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"FinishedSavingImage" object:self];
                        
                        --currentlySaving;
                        
                        if (attachments)
                            CFRelease(attachments);
                        
                        [[UIApplication sharedApplication] endBackgroundTask:identifier];
                    
                        
					}];
                    /*
                    [assetLibrary writeImageDataToSavedPhotosAlbum:jpegData orientation:assetOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
                        
                        savedCount++;
                        NSLog(@"Saved %d", savedCount);
                        
                        //NSDate *end = [NSDate date];
                        //NSTimeInterval interval = [end timeIntervalSinceDate:start];
                        //NSLog(@"Done %f", interval);
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"FinishedSavingImage" object:self];
                        
                        --currentlySaving;
                        
                        [[UIApplication sharedApplication] endBackgroundTask:identifier];
                    }];
                    */
                    
                    
                    
                    
                });
            //}
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CapturedImage" object:self];
        }];
}



-(void)clickFlash{
    
}


#pragma mark - Class Utility Methods

//+(void)saveImage:(UIImage *)image{
//    //CGContextRef context = UIGraphicsGetCurrentContext();
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//
//    //UIImageWriteToSavedPhotosAlbum(image, nil,nil,nil);
//
//}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(NSDictionary *)contextInfo {  
    
    NSLog(@"Image save completed");
    
    if (error != NULL){
        // errors
        
    }
    else { 
        //no errors
    }
    if (image !=NULL){
        image=nil;
    }
    if (contextInfo !=NULL){
        contextInfo=nil;
    }
    okToSnap = true;
    currentlySaving --;
}



@end
