/**
 * PlaybackView.h
 * 
 * Holds the video player and display output
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface PlaybackView : UIView

@property (nonatomic, retain) AVPlayer* player;

- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
