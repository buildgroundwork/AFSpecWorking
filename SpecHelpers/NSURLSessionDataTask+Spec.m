#import "NSURLSessionDataTask+Spec.h"
#import "NSURLSessionTask+Spec.h"
#import "NSURLSession+Spec.h"

@interface NSURLSpecSessionDataTask : NSURLSpecSessionTask
@end

@implementation NSURLSpecSessionDataTask

- (void)cancel {
    NSError *error = [NSError errorWithDomain:@"cancelled" code:-999 userInfo:nil];
    [self.session taskDidComplete:self.toNS error:error];
}

#pragma mark - Spec interface

- (void)receiveResponse:(NSURLResponse *)response {
    [super receiveResponse:response];
    [self.session dataTask:self.toNS didReceiveResponse:response];
}

- (void)receiveData:(NSData *)data {
    [self ensureResponse];
    [self.session dataTask:self.toNS didReceiveData:data];
}

- (void)completeWithError:(NSError *)error {
    [self ensureResponse];
    [self.session taskDidComplete:self.toNS error:error];
}

- (void)completeWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error {
    [self receiveResponse:response];
    if (data) {
        [self receiveData:data];
    }
    [self completeWithError:error];
}

#pragma mark - Private interface

- (NSURLSessionDataTask *)toNS {
    return (NSURLSessionDataTask *)self;
}

@end


#pragma mark - NSURLSessionDataTask+Spec
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
#pragma clang diagnostic ignored "-Wincomplete-implementation"
#pragma clang diagnostic ignored "-Wobjc-property-implementation"

@implementation NSURLSessionDataTask (Spec)

+ (instancetype)taskWithRequest:(NSURLRequest *)request session:(NSURLSession *)session identifier:(NSUInteger)identifier {
    return (NSURLSessionDataTask *)[[NSURLSpecSessionDataTask alloc] initWithRequest:request
                                                                             session:session
                                                                          identifier:identifier];
}

@end

#pragma clang diagnostic pop
