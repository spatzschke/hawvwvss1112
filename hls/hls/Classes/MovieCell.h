/**
 * MovieCell.h
 * 
 * Custom UITableViewCell to display the video data
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import <UIKit/UIKit.h>
#import "AsyncRequest.h"

@interface MovieCell : UITableViewCell<AsyncRequestDelegate>

@property (nonatomic, retain) IBOutlet UIImageView *movieImage;
@property (nonatomic, retain) IBOutlet UILabel *movieTitle;
@property (nonatomic, retain) IBOutlet UILabel *movieDuration;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingPanel;

@end
