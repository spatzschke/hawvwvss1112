//
//  StreamingVideoController.h
//  hls
//
//  Created by Sebastian Schuler on 25.11.11.
//  Copyright (c) 2011 commercetools.de. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

enum {
    HSVideoFinishReasonPlaybackEnded,
    HSVideoFinishReasonPlaybackError
};
typedef NSInteger HSVideoFinishReason;

@interface HSVideoController : NSObject {

    @private
    
    AVPlayer *player;
    AVPlayerItem *playerItem;
    AVPlayerLayer *playerLayer;
    
    IBOutlet UILabel *IblTimeElapsed;
    IBOutlet UILabel *IblTimeRemaining;
    IBOutlet UIBarButtonItem *IblPlay;
    IBOutlet UISlider *IblTimeControl;
    IBOutlet UIToolbar *IblUpperControls;
    IBOutlet UIToolbar *IblLowerControls;
    
    id timeObserver;
    
    @public
    
    UIView *view;
    
    NSURL *videoURL;
}

@property(nonatomic, copy) NSURL *videoURL;

// The view in which the media and playback controls are displayed.
@property(nonatomic, readonly) UIView *view;

// Indicates if a movie should automatically start playback when it is 
// likely to finish uninterrupted based on e.g. network conditions. Defaults to NO.
@property(nonatomic) BOOL shouldAutoplay;

// Determines how the content scales to fit the view. Defaults to MPMovieScalingModeAspectFit.
@property(nonatomic, copy) NSString *scalingMode;

- (id)initWithContentURL:(NSURL *)url;
//- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

@end

// Notifications

// Posted when video playback ends.
extern NSString *const HSVideoPlaybackDidFinishNotification;

extern NSString *const HSVideoPlaybackDidFinishReasonUserInfoKey;





