#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "PlayerView.h"

@interface MediaViewController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    @private
    IBOutlet UIImageView *_imageView;
    IBOutlet PlayerView *_playerView;
    UIButton *_playButton;
    BOOL _didReachPlaybackEnd;
    BOOL _isPlaying;
    
    UIGestureRecognizer *tap;
    
    UIImage *_image;
    UIImage *_displayImage;
}

@property (nonatomic, strong, readonly) NSURL *mediaURL;
@property (nonatomic, strong, readonly) NSString *type;

@property (nonatomic, retain) AVPlayer *player;
@property (retain) AVPlayerItem *playerItem;

-(void)setImage:(UIImage *)image;
-(void)loadVideoAtURL:(NSURL *)url;

-(IBAction)shareButtonPressed:(id)sender;

-(IBAction)doneButtonPressed:(id)sender;

@end
