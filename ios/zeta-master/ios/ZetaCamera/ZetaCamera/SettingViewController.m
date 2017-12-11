//
//  SettingViewController.m
//  ZetaCamera
//
//  Created by Me on 8/11/14.
//
//

#import "SettingViewController.h"
#import "Global.h"
#import "InstructionViewController.h"
#import "SwitchCell.h"
#import <MessageUI/MessageUI.h>

@interface SettingViewController () <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>

@end

@implementation SettingViewController

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
    
    NSDictionary *item1 = @{@"text": @"Geo Tagging", @"type": @"switch"};
    NSDictionary *item2 = @{@"text": @"Left Handed Mode", @"type": @"switch"};
    NSDictionary *item3 = @{@"text": @"Display Indicators", @"type": @"switch"};
    NSDictionary *item4 = @{@"text": @"Instructions", @"type": @"text"};
    NSDictionary *item5 = @{@"text": @"Rate/Review GRIP&SHOOT App", @"type": @"text"};
    NSDictionary *item6 = @{@"text": @"Give Feedback/Report a Bug", @"type": @"text"};
    
    NSArray *firstMenuList = @[item1, item2, item3, item4, item5, item6];
    NSDictionary *firstMenu = @{@"header": @"GRIP&SHOOT Settings", @"list": firstMenuList};
    [self.menuItems addObject:firstMenu];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapDone:(id)sender {
    [self.delegate didDismissViewController:self];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)changeSwitch:(id)sender {
    UISwitch *switchView = (UISwitch *)sender;
    NSInteger buttonTag = switchView.tag - 100;
    BOOL setting = switchView.on;
    
    switch (buttonTag) {
        case 0:
            [Global setShowGetTagging:setting];
            break;
        case 1:
            [Global setLeftMode:setting];
            break;
        case 2:
            [Global setHideIndicator:!setting];
            break;
        default:
            break;
    }
}

- (void)showInstructions {
    InstructionViewController *instructionVC = [[InstructionViewController alloc] init];
    [self.navigationController pushViewController:instructionVC animated:YES];
}

- (void)showRateView {
    NSString *appstoreURLFormat = @"itms-apps://itunes.apple.com/app/id666510503";
    NSURL *appStoreURL = [NSURL URLWithString:appstoreURLFormat];
    [[UIApplication sharedApplication] openURL:appStoreURL];
}

- (void)showFeedbackView {
    if ([MFMailComposeViewController canSendMail]) {
        NSString *description = @"";
        NSString *emailAddress = @"support@gripandshoot.com";
        
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:[NSString stringWithFormat:@"Feedback"]];
        [picker setMessageBody:description isHTML:YES];
        
        [picker setToRecipients:@[emailAddress]];
        
        [self presentViewController:picker animated:YES completion:^{
            
        }];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Your device is not able to send email." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#pragma mark - UITableView view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *menuInfo = self.menuItems[section];
    return [menuInfo objectForKey:@"header"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
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

- (SwitchCell *)switchViewCell {
    static NSString *cellIdentifier = @"SwitchCell";
    SwitchCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
        cell = nibs.firstObject;
        
        [cell.switchView addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *menuInfo = self.menuItems[indexPath.section];
    NSArray *menuList = [menuInfo objectForKey:@"list"];
    NSDictionary *menuItem = menuList[indexPath.row];
    
    if ([[menuItem objectForKey:@"type"] isEqualToString:@"text"]) {
        UITableViewCell *cell = [self textCell];;
        cell.textLabel.text = [menuItem objectForKey:@"text"];
        return cell;
    } else if ([[menuItem objectForKey:@"type"] isEqualToString:@"switch"]) {
        SwitchCell *cell = [self switchViewCell];
        cell.titleLabel.text = [menuItem objectForKey:@"text"];
        cell.switchView.tag = 100 + indexPath.row;
        
        switch (indexPath.row) {
            case 0:
                [cell.switchView setOn:[Global showGeoTagging]];
                break;
            case 1:
                [cell.switchView setOn:[Global leftMode]];
                break;
            case 2:
                [cell.switchView setOn:![Global hideIndicator]];
                break;
            default:
                break;
        }
        
        return cell;
    } else {
        return nil;
    }    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 3:
            [self showInstructions];
            break;
        case 4:
            [self showRateView];
            break;
        case 5:
            [self showFeedbackView];
            break;
        default:
            break;
    }
}

#pragma mark MFMailComposeView Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled: {
			UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Information" message:@"Mail Not Sent" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alertView show];
        }
			break;
		case MFMailComposeResultSaved: {
			UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Information" message:@"Mail Not Sent" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alertView show];
			break;
		}
		case MFMailComposeResultSent: {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Information" message:@"Mail was sent successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alertView show];
			break;
		}
		case MFMailComposeResultFailed: {
			UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Information" message:@"Mail sending failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alertView show];
			break;
		}
		default: {
			UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Information" message:@"Mail Not Sent" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alertView show];
			break;
		}
	}
    
    [controller dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(NSUInteger)supportedInterfaceOrientations {
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown);
}

@end
