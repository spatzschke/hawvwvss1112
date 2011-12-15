/**
 * HSVideoViewController.m
 * 
 * Manages the playback of a movie from a network stream.
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import "HSVideoViewController.h"

// Key path
NSString *const kTracksKey          = @"tracks";
NSString *const kStatusKey          = @"status";
NSString *const kRateKey			= @"rate";
NSString *const kPlayableKey		= @"playable";
NSString *const kCurrentItemKey     = @"currentItem";
NSString *const kBufferEmpty        = @"playbackBufferEmpty";
NSString *const kLikelyToKeepUp     = @"playbackLikelyToKeepUp";

// Observer
static void *HSVideoRateObserverContext = &HSVideoRateObserverContext;
static void *HSVideoCurrentItemObserverContext = &HSVideoCurrentItemObserverContext;
static void *HSVideoPlayerItemStatusObserverContext = &HSVideoPlayerItemStatusObserverContext;
static void *HSVideoPLayerBufferEmptyObserverContext = &HSVideoPLayerBufferEmptyObserverContext;
static void *HSVideoPlayerLikelyToKeepUpObserverContext = &HSVideoPlayerLikelyToKeepUpObserverContext;

// Notification
NSString *const HSVideoPlaybackDidFinishNotification = @"HSVideoPlaybackDidFinishNotification";
NSString *const HSVideoPlaybackDidFinishReasonUserInfoKey = @"HSVideoPlaybackDidFinishReasonUserInfoKey";

#pragma mark -
@interface HSVideoViewController (Player)

// Convert TMTime to seconds
- (Float64)secondsWithCMTimeOrZeroIfInvalid:(CMTime) time;

// Returns the duration in seconds for the current playback
- (Float64)durationInSeconds;

// Returns the current time in seconds for the current playback
- (Float64)currentTimeInSeconds;

// Returns remaining time in seconds for the current playback
- (Float64)timeRemainingInSeconds;

// Register time observer for update controls
- (void)addTimeObserver;

// Remove the previously registered time observer
- (void)removeTimeObserver;

// Checks whether the movie player is playing
- (BOOL)isPlaying;

// Load the player asset asynchronously
- (void)loadAssetAsync;

// Called when an player asset fails to prepare for playback
- (void)assetFailedToPrepareForPlayback:(NSError *)error;

// Prepares the player for playback, asynchronously
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;

// Causes the movie player to enter or exit full-screen mode
- (void)setFullscreen:(BOOL)fullscreen;

@end

@implementation HSVideoViewController

@synthesize shouldAutoplay;
@synthesize scalingMode;

#pragma mark -
#pragma mark init / dealloc

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
        
        videoURL = [url copy];
        
        [self loadAssetAsync];

    }
    
    return self;
}

- (void)dealloc 
{    
    [self removeTimeObserver];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                            name:AVPlayerItemDidPlayToEndTimeNotification
                            object:nil];
    
    [player removeObserver:self forKeyPath:kCurrentItemKey];
    [player removeObserver:self forKeyPath:kRateKey];
    
    [player pause];
    [player release];
    
    [videoURL release];
    [scalingMode release];
    
    [playbackView release];
    [upperControls release];
    [lowerControls release];
    [timeElapsed release];
    [timeRemaining release];
    [timeControl release];
    [volumeControl release];
    [playButton release];
    [fullscreenButton release];
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
    UISlider *volumeSlider;
    
    // Find the Slider in MPVolumeView
	for (UIView *view in [volumeView subviews]) {
		if ([[[view class] description] isEqualToString:@"MPVolumeSlider"]) 
        {
			volumeSlider = (UISlider *) view;
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
    [volumeControl release];
    volumeControl = nil;
    
    volumeControl = [volumeSlider retain];
    
    [volumeSlider release];
    [volumeView release];
    
    [lowerControls addSubview:volumeControl];
     
    // Start loading indicator
    [loadingIndicator startAnimating];
    
    [super viewDidLoad];
}

-(void)viewDidUnload 
{
    [playbackView release];
    playbackView = nil;
    
    [upperControls release];
    upperControls = nil;
    
    [lowerControls release];
    lowerControls = nil;
    
    [timeElapsed release];
    timeElapsed = nil;
    
    [timeRemaining release];
    timeRemaining = nil;
    
    [timeControl release];
    timeControl = nil;
    
    [volumeControl release];
    volumeControl = nil;
    
    [playButton release];
    playButton = nil;
    
    [fullscreenButton release];
    fullscreenButton = nil;
    
    [loadingIndicator release];
    loadingIndicator = nil;
    
    [timeObserver release];
    timeObserver = nil;
    
    [super viewDidUnload];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self removeTimeObserver];
    [super viewDidDisappear:animated];
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
 ////////////////////////////////////////////////////////////
 //
 // Orientationhandling for normal and fullscreen view
 //
 ////////////////////////////////////////////////////////////

//Handles the Rotation an the anchorpoint for the rotationanimation
- (CGAffineTransform)orientationTransformFromSourceBounds:(CGRect)sourceBounds
{
    
    UIDeviceOrientation orientation;
    
    // Check if the Rotation called from a Notification or is called from the fullScreenToogleButton
    if([[UIDevice currentDevice] orientation] == UIDeviceOrientationUnknown) {
        orientation = (UIDeviceOrientation)[[UIApplication sharedApplication] statusBarOrientation]; 
    } else {
        orientation = [[UIDevice currentDevice] orientation];
    }
    
    // Where is the display, it is shown to the ground or the the sky
	if (orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationFaceUp)
	{
        NSLog(@"FaceDownUP"); 
	}
    
    if (orientation == UIDeviceOrientationPortrait)
	{
        NSLog(@"Portrait"); 
        deviceOrientation = UIDeviceOrientationPortrait;
	}
    
    // Orientation for Protrait Upside Down
	if (orientation == UIDeviceOrientationPortraitUpsideDown)
	{
		CGAffineTransform result;
        deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
        
        NSLog(@"Upside Down");
        
        ////set different rotationangle for normal and fullscreenview
        
        if(!isFullscreen) {
            result = CGAffineTransformMakeRotation(2 * M_PI);
        } else {
            result = CGAffineTransformMakeRotation(M_PI);
        }
        
        return result;
	}
    
    // Orientation for Landscape Left
	else if (orientation == UIDeviceOrientationLandscapeLeft)
	{
        NSLog(@"Landscape Left");
        
        CGAffineTransform result;
        deviceOrientation = UIDeviceOrientationLandscapeLeft;
        
        if(!isFullscreen) {
            result = CGAffineTransformMakeRotation(0 * M_PI);
        } else {
            result = CGAffineTransformMakeRotation(0.5 * M_PI);
        }
		
        return result;
	}
    
    // Orientation for Landscape Right
	else if (orientation == UIDeviceOrientationLandscapeRight)
	{
        NSLog(@"Landscape Right");
    
        CGAffineTransform result;
        deviceOrientation = UIDeviceOrientationLandscapeRight;
        
        if(!isFullscreen) {
            result = CGAffineTransformMakeRotation(0 * M_PI);
        } else {
            result = CGAffineTransformMakeRotation(-0.5 * M_PI);
        }
		
        return result;
	}
    
    //If the Orientation Portrait do nothing an return the TransormIdentity
	return CGAffineTransformIdentity;
}

- (CGRect)rotatedWindowBounds
{
    UIDeviceOrientation orientation;
    
    // Check if the Rotation called from a Notification or is called from the fullScreenToogleButton
    if([[UIDevice currentDevice] orientation] == UIDeviceOrientationUnknown) {
        orientation = (UIDeviceOrientation)[[UIApplication sharedApplication] statusBarOrientation]; 
    } else {
        orientation = [[UIDevice currentDevice] orientation];
    }
	
	if (orientation == UIDeviceOrientationLandscapeLeft ||
		orientation == UIDeviceOrientationLandscapeRight)
	{
        
        //Different Viewsizes for normal and fullscreenview in Landscape Left and Right | Return the Bounds Rect 
        if(!isFullscreen) {
            CGRect windowBounds = self.view.bounds;
            return CGRectMake(0, 0, windowBounds.size.width, windowBounds.size.height);	
        } else {
            
            CGRect windowBounds = playbackView.bounds;
            if (deviceOrientation == orientation) {
                
                return CGRectMake(0, 0, windowBounds.size.width, windowBounds.size.height);
            }
            
            return CGRectMake(0, 0, windowBounds.size.height, windowBounds.size.width);
        }
	}
    
    //Different Viewsizes for normal and fullscreenview in Portrait | Return the Bounds Rect 
    if(!isFullscreen) {
        return self.view.bounds;
    } else {
        return self.view.window.bounds;
    }
    
    
    
}

// Method Called by Orientation Notification
- (void)deviceRotated:(NSNotification *)aNotification
{
    // if a Notfication fired for rotation
    if (aNotification)
    {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        
        if(orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown ||
           orientation == deviceOrientation) 
        {
            return;
        }
        
        CGRect windowBounds = playbackView.bounds;
        CGRect blankingFrame = CGRectMake(
                                    windowBounds.origin.x - (windowBounds.size.height * 0.5),
                                    windowBounds.origin.y - (windowBounds.size.height * 0.5),
                                    windowBounds.size.height * 2, 
                                    windowBounds.size.height * 2
                                );
        UIView *blankingView = [[[UIView alloc] initWithFrame:blankingFrame] autorelease];
        
        blankingView.backgroundColor = [UIColor blackColor];
        [self.view.window insertSubview:blankingView belowSubview:playbackView];
    
        [UIView animateWithDuration:0.25 
        animations:^{
            if(deviceOrientation == UIDeviceOrientationLandscapeRight && orientation == UIDeviceOrientationLandscapeLeft) 
            {
                playbackView.transform = [self orientationTransformFromSourceBounds:playbackView.bounds];
            }
            else if(deviceOrientation == UIDeviceOrientationLandscapeLeft && orientation == UIDeviceOrientationLandscapeRight) 
            {
                playbackView.transform = [self orientationTransformFromSourceBounds:playbackView.bounds];
            }
            playbackView.bounds = [self rotatedWindowBounds];
            playbackView.transform = [self orientationTransformFromSourceBounds:playbackView.bounds];
        } 
        completion:^(BOOL complete){
            [blankingView removeFromSuperview];
        }];
    }
    else
    {
        //rotate without animation / same functionality like with animation
        playbackView.bounds = [self rotatedWindowBounds];
        playbackView.transform = [self orientationTransformFromSourceBounds:playbackView.bounds];
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
    
    NSLog(@"Hallo");
    if (isFullscreen)
        buttonImage = [UIImage imageNamed:@"fullscreen-exit"];
    else
        buttonImage = [UIImage imageNamed:@"fullscreen-enter"];
    
    
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

@end

#pragma mark -
#pragma mark Player

@implementation HSVideoViewController (Player)

- (Float64)secondsWithCMTimeOrZeroIfInvalid:(CMTime)time {
    return CMTIME_IS_INVALID(time) ? 0.0f : CMTimeGetSeconds(time);
}

- (Float64)durationInSeconds 
{    
	return [self secondsWithCMTimeOrZeroIfInvalid:[playerItem duration]];
}

- (Float64)currentTimeInSeconds
{
    return [self secondsWithCMTimeOrZeroIfInvalid:[player currentTime]];
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
    /**
     * Create an asset for inspection of a resource referenced by a given URL.
     * Load the values for the asset keys "tracks", "playable".
     */
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    // Tells the asset to load the values of any of the specified keys that are not already loaded.
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{	
         dispatch_async( dispatch_get_main_queue(), 
                        ^{
                            // IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem.
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}

/** 
 * Called when the player item has played to its end time. 
 */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification 
{
    [player seekToTime:kCMTimeZero];
    [player setRate:0.f];
}

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{    
    [self removeTimeObserver];
    [self updateTimeScrubber];
    
    [timeControl setEnabled:NO];
    [playButton setEnabled:NO];
    
    [loadingIndicator stopAnimating];
    
    NSNumber *stopCode = [NSNumber numberWithInt: HSVideoFinishReasonPlaybackError];
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    
    [errorInfo setObject:stopCode forKey:HSVideoPlaybackDidFinishReasonUserInfoKey];
    [errorInfo setObject:error forKey:@"error"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HSVideoPlaybackDidFinishNotification 
                                                        object:self userInfo:errorInfo];
}

/**
 * Invoked at the completion of the loading of the values for all keys on the asset that required.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    // Make sure that the value of each key has loaded successfully.
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{            
            [self assetFailedToPrepareForPlayback:error];
			return;
		}
	}
    
    if (!asset.playable)
    {
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *error = [NSError errorWithDomain:@"HSVideoPlayer" code:0 userInfo:errorDict];
    
        [self assetFailedToPrepareForPlayback:error];
        return;
    }
	
    // Create a new instance of AVPlayerItem from the now successfully loaded AVAsset.
    playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    
    // Observe the player item "status" key to determine when it is ready to play.
    [playerItem addObserver:self 
                 forKeyPath:kStatusKey 
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:HSVideoPlayerItemStatusObserverContext];
    
    [playerItem addObserver:self 
                 forKeyPath:kBufferEmpty
                    options:NSKeyValueObservingOptionNew 
                    context:HSVideoPLayerBufferEmptyObserverContext];
    
    [playerItem addObserver:self 
                 forKeyPath:kLikelyToKeepUp
                    options:NSKeyValueObservingOptionNew 
                    context:HSVideoPlayerLikelyToKeepUpObserverContext];

    [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(playerItemDidReachEnd:)
                            name:AVPlayerItemDidPlayToEndTimeNotification
                            object:playerItem];
    
    // Get a new AVPlayer initialized to play the specified player item.
    player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    // Do nothing if the item has finished playing
    [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    
    /* Observe the AVPlayer "currentItem" property to find out when any 
     AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did 
     occur.*/
    [player addObserver:self 
             forKeyPath:kCurrentItemKey 
                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                context:HSVideoCurrentItemObserverContext];
    
    // Observe the AVPlayer "rate" property to update the scrubber control.
    [player addObserver:self
             forKeyPath:kRateKey 
                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                context:HSVideoRateObserverContext];
    
    [player replaceCurrentItemWithPlayerItem:playerItem];
    
    [timeControl setValue:0.0];
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
        
        [UIView animateWithDuration:0.4 
         animations:^{
             playbackView.frame = playbackView.window.bounds;
         }];
        
        //Add Observer for orientation change
        [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(deviceRotated:)
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
    }
    else 
    {
        
        CGRect frame = [self.view
                        convertRect:playbackView.frame
                        fromView:playbackView.window];
		playbackView.frame = frame;
        [self.view addSubview:playbackView];
        
        [UIView animateWithDuration:0.4 
         animations:^{
             playbackView.frame = self.view.frame;
         }];
        
        //Remove Observer for orientation change
        [[NSNotificationCenter defaultCenter] removeObserver:self
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
    }
    
    deviceOrientation = UIDeviceOrientationUnknown;
    
    [[UIApplication sharedApplication] 
     setStatusBarHidden:fullscreen
     withAnimation:UIStatusBarAnimationFade];
    
    isFullscreen = fullscreen;
    
    
    // Check the Device Orientation and rotate the application
    [self deviceRotated:nil];
    
    [self updateFullscreenButton];
}

- (void)observeValueForKeyPath:(NSString*) keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary*)change 
                       context:(void*)context
{
    
	// AVPlayerItem "status" property value observer.
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
                
                [loadingIndicator startAnimating];
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
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
                break;
        }
	}
	// AVPlayer "rate" property value observer.
	else if (context == HSVideoRateObserverContext)
	{
        [self updatePlayPauseButton];
	}
    // AVPlayer "currentItem" buffer is empty observer
    else if (context == HSVideoPLayerBufferEmptyObserverContext) 
    {
        if (!isScrubbing)
            [loadingIndicator startAnimating];
    }
    // AVPlayer "currentItem" is likely to keep up observer
    else if (context == HSVideoPlayerLikelyToKeepUpObserverContext)
    {
        if (!isScrubbing) {
            [loadingIndicator stopAnimating];
        }
    }
	// AVPlayer "currentItem" property observer. 
	else if (context == HSVideoCurrentItemObserverContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        // New player item null? 
        if (newPlayerItem == (id)[NSNull null])
        {            
            [playButton setEnabled:NO];
            [timeControl setEnabled:NO];
            
        } else  // Replacement of player currentItem has occurred
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