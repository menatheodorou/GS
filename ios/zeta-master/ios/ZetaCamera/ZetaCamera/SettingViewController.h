//
//  SettingViewController.h
//  ZetaCamera
//
//  Created by Me on 8/11/14.
//
//

#import <UIKit/UIKit.h>

@class SettingViewController;

@protocol SettingViewControllerDelegate <NSObject>

- (void)didDismissViewController:(SettingViewController *)settingVC;

@end

@interface SettingViewController : UIViewController {
    IBOutlet UITableView    *_tableView;
}

@property (nonatomic, strong) NSMutableArray    *menuItems;
@property (nonatomic, weak) id<SettingViewControllerDelegate> delegate;

@end
