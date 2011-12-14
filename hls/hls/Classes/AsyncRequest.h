/**
 * AsynRequest.h
 *
 * AsynRequest makes the communicating with web servers easier.
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import "AsyncRequestDelegate.h"

typedef enum
{
    AsyncRequestUseProtocolCachePolicy =  NSURLRequestUseProtocolCachePolicy,
    AsyncRequestIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData,
    AsyncRequestReturnCacheDataElseLoad = NSURLRequestReturnCacheDataElseLoad,
    AsyncRequestReturnCacheDataDontLoad = NSURLRequestReturnCacheDataDontLoad,
} AsyncRequestCachePolicy;

@interface AsyncRequest : NSOperation {

@private

    // Will contain the received data
    NSMutableData *receivedData;
    
    // Will contain the connection
    NSURLConnection *connection;
    
    BOOL isFinished;
    BOOL isExecuting;
    
@public
    
    // The url used for making the request
    NSURL *requestURL;
    
    // Username and password used for authentication
    NSString *username;
    NSString *password;
    
    // The cache policy that will be used for this request
    AsyncRequestCachePolicy cachePolicy;
    
    // Number of seconds to wait before timing out
    NSTimeInterval timeoutInterval;
    
    // The delegate - will be notified of various changes in state via the AsyncRequestDelegate protocol
    NSObject <AsyncRequestDelegate> *delegate;
    
    // Size of the response
    unsigned long long contentLength;
    
    // The total amount of downloaded data
    unsigned long long totalBytesRead;
}

@property (nonatomic, retain) NSURL *requestURL;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, assign) AsyncRequestCachePolicy cachePolicy;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSObject <AsyncRequestDelegate> *delegate;
@property (nonatomic, readonly) unsigned long long contentLength;
@property (nonatomic, readonly) unsigned long long totalBytesRead;

#pragma mark -
#pragma mark class methods

+ (id)requestWithURL:(NSURL *)theURL;
+ (id)requestWithURL:(NSURL *)theURL andCachePolicy:(AsyncRequestCachePolicy)policy;

#pragma mark -
#pragma mark instance methods

- (id)initWithURL:(NSURL *)theURL;
- (id)initWithURL:(NSURL *)theURL andCachePolicy:(AsyncRequestCachePolicy)policy;
- (void)addAuthenticationWithUsername:(NSString *)theUsername andPassword:(NSString *)thePassword;

@end

