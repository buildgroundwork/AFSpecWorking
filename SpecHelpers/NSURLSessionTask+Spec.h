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

@end

@interface NSURLSpecSessionTask : NSObject<NSURLSpecSessionTask>

- (instancetype)initWithRequest:(NSURLRequest *)request session:(NSURLSession *)session;
- (void)ensureResponse;

@end


@interface NSURLSessionTask (Spec)<NSURLSpecSessionTask>

@end
