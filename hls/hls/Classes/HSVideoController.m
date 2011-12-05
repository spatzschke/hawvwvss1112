//
//  HSVideoController.m
//  HLVideo
//
//  Created by Sebastian Schuler on 04.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HSVideoController.h"

NSString *const kTracksKey          = @"tracks";
NSString *const kStatusKey          = @"status";
NSString *const kRateKey			= @"rate";
NSString *const kPlayableKey		= @"playable";
NSString *const kCurrentItemKey     = @"currentItem";

static void *HSVideoTimedMetadataObserverContext = &HSVideoTimedMetadataObserverContext;
static void *HSVideoRateObserverContext = &HSVideoRateObserverContext;
static void *HSVideoCurrentItemObservationContext = &HSVideoCurrentItemObservationContext;
static void *HSVideoPlayerItemStatusObserverContext = &HSVideoPlayerItemStatusObserverContext;

NSString *const HSVideoPlaybackDidFinishNotification = @"HSVideoPlaybackDidFinishNotification";
NSString *const HSVideoPlaybackDidFinishReasonUserInfoKey = @"HSVideoPlaybackDidFinishReasonUserInfoKey";


#pragma mark -
@interface HSVideoController (Player)
- (Float64)durationInSeconds;
- (Float64)currentTimeInSeconds;
- (Float64)timeRemainingInSeconds;
- (void)assetFailedToPrepareForPlayback;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
- (void)loadAssetAsync;
- (BOOL)isPlaying;
@end

@implementation HSVideoController

@synthesize videoURL;
@synthesize shouldAutoplay;
@synthesize scalingMode;

#pragma mark -
#pragma mark Init

- (id)initWithContentURL:(NSURL *)url {
    
    self = [super init];
    if (self)
    {
        self.videoURL = [url retain];
        self.shouldAutoplay = YES;
    }
    
    return self;
}

#pragma mark Dealloc

- (void)dealloc {
    
    [timeObserver release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    
    [player removeObserver:self forKeyPath:kCurrentItemKey];
    //[playerItem removeObserver:self forKeyPath:kStatusKey];
    [player removeObserver:self forKeyPath:kRateKey];
    
    [player release];
    [playerItem release];
    
    [self.videoURL release];
    [self.scalingMode release];
    
    [playbackView release];
    [upperControls release];
    [lowerControls release];
    [timeElapsed release];
    [timeRemaining release];
    [timeControl release];
    [volumeControl release];
    [playButton release];
    
    [super dealloc];
}

#pragma mark UIViewController

-(void) viewDidLoad {
    
    [timeControl setValue:0.0];
    
    [self loadAssetAsync];
    
    [super viewDidLoad];
    
}

/*- (void) setVideoURL:(NSURL *)url {
    [self setVideoURL:url];
    [self loadAssetAsync];
}*/


static NSString *timeStringForSeconds(Float64 seconds) {
    NSUInteger minutes = seconds / 60;
    NSUInteger secondsLeftOver = seconds - (minutes * 60);
    return [NSString stringWithFormat:@"%02ld:%02ld", minutes, secondsLeftOver];
}

- (void)updateTimeElapsed {
    timeElapsed.text = timeStringForSeconds([self currentTimeInSeconds]);
}

- (void)updateTimeRemaining {
    timeRemaining.text = [NSString stringWithFormat:@"-%@", timeStringForSeconds([self timeRemainingInSeconds])]; 
}


- (void)updatePlayPauseButton {
    
    UIImage *buttonImage = nil;
    
    if ([self isPlaying])
	{
        buttonImage = [UIImage imageNamed:@"pause"];
	}
	else
	{
        buttonImage = [UIImage imageNamed:@"play"];     
	}
    
    [playButton setImage:buttonImage forState:UIControlStateNormal];
}

- (void)updateTimeScrubber
{    
    Float64 duration = [self durationInSeconds];
    	
	if (isfinite(duration) && (duration > 0))
	{
		float minValue = [timeControl minimumValue];
		float maxValue = [timeControl maximumValue];
		Float64 currentTime = [self currentTimeInSeconds];
        
		[timeControl setValue:(maxValue - minValue) * currentTime / duration + minValue];
	}
    else {
        timeControl.minimumValue = 0.0;
    }
}

-(void)initTimeScrubber
{
	double interval = .1f;
	Float64 duration = [self durationInSeconds];
    
    if (duration < 0.01) {
        return;
    }
    
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([timeControl bounds]);
		interval = 0.5f * duration / width;
    }
    
	/* Update the scrubber during normal playback. */
	timeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
                                                         queue:NULL 
                                                    usingBlock:
                     ^(CMTime time) 
                     {
                         [self updateTimeScrubber];
                         [self updateTimeElapsed]; // ??
                         [self updateTimeRemaining]; // ??
                     }] retain];
}

