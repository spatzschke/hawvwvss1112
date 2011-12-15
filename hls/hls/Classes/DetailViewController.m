//
//  DetailViewController.m
//  VWSplitView
//
//  Created by Jennifer Schöndorf on 10.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation DetailViewController

@synthesize detailItem;
@synthesize masterPopoverController;
@synthesize movieTitle;
@synthesize movieView;

- (void)dealloc
{
    [detailItem release];
    [masterPopoverController release];
    [movieTitle release];
    [movieView release];
    [super dealloc];
}

#pragma mark - Managing the detail item

- (void)showMovie:(NSMutableDictionary *)movie 
{    
    if (videoController != nil) 
    {
        [videoController.view removeFromSuperview];
        [videoController release];
        videoController = nil;
    }
    
    NSURL *videoURL = [[NSURL alloc] initWithString:[movie objectForKey:@"path"]];
    videoController = [[HSVideoViewController alloc] initWithContentURL:videoURL];
    
    self.movieTitle.text = [movie objectForKey:@"title"];
    videoController.view.frame = movieView.bounds;
    [movieView addSubview:videoController.view];
    
    [videoController setShouldAutoplay:YES];
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
    
    [videoURL release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Videos", @"Videos");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
