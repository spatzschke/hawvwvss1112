/**
 * AsynRequest.m
 *
 * AsynRequest makes the communicating with web servers easier.
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import "AsyncRequest.h"

@implementation AsyncRequest

@synthesize requestURL;
@synthesize username;
@synthesize password;
@synthesize cachePolicy;
@synthesize timeoutInterval;
@synthesize delegate;
@synthesize contentLength;
@synthesize totalBytesRead;

#pragma mark -
#pragma mark init / dealloc

- (id)init
{
    return [self initWithURL:[NSURL URLWithString:@""]];
}

- (id)initWithURL:(NSURL *)theURL
{
    self = [super init];    
    if (self) 
    {
        [self setRequestURL:theURL];
        [self setCachePolicy:AsyncRequestUseProtocolCachePolicy];
        [self setTimeoutInterval:60.0];
    
        isExecuting = NO;
        isFinished = NO;
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)theURL andCachePolicy:(AsyncRequestCachePolicy)policy
{
    self =[self initWithURL:theURL];
    [self setCachePolicy:policy];
    
    return self;    
}

+ (id)requestWithURL:(NSURL *)theURL
{
    return [[[self alloc] initWithURL:theURL] autorelease];
}

+ (id)requestWithURL:(NSURL *)theURL andCachePolicy:(AsyncRequestCachePolicy)policy
{
    AsyncRequest *request = [[[self alloc] initWithURL:theURL] autorelease];
    [request setCachePolicy:policy];
    
    return request;
}

- (void)dealloc
{
    delegate = nil;
    
    if (connection != nil) 
    {
        [connection cancel];
    }
   
    [receivedData release];
    [connection release];
    
    [requestURL release];
    [username release];
    [password release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark private methods

- (void)markAsFinished
{
    if (connection != nil) 
    {
        [connection cancel];
    }
    
    [connection release];
    connection = nil;
    
    [receivedData release];
    receivedData = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    isExecuting = NO;
    isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark -
#pragma mark public methods

- (void)start 
{
    
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        
        return;
    }
    
    if ([self isCancelled] || [self isFinished]) {
        return;
    }
    
    contentLength = 0;
    totalBytesRead = 0;
    
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    receivedData = [[NSMutableData alloc] init];
    
    // Create the connection with the URL
    NSURLRequest *request = [NSURLRequest requestWithURL:[self requestURL] cachePolicy:[self cachePolicy] 
                                         timeoutInterval:[self timeoutInterval]];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        
    // Used to prevent that user interaction blocks the connection
    // See: http://pixeldock.com/blog/how-to-avoid-blocked-downloads-during-scrolling/
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSRunLoopCommonModes];
    
    if (connection == nil)
    {
        [self markAsFinished];
        return;
    }
    
    // Establish connection
    [connection start];

    
}

- (void)cancel
{
    // Already canceled
    if ([self isCancelled])
    {
        return;
    }
    
    [self markAsFinished];
    [super cancel];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return isExecuting;
}

- (BOOL)isFinished
{
    return isFinished;
}

- (void)addAuthenticationWithUsername:(NSString *)theUsername andPassword:(NSString *)thePassword 
{
    [self setUsername:theUsername];
    [self setPassword:thePassword];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Reset the data as this could be fired if a redirect or other response occurs
    [receivedData setLength:0];
    
    contentLength = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{    
    // Append the received data each time this is called
    [receivedData appendData:data];
    
    totalBytesRead += [data length];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (!contentLength)
    {
        contentLength = totalBytesRead;
    }
    
    if (delegate && [delegate respondsToSelector:@selector(requestFinished:withData:)])
    {   
        [delegate requestFinished:self withData:receivedData];
    }
    
    [self markAsFinished];
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    if (delegate && [delegate respondsToSelector:@selector(requestFailed:withError:)])
    {        
        [delegate requestFailed:self withError:error];
    }
    
    [self markAsFinished];
}

- (void)connection:(NSURLConnection *)connection 
                    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (delegate && [delegate respondsToSelector:@selector(authenticationNeededForRequest:)])
    {
        [delegate authenticationNeededForRequest:self];
    }
    
    if ([self username] && [self password])
    {
        // Answer the challenge
        NSURLCredential *credential = [[[NSURLCredential alloc] initWithUser:[self username] password:[self password]
                                                           persistence:NSURLCredentialPersistenceForSession] autorelease];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    }
    else 
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

-(void) connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (delegate && [delegate respondsToSelector:@selector(authenticationCanceledForRequest:)])
    {
        [delegate authenticationCanceledForRequest:self];
    }
    
    [self markAsFinished];
}

@end
