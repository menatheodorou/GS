//
//  SliderCell.h
//  ZetaCamera
//
//  Created by Admin on 9/16/14.
//
//

#import <UIKit/UIKit.h>

@class SliderCell;

@protocol SliderCellDelegate <NSObject>

- (void)didSelectPlus:(SliderCell *)cell;
- (void)didSelectMinus:(SliderCell *)cell;

@end

@interface SliderCell : UITableViewCell {
    IBOutlet UILabel    *_titleLabel;
}

@property (nonatomic, weak) IBOutlet UIButton   *increaseButton;
@property (nonatomic, weak) IBOutlet UIButton   *decreaseButton;
@property (nonatomic, weak) id<SliderCellDelegate> sliderDelegate;
@property (nonatomic, assign) NSInteger cellIndex;

- (void)setTitle:(NSString *)title;

@end
