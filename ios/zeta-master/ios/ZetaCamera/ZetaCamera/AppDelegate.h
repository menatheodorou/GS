//
//  AppDelegate.h
//  ZetaCamera
//
//  Created by benjamin michel on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageCaptureViewController.h"

#define ApplicationDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    UINavigationController *navigationController;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;
//view controller
@property (strong, nonatomic) IBOutlet ImageCaptureViewController *vc;

@end
