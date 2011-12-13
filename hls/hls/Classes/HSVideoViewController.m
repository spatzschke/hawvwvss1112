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

#import "HSVideoViewController.h"

#define M_PI   3.14159265358979323846264338327950288   /* pi */

// Our conversion definition
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

// Key path
NSString *const kTracksKey          = @"tracks";
NSString *const kStatusKey          = @"status";
NSString *const kRateKey			= @"rate";
NSString *const kPlayableKey		= @"playable";
NSString *const kCurrentItemKey     = @"currentItem";

// Observer
static void *HSVideoRateObserverContext = &HSVideoRateObserverContext;
static void *HSVideoCurrentItemObserverContext = &HSVideoCurrentItemObserverContext;
static void *HSVideoPlayerItemStatusObserverContext = &HSVideoPlayerItemStatusObserverContext;
static void *HSVideoPLayerBufferEmptyObserverContext = &HSVideoPLayerBufferEmptyObserverContext;
static void *HSVideoPlayerLikelyToKeepUpObserverContext = &HSVideoPlayerLikelyToKeepUpObserverContext;

NSString *const HSVideoPlaybackDidFinishNotification = @"HSVideoPlaybackDidFinishNotification";
NSString *const HSVideoPlaybackDidFinishReasonUserInfoKey = @"HSVideoPlaybackDidFinishReasonUserInfoKey";


#pragma mark -
@interface HSVideoViewController (Player)
- (Float64)durationInSeconds;
- (Float64)currentTimeInSeconds;
- (Float64)timeRemainingInSeconds;
- (void)addTimeObserver;
- (void)removeTimeObserver;
- (BOOL)isPlaying;
- (void)loadAssetAsync;
- (void)assetFailedToPrepareForPlayback;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;

@end

@implementation HSVideoViewController

@synthesize videoURL;
@synthesize shouldAutoplay;
@synthesize scalingMode;

#pragma mark -
#pragma mark Init

- (id)initWithContentURL:(NSURL *)url 
{    
    self = [super initWithNibName:@"HSVideoPlayer" bundle:nil];
    if (self)
    {
        isFullscreen = NO;
        isScrubbing = NO;
        firstPlayback = YES;
        
        self.shouldAutoplay = NO;
        self.scalingMode = @"AVLayerVideoGravityResizeAspect";
        [self setVideoURL:url];
        
        //Add Observer for orientation change
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(deviceRotated:)
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
        
        
    }
    
    return self;
}

#pragma mark Dealloc

