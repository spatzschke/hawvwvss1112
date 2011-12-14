//
//  MovieCell.m
//  MasterDetail
//
//  Created by Jennifer Schöndorf on 10.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

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
