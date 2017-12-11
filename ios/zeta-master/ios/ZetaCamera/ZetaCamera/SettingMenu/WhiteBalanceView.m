//
//  WhiteBalanceView.m
//  ZetaCamera
//
//  Created by Me on 8/18/14.
//
//

#import "WhiteBalanceView.h"
#import "AppDelegate.h"
#import "SettingMenuView.h"

@implementation WhiteBalanceView

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
    // Drawing codej
}
*/

- (void)awakeFromNib {
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    GPUImageWhiteBalanceFilter *filter = (GPUImageWhiteBalanceFilter *)captureVC.whiteBalanceFilter;
    NSInteger buttonTag = 0;
    
    if (filter.temperature == 5000) {
        buttonTag = 0;
    } else if (filter.temperature == 1000) {
        buttonTag = 1;
    } else if (filter.temperature == 2000) {
        buttonTag = 2;
    } else if (filter.temperature == 3000) {
        buttonTag = 3;
    } else if (filter.temperature == 4000) {
        buttonTag = 4;
    } else if (filter.temperature == 5500) {
        buttonTag = 5;
    } else if (filter.temperature == 6500) {
        buttonTag = 6;
    } else if (filter.temperature == 7000) {
        buttonTag = 7;
    } else if (filter.temperature == 8000) {
        buttonTag = 8;
    } else if (filter.temperature == 9000) {
        buttonTag = 9;
    } else if (filter.temperature == 10000) {
        buttonTag = 10;
    } else {
        buttonTag = 0;
    }
    
    for (UIView *subview in self.subviews) {
        for (UIButton *subButton in subview.subviews) {
            if ([subButton isKindOfClass:[UIButton class]]) {
                subButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            }
        }
        
    }
    
    UIButton *selectedButton = nil;
    
    for (UIView *subview in self.subviews) {
        for (UIButton *subButton in subview.subviews) {
            if ([subButton isKindOfClass:[UIButton class]]) {
                if (subButton.tag == buttonTag) {
                    selectedButton = subButton;
                    [(UIButton *)subButton setSelected:YES];
                }
            }
        }
    }
}

- (void)setSelectedPosition {
    UIButton *selectedButton = nil;
    
    for (UIView *subview in self.subviews) {
        for (UIButton *subButton in subview.subviews) {
            if ([subButton isKindOfClass:[UIButton class]]) {
                if (subButton.selected) {
                    selectedButton = subButton;
                }
            }
        }
    }
    
    if (selectedButton) {
        if (selectedButton.superview.frame.origin.y + selectedButton.superview.frame.size.height > self.superview.frame.size.height) {
            UIScrollView *scrollView = (UIScrollView *)self.superview;
            scrollView.contentOffset = CGPointMake(0, selectedButton.superview.frame.origin.y + selectedButton.superview.frame.size.height - scrollView.frame.size.height);
        }
    }
}

- (IBAction)tapWhiteBalance:(id)sender {
    UIButton *btn = (UIButton *)sender;
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    GPUImageWhiteBalanceFilter *filter = (GPUImageWhiteBalanceFilter *)captureVC.whiteBalanceFilter;
    
    for (UIView *subview in self.subviews) {
        for (UIButton *subButton in subview.subviews) {
            if ([subButton isKindOfClass:[UIButton class]]) {
                [(UIButton *)subButton setSelected:NO];
            }
        }
    }
    
    switch (btn.tag) {
        case 0:
            [filter setTemperature:5000];
             [filter setTint:0];
            [captureVC.settingView tapWhiteBalance:nil];
            break;
        case 1:
            [filter setTemperature:1000];
             [filter setTint:21];
            break;
        case 2:
            [filter setTemperature:2000];
             [filter setTint:21];
            break;
        case 3:
            [filter setTemperature:3000];
             [filter setTint:0];
            break;
        case 4:
            [filter setTemperature:4000];
             [filter setTint:21];
            break;
        case 5:
            [filter setTemperature:5500];
            [filter setTint:10];
            break;
        case 6:
            [filter setTemperature:6500];
            [filter setTint:10];
            break;
        case 7:
            [filter setTemperature:7000];
            [filter setTint:10];
            break;
        case 8:
            [filter setTemperature:8000];
             [filter setTint:10];
            break;
        case 9:
            [filter setTemperature:9000];
             [filter setTint:10];
            break;
        case 10:
            [filter setTemperature:10000];
            break;
        default:
            break;
    }
    
    [captureVC.settingView resetWBButton];
    
    [btn setSelected:YES];
    
    for (UIView *subview in self.subviews) {
        for (UIButton *subButton in subview.subviews) {
            if ([subButton isKindOfClass:[UIButton class]]) {
                if (subButton.tag == btn.tag) {
                    [(UIButton *)subButton setSelected:YES];
                }
            }
        }
    }
    
    [captureVC resetSCN];
}

@end
