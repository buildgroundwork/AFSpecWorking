#import "NSURLSessionTask+Spec.h"
#import "NSURLSession+Spec.h"

#pragma mark - NSURLAuthenticationChallengeResponse
@interface NSURLAuthenticationChallengeResponse ()

@property (nonatomic, assign, readwrite) NSURLSessionAuthChallengeDisposition disposition;
@property (nonatomic, strong, readwrite) NSURLCredential *credential;

@end

@implementation NSURLAuthenticationChallengeResponse

- (instancetype)initWithDisposition:(NSURLSessionAuthChallengeDisposition)disposition
                         credential:(NSURLCredential *)credential {
    if (self = [super init]) {
        self.disposition = disposition;
        self.credential = credential;
    }
    return self;
}
@end

#pragma mark - NSURLSpecSessionTask
@interface NSURLSpecSessionTask ()

@property (nonatomic, weak) NSURLSession *session;
@property (nonatomic, assign) NSURLSessionTaskState state;
@property (nonatomic, assign) NSUInteger taskIdentifier;
@property (nonatomic, strong) NSURLRequest *originalRequest;
@property (nonatomic, strong) NSMutableArray *authenticationChallengeResponses;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation NSURLSpecSessionTask

- (instancetype)initWithRequest:(NSURLRequest *)request
                        session:(NSURLSession *)session
                     identifier:(NSUInteger)identifier {
    if (self = [super init]) {
        self.originalRequest = request;
        self.session = session;
        self.state = NSURLSessionTaskStateSuspended;
        self.taskIdentifier = identifier;
        self.authenticationChallengeResponses = [NSMutableArray array];
    }
    return self;
}

- (void)resume {
    [self ifNotCompleted:^{
        self.state = NSURLSessionTaskStateRunning;
    }];
}

- (void)suspend {
    [self ifNotCompleted:^{
        self.response = nil;
        self.state = NSURLSessionTaskStateSuspended;
    }];
}

- (void)cancel {
    [self ifNotCompleted:^{
        NSError *error = [NSError errorWithDomain:@"cancelled" code:-999 userInfo:nil];
        self.state = NSURLSessionTaskStateCompleted;
        [self.session taskDidComplete:self.toNS error:error];
    }];
}

#pragma mark Spec interface

- (void)receiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self ifRunning:^{
        [self.session task:self.toNS didReceiveAuthenticationChallenge:challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) {
            NSURLAuthenticationChallengeResponse *response = [[NSURLAuthenticationChallengeResponse alloc] initWithDisposition:disposition credential:credential];
            [self.authenticationChallengeResponses addObject:response];
        }];
    }];
}

- (void)receiveResponse:(NSURLResponse *)response {
    self.response = response;
}

- (void)completeWithError:(NSError *)error {
    [self ifRunning:^{
        [self ensureResponse];
        self.state = NSURLSessionTaskStateCompleted;
        [self.session taskDidComplete:self.toNS error:error];
    }];
}

- (void)ensureResponse {
    if (!self.response) {
        self.response = [[NSHTTPURLResponse alloc] initWithURL:self.originalRequest.URL
                                                    statusCode:200
                                                   HTTPVersion:@"1.0"
                                                  headerFields:@{}
                         ];
    }
}

- (void)ifRunning:(void (^)())action {
    if (self.state == NSURLSessionTaskStateRunning) {
        action();
    }
}

#pragma mark Private interface

- (NSURLSessionTask *)toNS {
    return (NSURLSessionTask *)self;
}

- (void)ifNotCompleted:(void (^)())action {
    if (self.state != NSURLSessionTaskStateCompleted) {
        action();
    }
}

@end