- (void)dealloc 
{    
    if (timeObserver) 
    {
        [player removeTimeObserver:timeObserver];
    }
    
    [[NSNotificationCenter defaultCenter] 
     removeObserver:self
     name:AVPlayerItemDidPlayToEndTimeNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    [player removeObserver:self forKeyPath:kCurrentItemKey];
    [playerItem removeObserver:self forKeyPath:kStatusKey];
    [player removeObserver:self forKeyPath:kRateKey];
    
    [timeObserver release];
    
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
    [loadingIndicator release];
    
    [super dealloc];
}

#pragma mark UIViewController

-(void) viewDidLoad 
{
    // Add lowerControls Rounded Corners and a white Border
    lowerControls.layer.borderColor = [[UIColor whiteColor] CGColor];
    lowerControls.layer.borderWidth = 2.3;
    lowerControls.layer.cornerRadius = 15;
    [lowerControls.layer setMasksToBounds:YES];
    
    // Add MPVolumeView
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider *volumeSlider = [[UISlider alloc] init];
    
    // Find the Slider in MPVolumeView
	for (UIView *view in [volumeView subviews]) {
		if ([[[view class] description] isEqualToString:@"MPVolumeSlider"]) 
        {
			volumeSlider = (UISlider *) [view retain];
            break;
		}
	}
    
    [volumeSlider setMinimumValueImage:[volumeControl minimumValueImage]];
    [volumeSlider setMaximumValueImage:[volumeControl maximumValueImage]];
    [volumeSlider setMinimumTrackTintColor:[volumeControl minimumTrackTintColor]];
    [volumeSlider setMaximumTrackTintColor:[volumeControl maximumTrackTintColor]];
    [volumeSlider setFrame:[volumeControl bounds]];
    [volumeSlider setCenter:[volumeControl center]];
    
    [volumeControl removeFromSuperview];
    [lowerControls addSubview:volumeSlider];
    
    [volumeControl release];
    volumeControl = [volumeSlider retain];
    [volumeSlider release];
    [volumeView release];
     
    // Start loading indicator
    [loadingIndicator startAnimating];
    
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

#pragma mark UI Updates

static NSString *timeStringForSeconds(Float64 seconds) 
{
    NSUInteger minutes = seconds / 60;
    NSUInteger secondsLeftOver = seconds - (minutes * 60);
    return [NSString stringWithFormat:@"%02ld:%02ld", minutes, secondsLeftOver];
}

- (void)updateTimeElapsed 
{
    timeElapsed.text = timeStringForSeconds([self currentTimeInSeconds]);
}

- (void)updateTimeRemaining 
{
    timeRemaining.text = [NSString stringWithFormat:@"-%@", timeStringForSeconds([self timeRemainingInSeconds])]; 
}


- (void)updatePlayPauseButton 
{    
    UIImage *buttonImage;
    
    if ([self isPlaying])
        buttonImage = [UIImage imageNamed:@"pause"];
	else
        buttonImage = [UIImage imageNamed:@"play"];
    
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
    else 
        timeControl.minimumValue = 0.0;
}

#pragma mark Orientation
/*////////////////////////////////////////////////////////////
/*
/* Orientationhandling for normal and fullscreen view
/*
////////////////////////////////////////////////////////////*/

//Handles the Rotation an the anchorpoint for the rotationanimation
- (CGAffineTransform)orientationTransformFromSourceBounds:(CGRect)sourceBounds
{
    
// Get orientation of the Device
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
// Where is the display, it is shown to the ground or the the sky
    if (orientation == UIDeviceOrientationFaceUp ||
		orientation == UIDeviceOrientationFaceDown)
	{
        //anytime get the oriantation of the statusBar
		orientation = [UIApplication sharedApplication].statusBarOrientation;
	}
	
// Orientation for Landscape Left	
	else if (orientation == UIDeviceOrientationLandscapeLeft)
	{
        //set the rotationangle
		CGAffineTransform result = CGAffineTransformMakeRotation(2 * M_PI);
        CGRect windowBounds = self.view.frame;
        //set the rotationanchor
        result = CGAffineTransformTranslate(result,
                                            0.5 * (windowBounds.size.height - sourceBounds.size.width),
                                            0.5 * (windowBounds.size.height - sourceBounds.size.width));
		
		return result;
	}
// Orientation for Landscape Right
	else if (orientation == UIDeviceOrientationLandscapeRight)
	{
        //set the rotationangle
        CGAffineTransform result = CGAffineTransformMakeRotation(2 * M_PI);
        CGRect windowBounds = self.view.window.bounds;
        //set the rotationanchor
        result = CGAffineTransformTranslate(result,
                                            0 * (windowBounds.size.height - sourceBounds.size.width),
                                            0 * (windowBounds.size.height - sourceBounds.size.width));
		
		return result;
	}
    
	return CGAffineTransformIdentity;
}

- (CGRect)rotatedWindowBounds
{
// Get orientation of the Device
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
// Orientation for Portrait
    if (orientation == UIDeviceOrientationPortrait)
	{
        NSLog(@"Portrait");
        CGAffineTransform transform = 
        CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0.0f));
        
        self.view.transform = transform;
	}
    
// Orientation for UpsideDown
	if (orientation == UIDeviceOrientationPortraitUpsideDown)
	{
        NSLog(@"Portrait UpsideDown");
        CGAffineTransform transform = 
        CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0.0f));
        self.view.transform = transform;
        //return CGRectMake(0, 0, 0, 0);
	}
	
// Orientation for Landscape Left
	if (orientation == UIDeviceOrientationLandscapeLeft)
	{
        NSLog(@"LandscapeLeft");
        CGAffineTransform transform = 
        CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90.0f));
        
        self.view.transform = transform;
	}
    
// Orientation for Landscape Right
	if (orientation == UIDeviceOrientationLandscapeRight)
	{
        
        NSLog(@"LandscapeRight");
        CGAffineTransform transform = 
        CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90.0f));
        self.view.transform = transform;
    }

