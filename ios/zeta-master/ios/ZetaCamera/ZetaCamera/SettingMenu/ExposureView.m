//
//  ExposureView.m
//  ZetaCamera
//
//  Created by Me on 8/18/14.
//
//

#import "ExposureView.h"
#import "AppDelegate.h"
#import "SettingMenuView.h"

@implementation ExposureView

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
    GPUImageExposureFilter *filter = (GPUImageExposureFilter *)captureVC.exposureFilter;
    NSInteger selectedButtonTag = 0;
    
    if (filter.exposure == -2) {
        selectedButtonTag = 0;
    } else if (filter.exposure == -1.5) {
        selectedButtonTag = 1;
    } else if (filter.exposure == -1) {
        selectedButtonTag = 2;
    } else if (filter.exposure == -0.5) {
        selectedButtonTag = 3;
    } else if (filter.exposure == 0) {
        selectedButtonTag = 4;
    } else if (filter.exposure == 0.5) {
        selectedButtonTag = 5;
    } else if (filter.exposure == 1.0) {
        selectedButtonTag = 6;
    } else if (filter.exposure == 1.5) {
        selectedButtonTag = 7;
    } else if (filter.exposure == 2) {
        selectedButtonTag = 8;
    } else {
        selectedButtonTag = 5;
    }
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.tag == selectedButtonTag) {
                [(UIButton *)subview setSelected:YES];
            }
        }
    }
}

- (void)setSelectedPosition {
    UIButton *selectedButton = nil;
    
    for (UIButton *subview in self.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.selected) {
                selectedButton = subview;
            }
        }
    }
    
    if (selectedButton) {
        if (selectedButton.frame.origin.y + selectedButton.frame.size.height > self.superview.frame.size.height) {
            UIScrollView *scrollView = (UIScrollView *)self.superview;
            scrollView.contentOffset = CGPointMake(0, selectedButton.frame.origin.y + selectedButton.frame.size.height - scrollView.frame.size.height);
        }
    }
}

- (IBAction)tapExposure:(id)sender {
    UIButton *btn = (UIButton *)sender;
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    GPUImageExposureFilter *filter = (GPUImageExposureFilter *)captureVC.exposureFilter;
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [(UIButton *)subview setSelected:NO];
        }
    }
    
    switch (btn.tag) {
        case 0:
            [filter setExposure:-2.0];
            break;
        case 1:
            [filter setExposure:-1.5];
            break;
        case 2:
            [filter setExposure:-1];
            break;
        case 3:
            [filter setExposure:-0.5];
            break;
        case 4:
            [filter setExposure:0];
            break;
        case 5:
            [filter setExposure:0.5];
            break;
        case 6:
            [filter setExposure:1.0];
            break;
        case 7:
            [filter setExposure:1.5];
            break;
        case 8:
            [filter setExposure:2];
            break;
        default:
            break;
    }
    
    [btn setSelected:YES];
    
    [captureVC.settingView resetExposureButton];
    [captureVC resetSCN];
}

@end
