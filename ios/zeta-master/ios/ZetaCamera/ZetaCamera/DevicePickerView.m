//
//  DevicePickerView.m
//  ZetaCamera
//
//  Created by Dexter Weiss on 4/5/13.
//
//

#import "DevicePickerView.h"
#import "UIImage+ImageCrop.h"

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

#define FLIP_OFFSET 11

@interface DevicePickerView () {
    @private
    IBOutlet UIImageView *_backgroundView;
    
}

@end

@implementation DevicePickerView

-(void)setFlipped:(BOOL)flipped {
    if (flipped == [self isFlipped]) {
        return;
    }
    [self willChangeValueForKey:@"flipped"];
    _flipped = flipped;
    [self didChangeValueForKey:@"flipped"];
    
    CGAffineTransform rotateTransform;
    CGRect currentTableFrame = [self._table frame];
    if (flipped) {
        rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(180));
        [self._table setFrame:CGRectMake(currentTableFrame.origin.x, currentTableFrame.origin.y - FLIP_OFFSET, currentTableFrame.size.width, currentTableFrame.size.height)];
    }
    else {
        rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(0));
        [self._table setFrame:CGRectMake(currentTableFrame.origin.x, currentTableFrame.origin.y + FLIP_OFFSET, currentTableFrame.size.width, currentTableFrame.size.height)];
    }
    [_backgroundView setTransform:rotateTransform];
}

@end
