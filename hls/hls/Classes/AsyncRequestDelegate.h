/**
 * AsynRequestDelegate.h
 *
 * Part of AsynRequest.
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

@class AsyncRequest;

@protocol AsyncRequestDelegate <NSObject>

@required
- (void)requestFailed:(AsyncRequest *)request withError:(NSError *)error;

@optional
- (void)requestFinished:(AsyncRequest *)request withData:(NSMutableData *)data;
- (void)authenticationNeededForRequest:(AsyncRequest *)request;
- (void)authenticationCanceledForRequest:(AsyncRequest *)request;

@end
