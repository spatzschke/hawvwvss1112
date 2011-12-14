//
//  MasterViewController.h
//  VWSplitView
//
//  Created by Jennifer Schöndorf on 10.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

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
