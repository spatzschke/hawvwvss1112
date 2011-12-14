//
//  PlaybackView.m
//  hls
//
//  Created by Sebastian Schuler on 04.12.11.
//  Copyright (c) 2011 commercetools.de. All rights reserved.
//

#import "PlaybackView.h"
#import <AVFoundation/AVFoundation.h>

@implementation PlaybackView

+ (Class)layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayer*)player
{
	return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player
{
	[(AVPlayerLayer*)[self layer] setPlayer:player];
}

- (void)setVideoFillMode:(NSString *)fillMode
{
	AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
	playerLayer.videoGravity = fillMode;
}

@end
