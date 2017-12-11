//
//  PhotoEffect.h
//  ZetaCamera
//
//  Created by Me on 8/8/14.
//
//

#import <Foundation/Foundation.h>
#import "Constant.h"

@interface PhotoEffect : NSObject

+ (PhotoEffect *)sharedInstance;

- (UIImage *)filterImage:(UIImage *)sourceImg filter:(PhotoFilterType)filterType;

@end
