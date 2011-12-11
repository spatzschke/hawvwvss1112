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
    
    float rateToRestoreAfterScrubbing;
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
    
    id timeObserver;
    NSTimer *hideControlsTimer;
    
@public
    
    NSURL *videoURL;
}

@property(nonatomic, copy) NSURL *videoURL;

// Indicates if a movie should automatically start playback when it is 
// likely to finish uninterrupted based on e.g. network conditions. Defaults to NO.
@property(nonatomic) BOOL shouldAutoplay;

// Determines how the content scales to fit the view. Defaults to AVLayerVideoGravityResizeAspect.
@property(nonatomic, copy) NSString *scalingMode;

- (id)initWithContentURL:(NSURL *)url;
- (void)setFullscreen:(BOOL)fullscreen;
- (void)play;
- (void)pause;

@end

// Notifications

// Posted when video playback ends.
extern NSString *const HSVideoPlaybackDidFinishNotification;

extern NSString *const HSVideoPlaybackDidFinishReasonUserInfoKey;