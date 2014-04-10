#import <Foundation/Foundation.h>

@interface NSURLSession (Spec)

@property (nonatomic, strong, readonly) NSArray *tasks;
@property (nonatomic, strong, readonly) NSArray *dataTasks;

- (void)dataTask:(NSURLSessionDataTask *)task didReceiveResponse:(NSURLResponse *)response;
- (void)dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data;
- (void)taskDidComplete:(NSURLSessionTask *)task error:(NSError *)error;

- (void)task:(NSURLSessionTask *)task
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void(^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler;

@end
