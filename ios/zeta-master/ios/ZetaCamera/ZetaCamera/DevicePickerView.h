//
//  DevicePickerView.h
//  ZetaCamera
//
//  Created by Dexter Weiss on 4/5/13.
//
//

#import <UIKit/UIKit.h>

@interface DevicePickerView : UIView

@property (nonatomic, getter = isFlipped) BOOL flipped;
@property (nonatomic, retain) IBOutlet UITableView *_table;
@end
