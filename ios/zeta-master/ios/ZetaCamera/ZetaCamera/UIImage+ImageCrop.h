

@interface UIImage (ImageCrop)

-(UIImage *)standardImageFromCurrentScale:(float)scale;
-(UIImage *)standardImageFromCurrentScale:(float)scale additionalRotation:(CGFloat)degrees;

- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;


@end
