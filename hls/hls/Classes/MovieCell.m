/**
 * MovieCell.m
 * 
 * Custom UITableViewCell to display the video data
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import "MovieCell.h"

@implementation MovieCell

@synthesize movieImage;
@synthesize movieDuration;
@synthesize movieTitle;
@synthesize loadingPanel;

-(void) requestFailed:(AsyncRequest *)request withError:(NSError *)error{
    
}

-(void) requestFinished:(AsyncRequest *)request withData:(NSMutableData *)data{
    UIImage *remoteImage = [[UIImage alloc] initWithData:data];
    self.movieImage.image = remoteImage;
    [remoteImage release];
    [self.loadingPanel stopAnimating];
}

@end
