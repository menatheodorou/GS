//
//  SwitchCellTableViewCell.h
//  ZetaCamera
//
//  Created by Me on 9/26/14.
//
//

#import <UIKit/UIKit.h>

@interface SwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

@end
