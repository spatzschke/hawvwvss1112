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
NSString *const kTimedMetadataKey	= @"currentItem.timedMetadata";

static void *HSVideoTimedMetadataObserverContext = &HSVideoTimedMetadataObserverContext;
static void *HSVideoRateObserverContext = &HSVideoRateObserverContext;
static void *HSVideoCurrentItemObservationContext = &HSVideoCurrentItemObservationContext;
static void *HSVideoPlayerItemStatusObserverContext = &HSVideoPlayerItemStatusObserverContext;

NSString *const HSVideoPlaybackDidFinishNotification = @"HSVideoPlaybackDidFinishNotification";
NSString *const HSVideoPlaybackDidFinishReasonUserInfoKey = @"HSVideoPlaybackDidFinishReasonUserInfoKey";


#pragma mark -
@interface HSVideoController (Player)
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
- (void)loadAssetAsync;
- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
@end

@implementation HSVideoController

@synthesize videoURL;
@synthesize shouldAutoplay;
@synthesize scalingMode;

- (id)initWithContentURL:(NSURL *)url {
    
    self = [super init];
    if (self)
    {
        //self.videoURL = [url retain];
        //[self loadAssetAsync];
    }
    
    return self;
}

- (void)dealloc {
    
    [self.videoURL release];
    [self.scalingMode release];
    
    [timeElapsed release];
    [timeRemaining release];
    [timeControl release];
    
    [playerItem release];
    [player release];
    [playbackView release];
    
    [super dealloc];
}

- (void) setVideoURL:(NSURL *)url {
    [self setVideoURL:url];
    [self loadAssetAsync];
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
	if ([self isPlaying])
	{
        //[self showStopButton];
	}
	else
	{
        //[self showPlayButton];        
	}
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		timeControl.minimumValue = 0.0;
		return;
	} 
	
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration) && (duration > 0))
	{
		float minValue = [timeControl minimumValue];
		float maxValue = [timeControl maximumValue];
		double time = CMTimeGetSeconds([player currentTime]);
		[timeControl setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

-(void)initScrubberTimer
{
	double interval = .1f;	
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		return;
	} 
    
	double duration = CMTimeGetSeconds(playerDuration);
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
                         [self syncScrubber];
                     }] retain];
}

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
	if (timeObserver)
	{
		[player removeTimeObserver:timeObserver];
		[timeObserver release];
		timeObserver = nil;
	}
}

@end

@implementation HSVideoController (Player)

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
    //[self showPlayButton];
    [player seekToTime:kCMTimeZero];
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
            NSNumber *stopCode = [NSNumber numberWithInt: HSVideoFinishReasonPlaybackError];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject: stopCode
                                                                 forKey: HSVideoPlaybackDidFinishReasonUserInfoKey];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:HSVideoPlaybackDidFinishNotification 
                                                                object:self userInfo:userInfo];
            
			return;
		}
	}
    
    if (!asset.playable)
    {
        NSNumber *stopCode = [NSNumber numberWithInt: HSVideoFinishReasonPlaybackError];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject: stopCode
                                                             forKey: HSVideoPlaybackDidFinishReasonUserInfoKey];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HSVideoPlaybackDidFinishNotification 
                                                            object:self userInfo:userInfo];        
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
        player = [AVPlayer playerWithPlayerItem:playerItem];
		
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
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [timeControl setEnabled:NO];
                //[IblPlay setEnabled:NO];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                [timeControl setEnabled:YES];
                //[IblPlay setEnabled:YES];
                
                [upperControls setHidden:NO];
                [lowerControls setHidden:NO];
                
                
                [playbackView setPlayer:player];
                
                [self initScrubberTimer];
                
                if (self.shouldAutoplay) {
                    [player play];
                } 
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                NSNumber *stopCode = [NSNumber numberWithInt: HSVideoFinishReasonPlaybackError];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject: stopCode
                                                                     forKey: HSVideoPlaybackDidFinishReasonUserInfoKey];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:HSVideoPlaybackDidFinishNotification 
                                                                    object:self userInfo:userInfo];
            }
                break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == HSVideoRateObserverContext)
	{
        [self syncPlayPauseButtons];
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
            //[IblPlay setEnabled:NO];
            [timeControl setEnabled:NO];
            
        }
        else /* Replacement of player currentItem has occurred */
        {
            [player replaceCurrentItemWithPlayerItem:playerItem];
            [self syncPlayPauseButtons];
        }
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
    
    return;
}

/**
 * Get the AVPlayerItem duration
 */
- (CMTime)playerItemDuration
{
	AVPlayerItem *thePlayerItem = [player currentItem];
	if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
	{
		return([playerItem duration]);
	}
    
	return(kCMTimeInvalid);
}

@end