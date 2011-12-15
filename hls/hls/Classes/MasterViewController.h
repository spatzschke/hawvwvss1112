/**
 * MasterViewController.h
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import <UIKit/UIKit.h>
#import "MovieCell.h"
#import "PlaylistParser.h"
#import "AsyncRequest.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <PlaylistParserDelegate>{
    @private
    PlaylistParser *playlistParser;
    NSMutableArray *movieItems;
    NSOperationQueue *imageQueue;
    
    BOOL hasLoaded;
}

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
