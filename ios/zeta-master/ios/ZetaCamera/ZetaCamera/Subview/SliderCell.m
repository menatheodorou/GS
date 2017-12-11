//
//  SliderCell.m
//  ZetaCamera
//
//  Created by Admin on 9/16/14.
//
//

#import "SliderCell.h"

@implementation SliderCell

- (void)awakeFromNib
{
    // Initialization code
    [_increaseButton.layer setBorderColor:[UIColor grayColor].CGColor];
    _increaseButton.layer.borderWidth = 1;
    _increaseButton.layer.cornerRadius = _increaseButton.bounds.size.width / 2;
    
    [_decreaseButton.layer setBorderColor:[UIColor grayColor].CGColor];
    _decreaseButton.layer.borderWidth = 1;
    _decreaseButton.layer.cornerRadius = _increaseButton.bounds.size.width / 2;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title {
    _titleLabel.text = title;
}

- (void)setSelectedCell:(BOOL)selectedCell {
    if (selectedCell) {
        [_increaseButton setBackgroundColor:[UIColor colorWithRed:13.0/255 green:195.0/255 blue:34.0/255 alpha:1.0]];
        [_decreaseButton setBackgroundColor:[UIColor colorWithRed:13.0/255 green:195.0/255 blue:34.0/255 alpha:1.0]];
    } else {
        [_increaseButton setBackgroundColor:[UIColor clearColor]];
        [_decreaseButton setBackgroundColor:[UIColor clearColor]];
    }
}

- (IBAction)tapPlus:(id)sender {
    [self.sliderDelegate didSelectPlus:self];
}

- (IBAction)tapMinus:(id)sender {
    [self.sliderDelegate didSelectMinus:self];
}

@end
