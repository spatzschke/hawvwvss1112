/**
 * PlaylistParser.h
 * 
 * Responsible for loading and parsing xml asynchronously
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import <Foundation/Foundation.h>
#import "AsyncRequest.h"
#import "PlaylistParserDelegate.h"

@interface PlaylistParser : NSObject <AsyncRequestDelegate, NSXMLParserDelegate> {

    @private
        NSMutableArray *movies;
        NSXMLParser *xmlParser;
        AsyncRequest *request;
    
        NSMutableString *currentTitle;
        NSMutableString *currentDuration;
        NSMutableString *currentPoster;
        NSMutableString *currentPath;
    
        NSString *currentElement;
    
    @public
        NSURL *url;
        NSObject<PlaylistParserDelegate> *delegate;
    
}

@property (nonatomic, assign) NSObject<PlaylistParserDelegate> *delegate;
@property (nonatomic, assign) NSURL *url;

-(id)initWithURL:(NSURL *)theURL;


@end
