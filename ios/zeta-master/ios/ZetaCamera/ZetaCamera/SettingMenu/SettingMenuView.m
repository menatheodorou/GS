//
//  SettingMenuView.m
//  ZetaCamera
//
//  Created by Me on 8/18/14.
//
//

#import "SettingMenuView.h"
#import "SettingViewController.h"
#import "AppDelegate.h"
#import "ExposureView.h"
#import "WhiteBalanceView.h"
#import "GridView.h"
#import "OrientNavigationVC.h"
#import "Global.h"

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

@implementation SettingMenuView

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
    _subMenuIndex = -1;
    
    _menuBackgroundView.layer.cornerRadius = 8;
    _submenuBackgroundView.layer.cornerRadius = 8;
    _orientation = UIInterfaceOrientationPortrait;
    
    [self resetAspectButton];
    [self resetWBButton];
    [self resetExposureButton];
}

- (void)resetWBButton {    
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    
    GPUImageWhiteBalanceFilter *whiteFilter = (GPUImageWhiteBalanceFilter *)captureVC.whiteBalanceFilter;
    if (whiteFilter.temperature != 5000) {
        [_WBBtn setSelected:YES];
    } else {
        [_WBBtn setSelected:NO];
    }
}

- (void)resetExposureButton {
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    
    GPUImageExposureFilter *exposureFilter = (GPUImageExposureFilter *)captureVC.exposureFilter;
    if (exposureFilter.exposure != 0) {
        [_exposureBtn setSelected:YES];
    } else {
        [_exposureBtn setSelected:NO];
    }
}

- (void)resetAspectButton {
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    
    switch (captureVC.aspectRatio) {
        case kAspectType43:
            [self.aspectButton setImage:[UIImage imageNamed:@"aspect_4_3"] forState:UIControlStateNormal];
            break;
        case kAspectType11:
            [self.aspectButton setImage:[UIImage imageNamed:@"aspect_1_1"] forState:UIControlStateNormal];
            break;
        case kAspectType169:
            [self.aspectButton setImage:[UIImage imageNamed:@"aspect_16_9"] forState:UIControlStateNormal];
            break;
        default:
            captureVC.aspectRatio = kAspectType43;
            break;
    }
}

- (void)removeSubSettingView {
    [self.subMenu removeFromSuperview];
}

- (void)deselectButton {
    for (UIButton *subview in _menuView.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview == _WBBtn) {
                [self resetWBButton];
            } else if (subview == _exposureBtn) {
                [self resetExposureButton];
            } else {
                [subview setSelected:NO];
            }
        }
    }
}

#pragma mark - IBAction

- (IBAction)tapAspect:(id)sender {
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    
    if (captureVC.captureMode == kCaptureModeVideo) {
        return;
    } else {
        [self removeSubSettingView];
        [self deselectButton];
        
        _subMenuIndex = 0;
        
        
        switch (captureVC.aspectRatio) {
            case kAspectType43:
                captureVC.aspectRatio = kAspectType11;
                break;
            case kAspectType11:
                captureVC.aspectRatio = kAspectType169;
                break;
            case kAspectType169:
                captureVC.aspectRatio = kAspectType43;
                break;
            default:
                captureVC.aspectRatio = kAspectType43;
                break;
        }
        
        [_subMenuView setHidden:YES];
        [_submenuBackgroundView setHidden:YES];
        
        [self resetAspectButton];
    }
}

- (IBAction)tapExposure:(id)sender {
    if (_subMenuIndex != 1) {
        [self removeSubSettingView];
        [self deselectButton];
        
        [_subMenuView setHidden:NO];
        [_submenuBackgroundView setHidden:NO];
        
        self.subMenuView.contentOffset = CGPointZero;
        
        _subMenuIndex = 1;
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"ExposureView" owner:self options:nil];
        ExposureView *subview = nibs.firstObject;
        [_subMenuView setContentSize:subview.bounds.size];
        [self.subMenuView addSubview:subview];
        
        [_submenuBackgroundView setFrame:_subMenuView.frame];
        [subview setSelectedPosition];
        
        self.subMenu = subview;
        
        CGFloat degreeDiff = [self degreesForInterfaceOrientation:UIInterfaceOrientationPortrait] - [self degreesForInterfaceOrientation:self.orientation];
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(degreeDiff));
        
        for (UIView *subview in self.subMenu.subviews) {
            [subview setTransform:rotateTransform];
        }
        
        [_exposureBtn setSelected:YES];
    } else {
        [self removeSubSettingView];
        [self deselectButton];
        
        [_subMenuView setHidden:YES];
        [_submenuBackgroundView setHidden:YES];
        
        _subMenuIndex = -1;
    }
}

