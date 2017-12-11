//
//  VideoEffect.h
//  ZetaCamera
//
//  Created by Me on 8/8/14.
//
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "Constant.h"

@interface VideoEffect : NSObject {

}

@property (nonatomic, strong) NSMutableArray    *pendingList;

typedef void (^FilterCompletion)(NSURL *movieURL);

+ (VideoEffect *)sharedInstance;

- (void)filterVideo:(NSURL *)videoURL filter:(VideoFilterType)filterType completionHandler:(FilterCompletion)completionHandler;

@end
