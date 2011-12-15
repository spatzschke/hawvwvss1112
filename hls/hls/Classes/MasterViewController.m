/**
 * MasterViewController.m
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import "MasterViewController.h"

#import "DetailViewController.h"

@interface MasterViewController (Private)
-(NSString *)timeStringForSeconds:(NSUInteger)seconds;
@end

@implementation MasterViewController

@synthesize detailViewController;

- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)dealloc
{
    [playlistParser release];
    [movieItems release];
    [imageQueue release];

    [detailViewController release];
    [super dealloc];
    
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
	// Do any additional setup after loading the view, typically from a nib.
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    playlistParser = [[PlaylistParser alloc] initWithURL:[NSURL URLWithString:@"http://dev.jennifer-schoendorf.de/movies.xml"]];
    [playlistParser setDelegate:self];
    
    imageQueue = [[NSOperationQueue alloc] init];
    
    hasLoaded = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(NSString *)timeStringForSeconds:(NSUInteger)seconds{
    NSUInteger minutes = seconds / 60;
    NSUInteger secondsLeftOver = seconds % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld min", minutes, secondsLeftOver];
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(hasLoaded){
        return [movieItems count];
    }else{
        return 1;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!hasLoaded){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
        
        if(cell == nil){
            cell =[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadingCell"] autorelease];
        }
        
        return cell;
    }
    
    MovieCell *cell = (MovieCell *)[tableView dequeueReusableCellWithIdentifier:@"MovieCell"];
    
    
    if(cell == nil){
        cell =[[[MovieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MovieCell"] autorelease];
    }
    
    NSMutableDictionary *currentItem = [[movieItems objectAtIndex:indexPath.row] retain];
    
    AsyncRequest *request = [[AsyncRequest alloc] initWithURL:[NSURL URLWithString:[currentItem objectForKey:@"poster"]]];
    [request setDelegate:cell];
    
    [imageQueue addOperation:request];
    [request release];
    
    NSUInteger duration = (NSUInteger) [[currentItem objectForKey:@"duration"] intValue];
    // Configure the cell.
    cell.movieTitle.text = [currentItem objectForKey:@"title"];
    cell.movieDuration.text = [self timeStringForSeconds:duration];
    [currentItem release];
        
    return cell;
   
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!hasLoaded) {
        return;
    }
    
    [self.detailViewController showMovie:[movieItems objectAtIndex:indexPath.row]];
}

-(void)parseFaild:(PlaylistParser *)xml withError:(NSError *)error{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                        message:@"Die XML-Datei konnte nicht geparsed werden."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

-(void)parseFinished:(PlaylistParser *)xml withMovies:(NSMutableArray *)movies{
    hasLoaded = YES;

    movieItems = [movies retain];
    [self.tableView reloadData];
}

@end