/* Cancels the previously registered time observer. */
-(void)removeTimeObserver
{
	if (timeObserver)
	{
		[player removeTimeObserver:timeObserver];
		[timeObserver release];
		timeObserver = nil;
	}
}

@end

#pragma mark -
#pragma mark Player

@implementation HSVideoController (Player)

static Float64 secondsWithCMTimeOrZeroIfInvalid(CMTime time) {
    return CMTIME_IS_INVALID(time) ? 0.0f : CMTimeGetSeconds(time);
}

- (Float64)durationInSeconds 
{    
	return secondsWithCMTimeOrZeroIfInvalid([playerItem duration]);
}

- (Float64)currentTimeInSeconds
{
    return secondsWithCMTimeOrZeroIfInvalid([player currentTime]);
}

- (Float64)timeRemainingInSeconds {
    return [self durationInSeconds] - [self currentTimeInSeconds];
}

- (BOOL)isPlaying
{
	return ([player rate] != 0.f);
}

- (void) loadAssetAsync {
    /*
     Create an asset for inspection of a resource referenced by a given URL.
     Load the values for the asset keys "tracks", "playable".
     */
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{		 
         dispatch_async( dispatch_get_main_queue(), 
                        ^{
                            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification 
{
    [self updatePlayPauseButton];
    [player seekToTime:kCMTimeZero];
}

-(void)assetFailedToPrepareForPlayback
{    
    [self removeTimeObserver];
    [self updateTimeScrubber];
    
    [timeControl setEnabled:NO];
    [playButton setEnabled:NO];
    
    NSNumber *stopCode = [NSNumber numberWithInt: HSVideoFinishReasonPlaybackError];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject: stopCode
                                                         forKey: HSVideoPlaybackDidFinishReasonUserInfoKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HSVideoPlaybackDidFinishNotification 
                                                        object:self userInfo:userInfo];
}


/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{  
            [self assetFailedToPrepareForPlayback];
			return;
		}
	}
    
    if (!asset.playable)
    {
        [self assetFailedToPrepareForPlayback];       
        return;
    }
	
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [playerItem removeObserver:self forKeyPath:kStatusKey];            
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:playerItem];
    }
	
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [playerItem addObserver:self 
                 forKeyPath:kStatusKey 
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:HSVideoPlayerItemStatusObserverContext];
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
	
    /* Create new player, if we don't already have one. */
    if (!player)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
		
        /* Observe the AVPlayer "currentItem" property to find out when any 
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did 
         occur.*/
        [player addObserver:self 
                 forKeyPath:kCurrentItemKey 
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:HSVideoCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [player addObserver:self
                 forKeyPath:kRateKey 
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:HSVideoRateObserverContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (player.currentItem != playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs 
         asynchronously; observe the currentItem property to find out when the 
         replacement will/did occur*/
        [player replaceCurrentItemWithPlayerItem:playerItem];
    }
}

- (void)observeValueForKeyPath:(NSString*) keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary*)change 
                       context:(void*)context
{
	/* AVPlayerItem "status" property value observer. */
    if (context == HSVideoPlayerItemStatusObserverContext)
	{        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because 
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removeTimeObserver];
                [self updateTimeScrubber];
                
                [timeControl setEnabled:NO];
                [playButton setEnabled:NO];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                [timeControl setEnabled:YES];
                
                [upperControls setHidden:NO];
                [lowerControls setHidden:NO];
                
                [playbackView setPlayer:player];
                
                [self initTimeScrubber];
                
                if (self.shouldAutoplay) {
                   [player play];
                } 
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                [self assetFailedToPrepareForPlayback];
            }
                break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == HSVideoRateObserverContext)
	{
        [self updatePlayPauseButton];
	}
	/* AVPlayer "currentItem" property observer. 
     Called when the AVPlayer replaceCurrentItemWithPlayerItem: 
     replacement will/did occur. */
	else if (context == HSVideoCurrentItemObservationContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* New player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {            
            [playButton setEnabled:NO];
            [timeControl setEnabled:NO];
            
        }
        else /* Replacement of player currentItem has occurred */
        {
            [player replaceCurrentItemWithPlayerItem:playerItem];
            [self updatePlayPauseButton];
        }
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
    
    return;
}

@end