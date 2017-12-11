//
//  InfoViewController.m
//  ZetaCamera
//
//  Created by Dexter Weiss on 2/19/13.
//
//

#import "InfoViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface InfoViewController () <UITableViewDataSource, UITableViewDelegate> {
    @private
    IBOutlet UIToolbar *_toolbar;
    IBOutlet UITableView *_tableView;
}

@end

@implementation InfoViewController

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)shouldAutorotate {
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerLoadStateDidChangeNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        MPMovieLoadState state = [(MPMoviePlayerController *)[note object] loadState];
        NSLog(@"Unknown: %d", state & MPMovieLoadStateUnknown);
        NSLog(@"Playable: %d", state & MPMovieLoadStatePlayable);
        NSLog(@"Playthrough OK: %d", state & MPMovieLoadStatePlaythroughOK);
        NSLog(@"Stalled: %d", state & MPMovieLoadStateStalled);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerPlaybackStateDidChangeNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        MPMoviePlaybackState state = [(MPMoviePlayerController *)[note object] playbackState];
        if (state == MPMoviePlaybackStateInterrupted) {
            NSLog(@"Interrupted");
        }
        else if (state == MPMoviePlaybackStatePaused) {
            NSLog(@"Paused");
        }
        else if (state == MPMoviePlaybackStatePlaying) {
            NSLog(@"Playing");
        }
        else if (state == MPMoviePlaybackStateStopped) {
            NSLog(@"Stopped");
        }
        else if (state == MPMoviePlaybackStateSeekingBackward) {
            NSLog(@"Seeking backward");
        }
        else if (state == MPMoviePlaybackStateSeekingForward) {
            NSLog(@"Seeking forward");
        }
    }];
    
    UIImage *image = [UIImage imageNamed:@"toolbar"];
    [_toolbar setBackgroundImage:image forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"subtle_dots.png"]]];
    
    [_tableView setBackgroundView:nil];
    [_tableView setBackgroundColor:[UIColor clearColor]];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(IBAction)webButtonPressed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://gripandshoot.com"]];
}

#pragma mark - Table Methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * reuseIdentifier = @"VideoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    NSString *text = nil;
    switch ([indexPath row]) {
        case 0:
            text = NSLocalizedString(@"How do I pair with my phone?", @"How to use G&S question");
            break;
        case 1:
            text = NSLocalizedString(@"How do I change the battery?", @"Battery change G&S question");
            break;
        case 2:
            text = NSLocalizedString(@"What is the Grip & Shoot?", @"What is G&S question");
            break;
    }
    [[cell textLabel] setText:text];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *videoName = nil;
    switch ([indexPath row]) {
        case 0:
            videoName = @"pairing";
            break;
        case 1:
            videoName = @"battery";
            break;
        case 2:
            videoName = @"master-movie";
            break;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:videoName ofType:@"m4v"];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSLog(@"%@", url);
    
    MPMoviePlayerViewController *viewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    [self presentMoviePlayerViewControllerAnimated:viewController];
    [[viewController moviePlayer] prepareToPlay];
    [[viewController moviePlayer] setShouldAutoplay:YES];
    [[viewController moviePlayer] setUseApplicationAudioSession:NO];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
