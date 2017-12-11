#import <AVFoundation/AVFoundation.h>
#import "MediaViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "UIImage+ImageCrop.h"

enum {
    EmailButtonIndex,
};

@interface MediaViewController ()

@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, strong) NSString *type;

-(void)setImageOrientation:(UIImageOrientation)orientation;

@end

@implementation MediaViewController

@synthesize mediaURL;
@synthesize type;
@synthesize player;
@synthesize playerItem;

static const NSString *ItemStatusContext;

-(void)viewDidLoad {
    [super viewDidLoad];
    [self setWantsFullScreenLayout:YES];
    _playButton = [[UIButton alloc] initWithFrame:CGRectMake((_playerView.bounds.size.width / 2) - 40, (_playerView.bounds.size.height / 2) - 40, 79, 79)];
    [_playButton setImage:[UIImage imageNamed:@"video_indicator_icon.png"] forState:UIControlStateNormal];
    [_playerView addSubview:_playButton];
    [_playerView setBackgroundColor:[UIColor blackColor]];
    [_playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)setImage:(UIImage *)image {
    [self setMediaURL:nil];
    _image = image;
    UIImageOrientation orientation = [image imageOrientation];
    [self setImageOrientation:orientation];
    [_imageView setHidden:NO];
    [_playerView setHidden:YES];
}

-(void)setImageOrientation:(UIImageOrientation)orientation {
    switch (orientation) {
        case UIImageOrientationUp:
            break;
        case UIImageOrientationDown:
            _displayImage = [_image imageRotatedByDegrees:180.0f];
            break;
        case UIImageOrientationLeft:
            _displayImage = [_image imageRotatedByDegrees:90.0f];
            break;
        case UIImageOrientationRight:
            _displayImage = [_image imageRotatedByDegrees:-90.0f];
            break;
        default:
            break;
    }
    [_imageView setImage:_displayImage];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return orientation == UIInterfaceOrientationPortrait;
}

-(void)loadVideoAtURL:(NSURL *)url {
    _image = nil;
    [self setMediaURL:url];
    _didReachPlaybackEnd = NO;
    [_playButton setHidden:YES];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:tracksKey] completionHandler: ^{
         dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [playerItem addObserver:self forKeyPath:@"status"
                                options:0 context:&ItemStatusContext];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:playerItem];
                self.player = [AVPlayer playerWithPlayerItem:playerItem];
                [_playerView setPlayer:player];
            }
            else {
                // You should deal with the error appropriately.
                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
            }
        });
     }];
}

-(void)playerItemDidReachEnd:(id)sender {
    [_playButton setHidden:NO];
    _didReachPlaybackEnd = YES;
    _isPlaying = NO;
    [_playerView removeGestureRecognizer:tap];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_playButton setHidden:NO];
       });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

-(void)playButtonPressed:(id)sender {
    if (_isPlaying) {
        [player pause];
        [_playButton setHidden:NO];
    }
    else {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        
        [_playerView addGestureRecognizer:tap];
        
        if (_didReachPlaybackEnd) {
            CMTime time = CMTimeMake(0, 1);
            [player seekToTime:time];
        }
        [_playButton setHidden:YES];
        [[self player] play];
    }
    _isPlaying = !_isPlaying;
}

-(void)tap:(UIGestureRecognizer *)tap {
    [self playButtonPressed:self];
}

-(IBAction)shareButtonPressed:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Action sheet cancel button") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Email", @"Email option title"), nil];
    [sheet showInView:[self view]];
}

-(IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == EmailButtonIndex) {
        MFMailComposeViewController *viewController = [[MFMailComposeViewController alloc] init];
        [viewController setMailComposeDelegate:self];
        [viewController setSubject:NSLocalizedString(@"Capture from Zeta's Grip & Shoot", @"Email subject line")];
        NSData *messageData;
        NSString *mimeType;
        NSString *fileName;
        if (_image) {
            messageData = UIImageJPEGRepresentation(_image, 0.2);
            mimeType = @"image/jpeg";
            fileName = NSLocalizedString(@"Grip & Shoot.jpeg", @"File name for mail attachments - image");
        }
        else {
            messageData = [NSData dataWithContentsOfURL:[self mediaURL]];
            mimeType = @"video/x-m4v";
            fileName = NSLocalizedString(@"Grip & Shoot.m4v", @"File name for mail attachments - video");
        }
        [viewController addAttachmentData:messageData mimeType:mimeType fileName:fileName];
        [self presentViewController:viewController animated:YES completion:NULL];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