- (IBAction)tapWhiteBalance:(id)sender {
    if (_subMenuIndex != 2) {
        [self removeSubSettingView];
        [self deselectButton];
        
        [_subMenuView setHidden:NO];
        [_submenuBackgroundView setHidden:NO];
        
        self.subMenuView.contentOffset = CGPointZero;
        
        _subMenuIndex = 2;
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"WhiteBalanceView" owner:self options:nil];
        WhiteBalanceView *subview = nibs.firstObject;
        [_subMenuView setContentSize:subview.bounds.size];
        [self.subMenuView addSubview:subview];
        
        [_submenuBackgroundView setFrame:_subMenuView.frame];
        [subview setSelectedPosition];
        
        self.subMenu = subview;
        
        CGFloat degreeDiff = [self degreesForInterfaceOrientation:UIInterfaceOrientationPortrait] - [self degreesForInterfaceOrientation:self.orientation];
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(degreeDiff));
        
        for (UIView *subview in self.subMenu.subviews) {
            [subview setTransform:rotateTransform];
        }
        
        [_WBBtn setSelected:YES];
    } else {
        [self removeSubSettingView];
        [self deselectButton];
        
        [_subMenuView setHidden:YES];
        [_submenuBackgroundView setHidden:YES];
        
        _subMenuIndex = -1;
    }
}

- (IBAction)tapGrid:(id)sender {
    if (_subMenuIndex != 3) {
        [self removeSubSettingView];
        [self deselectButton];
        
        [(UIButton *)sender setSelected:YES];
        
        [_subMenuView setHidden:NO];
        [_submenuBackgroundView setHidden:NO];
        
        [self.subMenuView setContentOffset:CGPointZero];
        
        _subMenuIndex = 3;
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"GridView" owner:self options:nil];
        GridView *gridView = nibs.firstObject;
        [_subMenuView setContentSize:gridView.bounds.size];

        [self.subMenuView addSubview:gridView];
        
        if ([Global leftMode]) {
            [_submenuBackgroundView setFrame:_subMenuView.frame];
        } else {
            CGRect backgroundFrame = _submenuBackgroundView.frame;
            backgroundFrame.size.height = 230;
            [_submenuBackgroundView setFrame:backgroundFrame];
        }
        
        CGFloat degreeDiff = [self degreesForInterfaceOrientation:UIInterfaceOrientationPortrait] - [self degreesForInterfaceOrientation:self.orientation];
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(degreeDiff));
        
        for (UIView *subview in gridView.subviews) {
            [subview setTransform:rotateTransform];
        }
        
        self.subMenu = gridView;
    } else {
        [self removeSubSettingView];
        [self deselectButton];
        [(UIButton *)sender setSelected:NO];
        
        [_subMenuView setHidden:YES];
        [_submenuBackgroundView setHidden:YES];
        
        _subMenuIndex = -1;
    }
}

- (IBAction)tapPreference:(id)sender {
    
    [self removeSubSettingView];
    [self deselectButton];

    [_subMenuView setHidden:YES];
    [_submenuBackgroundView setHidden:YES];
    
    _subMenuIndex = 4;
    
    [self.delegate willShowSettingView];
}

#pragma mark - Orientation

-(CGFloat)degreesForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGFloat value;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            value = 0.0f;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            value = 180.0f;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            value = 90.0f;
            break;
        case UIInterfaceOrientationLandscapeRight:
            value = 270.0f;
            break;
        default:
            value = 0.0f;
            break;
    }
    return value;
}


- (void)setOrientation:(UIInterfaceOrientation)orientation {
    _orientation = orientation;
    
    CGFloat degreeDiff = [self degreesForInterfaceOrientation:UIInterfaceOrientationPortrait] - [self degreesForInterfaceOrientation:orientation];
    
    [UIView animateWithDuration:0.2 animations:^{
 
    }];
    
    CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(DegreesToRadians(degreeDiff));
    
    for (UIView *subView in _menuView.subviews) {
        if ([subView isKindOfClass:[UIButton class]]) {
            [subView setTransform:rotateTransform];
        }
    }
    
    for (UIView *subview in self.subMenu.subviews) {
        [subview setTransform:rotateTransform];
    }
}

#pragma mark - Touch Delegate

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch Ended");
    ImageCaptureViewController *captureVC = ApplicationDelegate.vc;
    [captureVC tapSetting:nil];
}

@end
