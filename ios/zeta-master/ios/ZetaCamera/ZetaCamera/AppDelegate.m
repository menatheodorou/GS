//
//  AppDelegate.m
//  ZetaCamera
//
//  Created by benjamin michel on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "EMFramework.h"
#import <AudioToolbox/AudioToolbox.h>
#import "Constant.h"
//#import "TestFlight.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self.window makeKeyAndVisible];
    
    [self checkNecessaryDirectories];
    
    [application setIdleTimerDisabled:YES];
    
    [[EMConnectionListManager sharedManager] setAutomaticallyConnectsToLastDevice:YES];
    
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAudioProcessing error:&setCategoryError];
    
    if (!setCategoryError) {
        OSStatus propertySetError = 0;
        UInt32 allowMixing = true;
        
        propertySetError = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (allowMixing), &allowMixing);
    }
    else {
        NSLog(@"%@",[setCategoryError description]);
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:KEY_PLUS_ACTION] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:kGripSettingZoom] forKey:KEY_PLUS_ACTION];  // Set zoom in
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:kGripSettingZoom] forKey:KEY_MINUS_ACTION];  // Set zoom out
    }
    
    EMBluetoothLowEnergyConnectionType *connectionType = [[EMBluetoothLowEnergyConnectionType alloc] init];
    [[EMConnectionListManager sharedManager] addConnectionTypeToUpdates:connectionType];
    
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:kLastConnectedDevice]);
    
    return YES;
}

- (void)checkNecessaryDirectories {
    [[NSFileManager defaultManager] removeItemAtPath:CAPTURE_DIRECTORY error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:CAPTURE_DIRECTORY withIntermediateDirectories:NO attributes:nil error:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    if (self.vc.recordingVideo) {
        [self.vc stopRecordingVideo];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    while (navigationController.viewControllers.count > 1) {
        //NSLog(@"pop parent");
        [navigationController popViewControllerAnimated:NO];
        
    }
    
    [navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"did become active");
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    if (![[EMConnectionListManager sharedManager] isUpdating]) {
        [[EMConnectionListManager sharedManager] startUpdating];
    }
    else {
        NSLog(@"Already updating");
    }
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
