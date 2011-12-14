//
//  MovieCell.h
//  MasterDetail
//
//  Created by Jennifer Schöndorf on 10.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncRequest.h"

@interface MovieCell : UITableViewCell<AsyncRequestDelegate>

@property (nonatomic, retain) IBOutlet UIImageView *movieImage;
@property (nonatomic, retain) IBOutlet UILabel *movieTitle;
@property (nonatomic, retain) IBOutlet UILabel *movieDuration;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingPanel;

@end
