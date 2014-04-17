#import "NSURLSession+Spec.h"
#import "NSURLSessionDataTask+Spec.h"
#import "NSURLRequest+Spec.h"
#import "objc/runtime.h"

@interface NSURLSpecSession : NSObject

@property (nonatomic, strong, readwrite) NSMutableArray *dataTasks;
@property (nonatomic, strong) NSURLSessionConfiguration *configuration;
@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) BOOL valid;

@property (nonatomic, assign) NSUInteger nextIdentifier;

@end


@implementation NSURLSpecSession

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id <NSURLSessionDelegate>)delegate delegateQueue:(NSOperationQueue *)queue {
    self.configuration = configuration;
    self.delegate = delegate;

    self.dataTasks = [NSMutableArray array];
    self.valid = YES;
    return self;
}

#pragma mark - Overrides

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    if (!self.valid) {
        [[NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Attempt to create network connection with invalidated session"
                               userInfo:nil]
         raise];
    }

    [self addAdditionalHeaderFieldsToRequest:request];
    NSURLSessionDataTask *task = [NSURLSessionDataTask taskWithRequest:request
                                                               session:self.toNS
                                                            identifier:self.nextIdentifier];
    [self.dataTasks addObject:task];
    return task;
}

- (void)getTasksWithCompletionHandler:(void (^)(NSArray *, NSArray *, NSArray *))completionHandler {
    completionHandler(self.dataTasks, [NSArray array], [NSArray array]);
}

- (void)invalidateAndCancel {
    self.valid = NO;
    [self.dataTasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask *task, NSUInteger idx, BOOL *stop) {
        [task cancel];
    }];
    [self notifyInvalid];
}

- (void)finishTasksAndInvalidate {
    self.valid = NO;
    [self notifyInvalid];
}

#pragma mark - Spec interface

- (NSArray *)tasks {
    return self.dataTasks;
}

- (void)dataTask:(NSURLSessionDataTask *)task didReceiveResponse:(NSURLResponse *)response {
    id delegate = [self delegateForSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)];
    [delegate URLSession:self.toNS
                dataTask:task
      didReceiveResponse:response
       completionHandler:^(NSURLSessionResponseDisposition disposition) {}
     ];
}

- (void)dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data {
    id delegate = [self delegateForSelector:@selector(URLSession:dataTask:didReceiveData:)];
    [delegate URLSession:self.toNS dataTask:task didReceiveData:data];
}

- (void)taskDidComplete:(NSURLSessionTask *)task error:(NSError *)error {
    [self.dataTasks removeObject:task];

    id delegate = [self delegateForSelector:@selector(URLSession:task:didCompleteWithError:)];
    [delegate URLSession:self.toNS task:task didCompleteWithError:error];

    if (!self.valid) {
        [self notifyInvalid];
    }
}

- (void)task:(NSURLSessionTask *)task
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void(^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    id delegate = [self delegateForSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)];
    [delegate URLSession:self.toNS task:task didReceiveChallenge:challenge completionHandler:completionHandler];
}

#pragma mark - Private

- (NSUInteger)nextIdentifier {
    return _nextIdentifier++;
}

- (NSURLSession *)toNS {
    return (NSURLSession *)self;
}

- (id)delegateForSelector:(SEL)sel {
    if ([self.delegate respondsToSelector:sel]) {
        return self.delegate;
    } else {
        return nil;
    }
}

- (void)notifyInvalid {
    if (!self.tasks.count) {
        id delegate = [self delegateForSelector:@selector(URLSession:didBecomeInvalidWithError:)];
        [delegate URLSession:self.toNS didBecomeInvalidWithError:nil];
    }
}

- (void)addAdditionalHeaderFieldsToRequest:(NSURLRequest *)request {
    [self.configuration.HTTPAdditionalHeaders enumerateKeysAndObjectsUsingBlock:^(id header, id value, BOOL *stop) {
        [request setValue:value forHTTPHeaderField:header];
    }];
}

@end

#pragma mark - NSURLSession+Spec
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
#pragma clang diagnostic ignored "-Wincomplete-implementation"
#pragma clang diagnostic ignored "-Wobjc-property-implementation"

@implementation NSURLSession (Spec)

+ (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration {
    return (NSURLSession *)[[NSURLSpecSession alloc] initWithConfiguration:configuration delegate:nil delegateQueue:nil];
}

+ (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id<NSURLSessionDelegate>)delegate delegateQueue:(NSOperationQueue *)queue {
    return (NSURLSession *)[[NSURLSpecSession alloc] initWithConfiguration:configuration delegate:delegate delegateQueue:queue];
}

@end

#pragma clang diagnostic pop
