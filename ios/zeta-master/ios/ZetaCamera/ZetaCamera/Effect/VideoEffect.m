//
//  VideoEffect.m
//  ZetaCamera
//
//  Created by Me on 8/8/14.
//
//

#import "VideoEffect.h"
#import "Constant.h"

@implementation VideoEffect

+ (VideoEffect *)sharedInstance
{
    static VideoEffect *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[VideoEffect alloc] init];
    });
    return singleton;
}

- (id)init {
    if (self = [super init]) {
        self.pendingList = [NSMutableArray array];
    }
    
    return self;
}

- (NSURL *)filterVideoURL {
    NSString *filename = [NSString stringWithFormat:@"%.4f.mov", [[NSDate date] timeIntervalSince1970]];
    NSString *path = [CAPTURE_DIRECTORY stringByAppendingPathComponent:filename];
    return [[NSURL alloc] initFileURLWithPath:path];
}

- (void)filterVideo:(NSURL *)videoURL filter:(VideoFilterType)filterType completionHandler:(FilterCompletion)completionHandler {

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *track = [tracks objectAtIndex:0];
    CGSize mediaSize = track.naturalSize;

    NSLog(@"%@", NSStringFromCGSize(mediaSize));
    
    GPUImageMovie *movieFile = [[GPUImageMovie alloc] initWithURL:videoURL];
    movieFile.runBenchmark = NO;
    movieFile.playAtActualSpeed = NO;
    
    GPUImageOutput<GPUImageInput> *filter;
    
    if (filterType == kVideoFilterMono) {
        filter = [[GPUImageSaturationFilter alloc] init];
        [(GPUImageSaturationFilter *)filter setSaturation:0];
    } else if (filterType == kVideoFilterFalse) {
        filter = [[GPUImageFalseColorFilter alloc] init];
    } else if (filterType == kVideoFilterChroma) {
        completionHandler(videoURL);
        return;
    } else if (filterType == kVideoFilterFrameLine) {
        
        GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
        [transformFilter setBackgroundColorRed:1 green:1 blue:1 alpha:0]; // For example
        
        // Calculate scale for exact crop size
        // For 16x9 scale = 16 * videoSize.height / (9 * videoSize.width);
        CGFloat scale = 0.9;
        transformFilter.affineTransform = CGAffineTransformMakeScale(scale, scale);
        
        filter = transformFilter;

        CGRect cropRegion;
        if (mediaSize.width > mediaSize.height) {
            cropRegion = CGRectMake((1 - scale) / 4, 0, scale + (1 - scale) / 2, 1);
        } else {
            cropRegion = CGRectMake(0, (1 - scale) / 2, 1, scale);
        }
        
        GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] init];
        cropFilter.cropRegion = cropRegion;
        
        filter = [[GPUImageFilterGroup alloc] init];
        [(GPUImageFilterGroup *)filter addFilter:transformFilter];
        [(GPUImageFilterGroup *)filter addFilter:cropFilter];
        
        [transformFilter addTarget:cropFilter];
        [(GPUImageFilterGroup *)filter setInitialFilters:[NSArray arrayWithObject:transformFilter]];
        [(GPUImageFilterGroup *)filter setTerminalFilter:cropFilter];
        
        mediaSize = CGSizeMake(cropRegion.size.width * mediaSize.width, cropRegion.size.height * mediaSize.height);
    }
    
    [movieFile addTarget:filter];
    
    NSURL *movieURL = [self filterVideoURL];
    [[NSFileManager defaultManager] removeItemAtURL:movieURL error:nil];
    
    GPUImageMovieWriter *movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:mediaSize];
    [filter addTarget:movieWriter];
    
    // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecordingInOrientation:track.preferredTransform];
    [movieFile startProcessing];
    
    NSDictionary *pendingInfo = @{@"movie" : movieFile, @"filter": filter, @"writer": movieWriter};
    [self.pendingList addObject:pendingInfo];
    
    __weak VideoEffect *weakself = self;
    
    [movieWriter setCompletionBlock:^{
        GPUImageMovieWriter *movieWriter = [pendingInfo objectForKey:@"write"];
        GPUImageSaturationFilter *filter = [pendingInfo objectForKey:@"filter"];
        [filter removeTarget:movieWriter];
        [movieWriter finishRecording];
        
        [weakself.pendingList removeObject:pendingInfo];
        [[NSFileManager defaultManager] removeItemAtURL:videoURL error:nil];
        
        completionHandler(movieURL);
    }];
}

@end
