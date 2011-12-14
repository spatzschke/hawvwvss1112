//
//  DetailViewController.h
//  VWSplitView
//
//  Created by Jennifer Schöndorf on 10.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HSVideoViewController.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>{
    @private
    HSVideoViewController *videoController;
}

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *movieTitle;
@property (strong, nonatomic) IBOutlet UIView *movieView;

- (void)showMovie:(NSMutableDictionary *)movie;

@end