// Dont change the size of the Player. Only rotate them.
    return self.view.bounds;
	
    
}

// Method Called by Orientation Notification
- (void)deviceRotated:(NSNotification *)aNotification
{
	if (self.view)
	{
        // if a Notfication fired for rotation
		if (aNotification)
		{			
            //rotat with animation
			[UIView animateWithDuration:0.25 animations:^{
				self.view.bounds = [self rotatedWindowBounds];
				self.view.transform = [self orientationTransformFromSourceBounds:self.view.bounds];
			} completion:^(BOOL complete){
				
			}];
		}
		else
		{
            //rotat without animation / same functionality like with animation
			self.view.bounds = [self rotatedWindowBounds];
			self.view.transform = [self orientationTransformFromSourceBounds:self.view.bounds];
		}
	}
	else
	{
		self.view.transform = CGAffineTransformIdentity;
	}
    
    
}

#pragma mark -
#pragma mark Actions

- (IBAction)togglePlaying:(id)sender 
{
	if ([self isPlaying])
		[self pause];
	else
		[self play];
}

- (IBAction)toggleFullscreen:(id)sender
{
    [self setFullscreen:!isFullscreen];
}

- (IBAction)beginScrubbing:(id)sender
{
	rateToRestoreAfterScrubbing = [player rate];
	[player setRate:0.f];
    isScrubbing = YES;
    
	/* Remove previous timer. */
	[self removeTimeObserver];
}

- (IBAction)endScrubbing:(id)sender
{    
	if (rateToRestoreAfterScrubbing)
	{
		[player setRate:rateToRestoreAfterScrubbing];
		rateToRestoreAfterScrubbing = 0.f;
	}
    
    isScrubbing = NO;
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrubValueChanged:(id)sender
{
	if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		Float64 duration = [self durationInSeconds];
        
        if (duration < 0.01) 
        {
            return;
        }
		
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			Float64 elapsed = duration * (value - minValue) / (maxValue - minValue);
            Float64 remaining = duration - elapsed;
			
			[player seekToTime:CMTimeMakeWithSeconds(elapsed, NSEC_PER_SEC) 
               toleranceBefore:kCMTimeZero 
                toleranceAfter:kCMTimePositiveInfinity];

            timeElapsed.text = timeStringForSeconds(elapsed);
            timeRemaining.text = [NSString stringWithFormat:@"-%@", timeStringForSeconds(remaining)];   
		}
	}
}

- (IBAction)updateFullscreenButton
{
    UIImage *buttonImage;
    
    if (isFullscreen)
        buttonImage = [UIImage imageNamed:@"fullscreen-exit"];
    else
        buttonImage = [UIImage imageNamed:@"fullscreen-exit"];
    
    [fullscreenButton setImage:buttonImage forState:UIControlStateNormal];
}

- (void)play
{    
	[player play];
    [self updatePlayPauseButton];
}

- (void)pause
{
	[player pause];
    [self updatePlayPauseButton];
}

-(void)setFullscreen:(BOOL)fullscreen
{    
    if (fullscreen) 
    {
        CGRect frame = [playbackView.window
                        convertRect:playbackView.frame
                        fromView:self.view];
		[playbackView.window addSubview:playbackView];
		playbackView.frame = frame;
        
        [UIView
         animateWithDuration:0.4 
         animations:^{
             playbackView.frame = playbackView.window.bounds;
         }];
    }
    else 
    {
        CGRect frame = [self.view
                        convertRect:playbackView.frame
                        fromView:playbackView.window];
		playbackView.frame = frame;
        [self.view addSubview:playbackView];
        
        [UIView
         animateWithDuration:0.4 
         animations:^{
             playbackView.frame = self.view.frame;
         }];
    }
    
    [[UIApplication sharedApplication] 
        setStatusBarHidden:fullscreen
        withAnimation:UIStatusBarAnimationFade];
    
    isFullscreen = fullscreen;
    [self updateFullscreenButton];
}

-(void)setVideoURL:(NSURL *)url 
{
    if (videoURL) 
    {
        [videoURL release];
        videoURL = nil;
    }
    
    videoURL = [url copy];
    [self loadAssetAsync];
}

