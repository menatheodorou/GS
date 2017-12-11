//
//  SettingMenuView.h
//  ZetaCamera
//
//  Created by Me on 8/18/14.
//
//

#import <UIKit/UIKit.h>

@protocol SettingMenuDelegate <NSObject>

- (void)willShowSettingView;

@end

@interface SettingMenuView : UIView {
    IBOutlet UIImageView *_menuBackgroundView;
    IBOutlet UIImageView *_submenuBackgroundView;
    
    IBOutlet UIButton   *_exposureBtn;
    IBOutlet UIButton   *_WBBtn;
    IBOutlet UIButton   *_gridBtn;
}

@property (nonatomic, weak) IBOutlet UIView *menuView;
@property (nonatomic, strong) IBOutlet UIScrollView *subMenuView;
@property (nonatomic, strong) UIView    *subMenu;
@property (nonatomic, strong) IBOutlet UIButton *aspectButton;

@property (nonatomic, assign) NSInteger subMenuIndex;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

@property (nonatomic, weak) id<SettingMenuDelegate> delegate;

- (IBAction)tapGrid:(id)sender;
- (IBAction)tapExposure:(id)sender;
- (IBAction)tapWhiteBalance:(id)sender;
- (void)resetWBButton;
- (void)resetExposureButton;

@end
