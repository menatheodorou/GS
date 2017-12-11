//
//  Global.m
//  ZetaCamera
//
//  Created by Me on 8/8/14.
//
//

#import "Global.h"

#define KEY_VIDEO_FILTER    @"video_filter"
#define KEY_PHOTO_FILTER    @"photo_filter"
#define KEY_GEOTAGGING      @"geotagging"
#define KEY_SHOW_INDICATOR  @"show_indicator"
#define KEY_LEFT_MODE       @"left_mode"

@implementation Global

+ (NSInteger)videoFilterType {
    NSInteger videoFilter = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_VIDEO_FILTER];
    return videoFilter;
}

+ (void)setVideoFilterType:(NSInteger)filterType {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:filterType] forKey:KEY_VIDEO_FILTER];
     [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger)photoFilterType {
    NSInteger photoFilter = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_PHOTO_FILTER];
    return photoFilter;
}

+ (void)setPhotoFilterType:(NSInteger)filterType {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:filterType] forKey:KEY_PHOTO_FILTER];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)showGeoTagging {
    BOOL geoTagging = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_GEOTAGGING];
    return geoTagging;
}

+ (void)setShowGetTagging:(BOOL)geoTagging {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:geoTagging] forKey:KEY_GEOTAGGING];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (BOOL)hideIndicator {
    BOOL showIndicator = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_SHOW_INDICATOR];
    return showIndicator;
}

+ (void)setHideIndicator:(BOOL)showIndicator {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:showIndicator] forKey:KEY_SHOW_INDICATOR];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (BOOL)leftMode {
    BOOL leftMode = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_LEFT_MODE];
    return leftMode;
}

+ (void)setLeftMode:(BOOL)leftMode {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:leftMode] forKey:KEY_LEFT_MODE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
