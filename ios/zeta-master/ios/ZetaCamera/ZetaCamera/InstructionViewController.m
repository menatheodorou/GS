//
//  InstructionViewController.m
//  ZetaCamera
//
//  Created by Me on 8/25/14.
//
//

#import "InstructionViewController.h"

@interface InstructionViewController ()

@end

@implementation InstructionViewController

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
    NSURL *instructionURL = [NSURL URLWithString:@"http://vimeo.com/user18121529/videos"];
    [_webView loadRequest:[NSURLRequest requestWithURL:instructionURL]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