@end

#pragma mark -
#pragma mark Player

@implementation HSVideoViewController (Player)

static Float64 secondsWithCMTimeOrZeroIfInvalid(CMTime time) 
{
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

-(void)addTimeObserver
{
    if (!timeObserver) 
    {
        timeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0, NSEC_PER_SEC) 
                                                             queue:NULL 
                                                        usingBlock:
                         ^(CMTime time) 
                         {
                             [self updateTimeScrubber];
                             [self updateTimeElapsed];
                             [self updateTimeRemaining];
                         }] retain];
    }
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


- (BOOL)isPlaying
{
	return (rateToRestoreAfterScrubbing != 0.f || [player rate] != 0.f);
}

- (void) loadAssetAsync 
{
    /*
     Create an asset for inspection of a resource referenced by a given URL.
     Load the values for the asset keys "tracks", "playable".
     */
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.videoURL options:nil];
    
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
    [player seekToTime:kCMTimeZero];
    [player setRate:0.f];
}

-(void)assetFailedToPrepareForPlayback
{    
    [self removeTimeObserver];
    [self updateTimeScrubber];
    
    [timeControl setEnabled:NO];
    [playButton setEnabled:NO];
    
    [loadingIndicator stopAnimating];
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
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Verbindungsfehler"
                                                                message:@"Es konnte keine Verbindung zum Server hergestellt werden."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            
            [self assetFailedToPrepareForPlayback];
			return;
		}
	}
    
    if (!asset.playable)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                            message:@"Die Datei kann nicht abgespielt werden."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    
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
    
    [playerItem addObserver:self 
                 forKeyPath:@"playbackBufferEmpty" 
                    options:NSKeyValueObservingOptionNew 
                    context:HSVideoPLayerBufferEmptyObserverContext];
    
    [playerItem addObserver:self 
                 forKeyPath:@"playbackLikelyToKeepUp" 
                    options:NSKeyValueObservingOptionNew 
                    context:HSVideoPlayerLikelyToKeepUpObserverContext];

	
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
        
        /* Do nothing if the item has finished playing */
        [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
		
        /* Observe the AVPlayer "currentItem" property to find out when any 
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did 
         occur.*/
        [player addObserver:self 
                 forKeyPath:kCurrentItemKey 
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:HSVideoCurrentItemObserverContext];
        
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
        [self updatePlayPauseButton];
    }
    
    [timeControl setValue:0.0];
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
            case AVPlayerStatusUnknown:
            {
                [self removeTimeObserver];
                [self updateTimeScrubber];
                
                [timeControl setEnabled:NO];
                [playButton setEnabled:NO];
                [fullscreenButton setEnabled:NO];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                if (firstPlayback) 
                {
                    [timeControl setEnabled:YES];
                    [playButton setEnabled:YES];
                    [fullscreenButton setEnabled:YES];
                    [upperControls setHidden:NO];
                    [lowerControls setHidden:NO];
                    [loadingIndicator stopAnimating];
                    
                    [playbackView setNeedsDisplay];
                
                    if (self.shouldAutoplay) 
                    {
                        [player play];
                    }
                    
                    firstPlayback = NO;
                }
                
                if (!isScrubbing) 
                {
                    [self addTimeObserver];
                }
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                                    message:@"Die Datei kann nicht mehr abgespielt werden."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                [alertView release];
                
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
    /* AVPlayer "currentItem" buffer is empty observer */
    else if (context == HSVideoPLayerBufferEmptyObserverContext) 
    {
        if (!isScrubbing)
            [loadingIndicator startAnimating];
    }
    /* AVPlayer "currentItem" is likely to keep up observer */
    else if (context == HSVideoPlayerLikelyToKeepUpObserverContext)
    {
        if (!isScrubbing) {
            [loadingIndicator stopAnimating];
        }
    }
	/* AVPlayer "currentItem" property observer. 
     Called when the AVPlayer replaceCurrentItemWithPlayerItem: 
     replacement will/did occur. */
	else if (context == HSVideoCurrentItemObserverContext)
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
            [playbackView setPlayer:player];
            [playbackView setVideoFillMode:[self scalingMode]];
            
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