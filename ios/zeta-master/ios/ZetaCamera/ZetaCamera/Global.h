//
//  Global.h
//  ZetaCamera
//
//  Created by Me on 8/8/14.
//
//

#import <Foundation/Foundation.h>

@interface Global : NSObject

+ (NSInteger)videoFilterType;
+ (void)setVideoFilterType:(NSInteger)filterType;

+ (NSInteger)photoFilterType;
+ (void)setPhotoFilterType:(NSInteger)filterType;

+ (BOOL)showGeoTagging;
+ (void)setShowGetTagging:(BOOL)geoTagging;

+ (BOOL)hideIndicator;
+ (void)setHideIndicator:(BOOL)showIndicator;

+ (BOOL)leftMode;
+ (void)setLeftMode:(BOOL)leftMode;


@end
