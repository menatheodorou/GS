//
//  GripShootSettingsVC.m
//  ZetaCamera
//
//  Created by Me on 9/16/14.
//
//

#import "GripShootSettingsVC.h"
#import "Global.h"
#import "SliderCell.h"
#import "Constant.h"

@interface GripShootSettingsVC () <UITableViewDataSource, SliderCellDelegate>

@end

@implementation GripShootSettingsVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.menuItems = [NSMutableArray array];
    
    NSDictionary *item = @{@"text": @"Aspect Ratio Toggle", @"type": @"slider"};
    NSArray *menulist = @[item];
    NSDictionary *menuInfo = @{@"footer": @"Choose button to control scrolling thru 4:3, 1:1, and 16:9 aspect ratios", @"list": menulist};
    [self.menuItems addObject:menuInfo];

    item = @{@"text": @"Exposure Control", @"type": @"switch"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Control Exposure using +/- buttons", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"Flash Toggle", @"type": @"slider"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Choose button to control scrolling thru Flash On, Flash Off, Automatic, Flashlight", @"list": menulist};
    [self.menuItems addObject:menuInfo];

    item = @{@"text": @"Geo Tagging Toggle", @"type": @"slider"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Choose button to control scrolling thru Geo Tagging On, Geo Tagging Off", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"Grid Toggle", @"type": @"slider"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Choose button to control scrolling thru Off, Grid, Spiral, Triangle", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"Photo/Video Toggle", @"type": @"slider"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Choose button to control scrolling thru Photo, Video", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"Photo Preview Toggle", @"type": @"slider"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Choose button to review captured Photo", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"Preferences Toggle", @"type": @"slider"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Choose button to review Preferences", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"Switch Camera Toggle", @"type": @"slider"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Choose button to control scrolling thru Front Camera, Rear Camera", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"White Balance Control", @"type": @"switch"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Control White Balance using +/- buttons", @"list": menulist};
    [self.menuItems addObject:menuInfo];
    
    item = @{@"text": @"Zoom Control", @"type": @"switch"};
    menulist = @[item];
    menuInfo = @{@"footer": @"Control Zoom using +/- buttons", @"list": menulist};
    [self.menuItems addObject:menuInfo];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)changeSwitch:(id)sender {
    UISwitch *switchView = (UISwitch *)sender;
    NSInteger buttonTag = switchView.tag - 100;
    BOOL setting = switchView.on;
    
    if (setting) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:buttonTag] forKey:KEY_PLUS_ACTION];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:buttonTag] forKey:KEY_MINUS_ACTION];
    } else {
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:kGripSettingZoom] forKey:KEY_PLUS_ACTION];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:kGripSettingZoom] forKey:KEY_MINUS_ACTION];
    }
    
    [_tableView reloadData];
}


#pragma mark - UITableView view data source

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSDictionary *menuInfo = self.menuItems[section];
    return [menuInfo objectForKey:@"footer"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        return 35;
    } else {
        NSDictionary *menuInfo = self.menuItems[section];
        NSString *title = [menuInfo objectForKey:@"footer"];
        
        if (title.length < 40) {
            return 35;
        } else {
            return 50;
        }
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.menuItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *menuInfo = self.menuItems[section];
    NSArray *menuList = [menuInfo objectForKey:@"list"];
    return menuList.count;
}

- (UITableViewCell *)textCell {
    static NSString *cellIdentifier = @"TextCell";
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    return cell;
}

- (SliderCell *)sliderCell {

    static NSString *cellIdentifier = @"SliderCell";
    SliderCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"SliderCell" owner:self options:nil];
        cell = nibs.firstObject;
    }
    
    return cell;
}

- (UITableViewCell *)switchViewCell {
    static NSString *cellIdentifier = @"SwitchCell";
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 7, 60, 30)];
        [switchView addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:switchView];
        switchView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *menuInfo = self.menuItems[indexPath.section];
    NSArray *menuList = [menuInfo objectForKey:@"list"];
    NSDictionary *menuItem = menuList[indexPath.row];
    
    if ([[menuItem objectForKey:@"type"] isEqualToString:@"slider"]) {
        SliderCell *cell = [self sliderCell];
        [cell setTitle:[menuItem objectForKey:@"text"]];
        cell.cellIndex = indexPath.section;
        cell.sliderDelegate = self;
        
        NSInteger plusIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_PLUS_ACTION] integerValue];
        
        if (plusIndex == indexPath.section) {
            [cell.increaseButton setBackgroundColor:[UIColor colorWithRed:13.0/255 green:195.0/255 blue:34.0/255 alpha:1.0]];
        } else {
            [cell.increaseButton setBackgroundColor:[UIColor clearColor]];
        }
        
        NSInteger minusIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_MINUS_ACTION] integerValue];
        
        if (minusIndex == indexPath.section) {
            [cell.decreaseButton setBackgroundColor:[UIColor colorWithRed:13.0/255 green:195.0/255 blue:34.0/255 alpha:1.0]];
        } else {
            [cell.decreaseButton setBackgroundColor:[UIColor clearColor]];
        }
        
        return cell;
    } else if ([[menuItem objectForKey:@"type"] isEqualToString:@"switch"]) {
        UITableViewCell *cell = [self switchViewCell];
        cell.textLabel.text = [menuItem objectForKey:@"text"];
        UISwitch *switchView = nil;
        
        for (UIView *subView in cell.contentView.subviews) {
            if ([subView isKindOfClass:[UISwitch class]]) {
                switchView = (UISwitch *)subView;
                switchView.tag = 100 + indexPath.section;
            }
        }
        
        NSInteger plusIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_PLUS_ACTION] integerValue];
        
        if (plusIndex == indexPath.section) {
            [switchView setOn:YES];
        } else {
            [switchView setOn:NO];
        }
        
        return cell;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

#pragma mark - Slider Cell Delegate

- (void)didSelectPlus:(SliderCell *)cell {
    NSInteger currentIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_PLUS_ACTION] integerValue];
    
    if (currentIndex > -1) {
        NSDictionary *menuInfo = self.menuItems[currentIndex];
        NSArray *menuList = [menuInfo objectForKey:@"list"];
        NSDictionary *menuItem = menuList[0];
        
        if ([[menuItem objectForKey:@"type"] isEqualToString:@"switch"]) {
            [[NSUserDefaults standardUserDefaults] setObject:@-1 forKey:KEY_MINUS_ACTION];
        }
    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:cell.cellIndex] forKey:KEY_PLUS_ACTION];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [_tableView reloadData];
}

- (void)didSelectMinus:(SliderCell *)cell {
    NSInteger currentIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:KEY_MINUS_ACTION] integerValue];
    
    if (currentIndex > -1) {
        NSDictionary *menuInfo = self.menuItems[currentIndex];
        NSArray *menuList = [menuInfo objectForKey:@"list"];
        NSDictionary *menuItem = menuList[0];
        
        if ([[menuItem objectForKey:@"type"] isEqualToString:@"switch"]) {
            [[NSUserDefaults standardUserDefaults] setObject:@-1 forKey:KEY_PLUS_ACTION];
        }
    }
   
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:cell.cellIndex] forKey:KEY_MINUS_ACTION];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [_tableView reloadData];
}

@end
