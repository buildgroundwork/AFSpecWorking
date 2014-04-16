#import <Foundation/Foundation.h>

@interface NSURLAuthenticationChallengeResponse : NSObject

@property (nonatomic, assign, readonly) NSURLSessionAuthChallengeDisposition disposition;
@property (nonatomic, strong, readonly) NSURLCredential *credential;

@end


@protocol NSURLSpecSessionTask

- (NSURLSession *)session;
- (NSArray *)authenticationChallengeResponses;

- (void)receiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)receiveResponse:(NSURLResponse *)response;
- (void)completeWithError:(NSError *)error;

@end

@interface NSURLSpecSessionTask : NSObject<NSURLSpecSessionTask>

- (instancetype)initWithRequest:(NSURLRequest *)request
                        session:(NSURLSession *)session
                     identifier:(NSUInteger)identifier;
- (void)ensureResponse;
- (void)ifRunning:(void (^)())action;

@end


@interface NSURLSessionTask (Spec)<NSURLSpecSessionTask>

@end
