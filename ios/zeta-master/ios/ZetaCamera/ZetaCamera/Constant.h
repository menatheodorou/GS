//
//  Constant.h
//  ZetaCamera
//
//  Created by Me on 8/11/14.
//
//

#ifndef ZetaCamera_Constant_h
#define ZetaCamera_Constant_h

#define CAPTURE_DIRECTORY [NSString stringWithFormat:@"%@capture", NSTemporaryDirectory()]


typedef enum {
    kVideoFilterNone,
    kVideoFilterMono,
    kVideoFilterFalse,
    kVideoFilterChroma,
    kVideoFilterFrameLine
} VideoFilterType;

typedef enum {
    kPhotoFilterNone,
    kPhotoFilterMono,
    kPhotoFilterSepia,
    kPhotoFilterNegative,
    kPhotoFilterSketch,
    kPhotoFilterNeon
} PhotoFilterType;

#define KEY_PLUS_ACTION     @"plus_action"
#define KEY_MINUS_ACTION     @"minus_action"

typedef enum {
    kGripSettingAspect,
    kGripSettingExposure,
    kGripSettingFlash,
    kGripSettingGeoTagging,
    kGripSettingGrid,
    kGripSettingCameraMode,
    kGripSettingPhotoPreview,
    kGripSettingPreference,
    kGripSettingCameraType,
    kGripSettingWhiteBalance,
    kGripSettingZoom
} GripSettingType;


#endif
