#import <Foundation/Foundation.h>
#import "NSURLSessionTask+Spec.h"

@interface NSURLSessionDataTask (Spec)<NSURLSpecSessionTask>

+ (instancetype)taskWithRequest:(NSURLRequest *)request session:(NSURLSession *)session identifier:(NSUInteger)identifer;

- (void)receiveData:(NSData *)data;
- (void)completeWithError:(NSError *)error; // Task
- (void)completeWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error;

@end
