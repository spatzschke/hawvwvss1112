/**
 * PlaylistParserDelegate.h
 *
 * Part of PlaylistParser.
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

@class PlaylistParser;

@protocol PlaylistParserDelegate <NSObject>

@required
-(void)parseFaild:(PlaylistParser *)parser withError:(NSError *)error;

@optional
-(void)parseFinished:(PlaylistParser *)parser withMovies:(NSMutableArray *)movies;


@end
