//
//  XMLDelegate.h
//  VWSplitView
//
//  Created by Jennifer Schöndorf on 11.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

@class PlaylistParser;

@protocol PlaylistParserDelegate <NSObject>

@required
-(void)parseFaild:(PlaylistParser *)parser withError:(NSError *)error;

@optional
-(void)parseFinished:(PlaylistParser *)parser withMovies:(NSMutableArray *)movies;


@end
