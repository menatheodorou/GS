//
//  GridView.m
//  ZetaCamera
//
//  Created by Me on 9/1/14.
//
//

#import "GridView.h"
#import "ImageCaptureViewController.h"
#import "AppDelegate.h"
#import "SettingMenuView.h"

@implementation GridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)awakeFromNib {
    [super awakeFromNib];
    
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    NSInteger buttonIndex = 0;
    
    switch (captureVC.gridType) {
        case kGridTypeNone:
            buttonIndex = 0;
            break;
        case kGridTypeSquare:
            buttonIndex = 1;
            break;
        case kGridTypeSprial:
            buttonIndex = 2;
            break;
        case kGridTypeTriangle:
            buttonIndex = 3;
            break;
        default:
            break;
    }
    
    for (UIButton *subview in self.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            subview.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    }
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.tag == buttonIndex) {
                [(UIButton *)subview setSelected:YES];
            }
        }
    }
    
    [self resetGrid];
}

- (void)resetGrid {
    [_rotateButton setEnabled:NO];
    
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    
    if (captureVC.gridType == kGridTypeSprial) {
        [self.spiralButton setBackgroundColor:[UIColor colorWithRed:0 green:149.0/255 blue:218.0/255 alpha:1.0]];
        [_rotateButton setEnabled:YES];
    } else if (captureVC.gridType == kGridTypeSquare) {
        [self.squareButton setBackgroundColor:[UIColor colorWithRed:0 green:149.0/255 blue:218.0/255 alpha:1.0]];
    } else if (captureVC.gridType == kGridTypeTriangle) {
        [self.triangleButton setBackgroundColor:[UIColor colorWithRed:0 green:149.0/255 blue:218.0/255 alpha:1.0]];
        [_rotateButton setEnabled:YES];
    }

}

- (IBAction)tapGrid:(id)sender {
    [_rotateButton setEnabled:NO];
    
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    UIButton *gridButton = (UIButton *)sender;
    
    switch (gridButton.tag) {
        case 0:
            captureVC.gridType = kGridTypeNone;
            [captureVC.settingView tapGrid:nil];
            break;
        case 1:
            captureVC.gridType = kGridTypeSquare;
            break;
        case 2:
            if (captureVC.aspectRatio != kAspectType11) {
                captureVC.gridType = kGridTypeSprial;
                [_rotateButton setEnabled:YES];
            } else {
                return;
            }
            
            break;
        case 3:
            if (captureVC.aspectRatio != kAspectType11) {
                captureVC.gridType = kGridTypeTriangle;
                [_rotateButton setEnabled:YES];
            } else {
                return;
            }
            
            break;
        default:
            captureVC.gridType = kGridTypeSprial;
            break;
    }
    
    for (UIButton *subview in self.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            button.backgroundColor = [UIColor clearColor];
        }
    }
    
    [gridButton setBackgroundColor:[UIColor colorWithRed:0 green:149.0/255 blue:218.0/255 alpha:1.0]];
}

- (IBAction)tapRotate:(id)sender {
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    [captureVC rotateGridView];
}

@end
