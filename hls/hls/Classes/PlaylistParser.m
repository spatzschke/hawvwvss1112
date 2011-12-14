//
//  XML.m
//  VWSplitView
//
//  Created by Jennifer Schöndorf on 11.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistParser.h"

@implementation PlaylistParser

@synthesize delegate;
@synthesize url;

-(id)initWithURL:(NSURL *)theURL{
    self = [super init];
    if(self){
        [self setUrl:theURL];
        request = [[AsyncRequest alloc] initWithURL:[self url] andCachePolicy:AsyncRequestIgnoringCacheData];
        [request setDelegate:self];
        [request start];
        
        movies= [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc{
    delegate = nil;
    [request release];
    [movies release];
    [xmlParser release];
    [currentDuration release];
    [currentElement release];
    [currentPath release];
    [currentPoster release];
    [currentTitle release];
    [url release];
    
    [super dealloc];
}

-(void)requestFailed:(AsyncRequest *)request withError:(NSError *)error{
}
-(void)requestFinished:(AsyncRequest *)request withData:(NSMutableData *)data{
    xmlParser = [[NSXMLParser alloc] initWithData:data];
    
    [xmlParser setDelegate:self];
    [xmlParser setShouldProcessNamespaces:NO];
    [xmlParser setShouldReportNamespacePrefixes:NO];
    [xmlParser setShouldResolveExternalEntities:NO];
    [xmlParser parse];
}

-(void)parserDidStartDocument:(NSXMLParser *)parser{
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    if([delegate respondsToSelector:@selector(parseFaild:withError:)]){
        [delegate parseFaild:self withError:parseError];
    }
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
 namespaceURI:(NSString *)namespaceURI 
qualifiedName:(NSString *)qName 
   attributes:(NSDictionary *)attributeDict{
    
    currentElement = [elementName copy];
    if([currentElement isEqualToString:@"item"]){
        [currentDuration release];
        currentDuration = nil;
        
        [currentPath release];
        currentPath = nil;
        
        [currentPoster release];
        currentPoster = nil;
        
        [currentTitle release];
        currentTitle = nil;
        
        currentDuration = [[NSMutableString alloc] init];
        currentPath = [[NSMutableString alloc] init];
        currentPoster = [[NSMutableString alloc] init];
        currentTitle = [[NSMutableString alloc] init];
            
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
 namespaceURI:(NSString *)namespaceURI 
qualifiedName:(NSString *)qName{
    if([elementName isEqualToString:@"item"]){
        NSMutableDictionary *movie = [[NSMutableDictionary alloc] init];
        [movie setObject:currentTitle forKey:@"title"];
        [movie setObject:currentDuration forKey:@"duration"];
        [movie setObject:currentPath forKey:@"path"];
        [movie setObject:currentPoster forKey:@"poster"];
        
        [movies addObject:movie];
        
        [movie release];
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    
    if([currentElement isEqualToString:@"title"]){
        [currentTitle appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }else if([currentElement isEqualToString:@"duration"]){
        [currentDuration appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }else if([currentElement isEqualToString:@"poster"]){
        [currentPoster appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }else if([currentElement isEqualToString:@"path"]){
        [currentPath appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{       
    if([delegate respondsToSelector:@selector(parseFinished:withMovies:)]){
        [delegate parseFinished:self withMovies:movies];
    }
}

@end
