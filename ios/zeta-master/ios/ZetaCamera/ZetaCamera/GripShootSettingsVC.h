//
//  GripShootSettingsVC.h
//  ZetaCamera
//
//  Created by Me on 9/16/14.
//
//

#import <UIKit/UIKit.h>

@interface GripShootSettingsVC : UIViewController {
    IBOutlet UITableView    *_tableView;
}

@property (nonatomic, strong) NSMutableArray    *menuItems;

@end
