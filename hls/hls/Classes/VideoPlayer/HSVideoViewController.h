/**
 * HSVideoViewController.h
 * 
 * Manages the playback of a movie from a network stream.
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PlaybackView.h"
#import "UpperControlBar.h"

enum {
    HSVideoFinishReasonPlaybackEnded,
    HSVideoFinishReasonPlaybackError
};
typedef NSInteger HSVideoFinishReason;

@interface HSVideoViewController : UIViewController {
    
@private
    
    AVPlayer *player;
    AVPlayerItem *playerItem;
    
    Float64 rateToRestoreAfterScrubbing;
    BOOL isFullscreen;
    BOOL isScrubbing;
    BOOL firstPlayback;
    
    IBOutlet PlaybackView *playbackView;
    IBOutlet UpperControlBar *upperControls;
    IBOutlet UIView *lowerControls;
    IBOutlet UILabel *timeElapsed;
    IBOutlet UILabel *timeRemaining;
    IBOutlet UISlider *timeControl;
    IBOutlet UISlider *volumeControl;
    IBOutlet UIButton *playButton;
    IBOutlet UIButton *fullscreenButton;
    IBOutlet UIActivityIndicatorView *loadingIndicator;
    
    UIDeviceOrientation deviceOrientation;
    
    id timeObserver;
    
@public
    
    NSURL *videoURL;
}

// Indicates if a movie should automatically start playback. Defaults to NO.
@property(nonatomic) BOOL shouldAutoplay;

// Determines how the content scales to fit the view. Defaults to AVLayerVideoGravityResizeAspect.
@property(nonatomic, copy) NSString *scalingMode;

// Returns a HSVideoViewController object initialized with the stream at the specified URL
- (id)initWithContentURL:(NSURL *)url;

// Begins video playback
- (void)play;

// Pauses video playback
- (void)pause;

@end

// Notifications

// Posted when video playback ends.
extern NSString *const HSVideoPlaybackDidFinishNotification;

extern NSString *const HSVideoPlaybackDidFinishReasonUserInfoKey;