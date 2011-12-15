/**
 * DetailViewController.h
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

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
