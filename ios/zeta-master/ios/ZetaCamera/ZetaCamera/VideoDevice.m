//
//  VideoDevice.m
//  ZetaCamera
//
//  Created by benjamin michel on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VideoDevice.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "CaptureDelegate.h"
#import "VideoEffect.h"
#import "Constant.h"
#import "Global.h"

@interface VideoDevice(){
    
}

/**
 The delegate for showing output and showing user events
 */
@property (nonatomic, strong) id<CaptureDelegate> delegate;

/**
 indicate if we are currently capturing
 */
@property (nonatomic) Boolean isCapturing;

/**
 Output for the video
 */
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

/**
 Start the capture of the video
 @param void
 @returns void
 @exception none
 */
-(void)startCapture;

/**
 Stop the capture of the video
 @param void
 @returns void
 @exception none
 */
-(void)stopCapture;

/**
 Make the Url of the temporary video
 @param void
 @returns NSUrl*
 @exception none
 */
+(NSURL *)makeTemporaryVideoUrl;

@end

@implementation VideoDevice

@synthesize delegate, isCapturing, movieFileOutput;

#pragma mark - Capture Device Protocol implementations

-(id)initWithCaptureDelegate:(id<CaptureDelegate>)del{
    if(self = [super init]){
        self.delegate = del;
        
        //add output
        self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        [self.delegate addCaptureOutput:self.movieFileOutput];
    }
    return self;
}

-(void)clickCapture:(float)scaleImg orientation:(UIInterfaceOrientation)orientation {
    if (!isCapturing)
        [self startCapture];
    else
        [self stopCapture];
    
}

-(void)activateDevice:(Boolean)activate{
    if (activate) {
        [self.delegate setVideoMode];
        
        /*
         If we want to deactivate the device, make sure that it is not recording
         */
    } else if (isCapturing){
        [self stopCapture];
    }
}



#pragma mark - Capture Lifecycle

-(void)startCapture {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in movieFileOutput.connections){
        for (AVCaptureInputPort *port in [connection inputPorts]){
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ){
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    //[videoConnection setVideoMinFrameDuration:CMTimeMake(1, 15)];
    
    if([videoConnection respondsToSelector:@selector(isVideoStabilizationSupported)])
    {
        if ([videoConnection isVideoStabilizationSupported])
            videoConnection.enablesVideoStabilizationWhenAvailable = YES;
    }
    
    
        
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:(AVCaptureVideoOrientation) [[UIDevice currentDevice] orientation]];
    }
    
    VideoTimer *videoTimer = [self.delegate getCurrentVideoTimer];
    [self.delegate videoTimerIsHidden:NO];
    [self.delegate cameraSwitchIsHidden:YES];
    isCapturing = YES;
    [videoTimer startTimer];
    
    NSURL *temporaryVideoUrl = [VideoDevice makeTemporaryVideoUrl];
    [movieFileOutput startRecordingToOutputFileURL:temporaryVideoUrl recordingDelegate:self];
}

-(void)stopCapture{
    [movieFileOutput stopRecording];
    VideoTimer *videoTimer = [self.delegate getCurrentVideoTimer];
    [self.delegate videoTimerIsHidden:YES];
    [self.delegate cameraSwitchIsHidden:NO];
    isCapturing = NO;
    [videoTimer stopTimer];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate implementations

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    if (error){
        NSLog(@"Capture Finished Error: %@", [error debugDescription]);
    }
    
    [[VideoEffect sharedInstance] filterVideo:outputFileURL filter:[Global videoFilterType] completionHandler:^(NSURL *movieURL) {
        //Saving Video
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:movieURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL
                                        completionBlock:^(NSURL *assetURL, NSError *error){
                                            NSLog(@"Video saved in Assets");
                                            [[NSFileManager defaultManager] removeItemAtURL:movieURL error:nil];
                                        }];
        }
    }];
    
}

#pragma mark - Class Utility Methods

+(NSURL *)makeTemporaryVideoUrl{
    NSString *filename = [NSString stringWithFormat:@"%.4f.mov", [[NSDate date] timeIntervalSince1970]];
    NSString *path = [CAPTURE_DIRECTORY stringByAppendingPathComponent:filename];
    return [[NSURL alloc] initFileURLWithPath:path];
}

@end
