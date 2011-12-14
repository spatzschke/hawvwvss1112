//
//  PlaybackView.h
//  hls
//
//  Created by Sebastian Schuler on 04.12.11.
//  Copyright (c) 2011 commercetools.de. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface PlaybackView : UIView

@property (nonatomic, retain) AVPlayer* player;

- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
