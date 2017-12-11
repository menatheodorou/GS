//
//  PhotoEffect.m
//  ZetaCamera
//
//  Created by Me on 8/8/14.
//
//

#import "PhotoEffect.h"
#import "GPUImage.h"

@implementation PhotoEffect

+ (PhotoEffect *)sharedInstance
{
    static PhotoEffect *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[PhotoEffect alloc] init];
    });
    return singleton;
}

- (UIImage *)filterImage:(UIImage *)sourceImg filter:(PhotoFilterType)filterType {
    switch (filterType) {
        case kPhotoFilterNone:
            return sourceImg;
            break;
        case kPhotoFilterNegative:
            return [self negativeImage:sourceImg];
            break;
        case kPhotoFilterMono:
            return [self monoImage:sourceImg];
            break;
        case kPhotoFilterNeon:
            return [self neonImage:sourceImg];
            break;
        case kPhotoFilterSepia:
            return [self sepiaImage:sourceImg];
            break;
        case kPhotoFilterSketch:
            return [self sketchImage:sourceImg];
            break;
        default:
            return sourceImg;
            break;
    }
}

- (UIImage *)monoImage:(UIImage *)sourceImg {
    GPUImageSaturationFilter *stillImageFilter = [[GPUImageSaturationFilter alloc] init];
    stillImageFilter.saturation = 0;
    UIImage *currentFilteredImage = [stillImageFilter imageByFilteringImage:sourceImg];
    
    return currentFilteredImage;
}

- (UIImage *)sepiaImage:(UIImage *)sourceImg {
    GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];
    UIImage *currentFilteredImage = [stillImageFilter imageByFilteringImage:sourceImg];
    
    return currentFilteredImage;
    
}

- (UIImage *)negativeImage:(UIImage *)sourceImg {
    GPUImageColorInvertFilter *invertFilter = [[GPUImageColorInvertFilter alloc] init];
    UIImage *currentFilteredImage = [invertFilter imageByFilteringImage:sourceImg];
    
    return currentFilteredImage;
 
}

- (UIImage *)sketchImage:(UIImage *)sourceImg {
    GPUImageSketchFilter *stillImageFilter = [[GPUImageSketchFilter alloc] init];
    UIImage *currentFilteredImage = [stillImageFilter imageByFilteringImage:sourceImg];
    
    return currentFilteredImage;

}

- (UIImage *)neonImage:(UIImage *)sourceImg {
    return sourceImg;
}

@end
