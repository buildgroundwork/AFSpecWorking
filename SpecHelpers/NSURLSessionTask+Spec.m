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
@property (nonatomic, strong) NSURLRequest *originalRequest;
@property (nonatomic, strong) NSMutableArray *authenticationChallengeResponses;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation NSURLSpecSessionTask

- (instancetype)initWithRequest:(NSURLRequest *)request session:(NSURLSession *)session {
    if (self = [super init]) {
        self.originalRequest = request;
        self.session = session;
        self.authenticationChallengeResponses = [NSMutableArray array];
    }
    return self;
}

- (void)receiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self.session task:self.toNS didReceiveAuthenticationChallenge:challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) {
        NSURLAuthenticationChallengeResponse *response = [[NSURLAuthenticationChallengeResponse alloc] initWithDisposition:disposition credential:credential];
        [self.authenticationChallengeResponses addObject:response];
    }];
}

- (void)receiveResponse:(NSURLResponse *)response {
    self.response = response;
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

#pragma mark Private interface

- (NSURLSessionTask *)toNS {
    return (NSURLSessionTask *)self;
}

@end
