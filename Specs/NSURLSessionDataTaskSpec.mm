#import "NSURLSessionDataTask+Spec.h"
#import "NSURLSession+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@protocol NSURLSessionEverythingDelegate <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@end

SPEC_BEGIN(NSURLSessionDataTaskSpec)

describe(@"NSURLSessionDataTask", ^{
    __block NSURLSession *session;
    __block NSURLSessionDataTask *task;
    __block NSURLRequest *request;
    __block id delegate;

    beforeEach(^{
        NSURL *url = [NSURL URLWithString:@"/"];
        request = [NSURLRequest requestWithURL:url];
        delegate = nice_fake_for(@protocol(NSURLSessionEverythingDelegate));
        session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:[[NSOperationQueue alloc] init]];

        task = [session dataTaskWithRequest:request];
    });

    describe(@"-cancel", ^{
        subjectAction(^{ [task cancel]; });

        it(@"should remove the task from the session's list of tasks", ^{
            session.dataTasks should_not contain(task);
        });

        context(@"when the delegate implements -URLSession:task:didCompleteWithError:", ^{
            beforeEach(^{
                delegate stub_method("URLSession:task:didCompleteWithError:");
            });

            it(@"should notify the delegate", ^{
                delegate should have_received("URLSession:task:didCompleteWithError:").with(session, task, Arguments::any([NSError class]));
            });
        });

        context(@"when the delegate does not implement -URLSession:task:didCompleteWithError:", ^{
            beforeEach(^{
                delegate reject_method("URLSession:task:didCompleteWithError:");
            });

            it(@"should not try to notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didCompleteWithError:");
            });
        });
    });

    describe(@"-receiveResponse:", ^{
        __block NSURLResponse *response;

        subjectAction(^{ [task receiveResponse:response]; });

        beforeEach(^{
            NSURL *url = [NSURL URLWithString:@"/"];
            response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.0" headerFields:@{}];
        });

        it(@"should not remove the task from the session's list of tasks", ^{
            session.dataTasks should contain(task);
        });

        it(@"should assign the response to the task's response property", ^{
            task.response should equal(response);
        });

        context(@"when the delegate implements -URLSession:dataTask:didReceiveResponse:completionHandler:", ^{
            beforeEach(^{
                delegate stub_method("URLSession:dataTask:didReceiveResponse:completionHandler:");
            });

            it(@"should notify the delegate", ^{
                delegate should have_received("URLSession:dataTask:didReceiveResponse:completionHandler:").with(session, task, response, Arguments::anything);
            });
        });

        context(@"when the delegate does not implement -URLSession:dataTask:didReceiveResponse:completionHandler:", ^{
            beforeEach(^{
                delegate reject_method("URLSession:dataTask:didReceiveResponse:completionHandler:");
            });

            it(@"should not try to notify the delegate", ^{
                delegate should_not have_received("URLSession:dataTask:didReceiveResponse:completionHandler:");
            });
        });
    });

    describe(@"-receiveData:", ^{
        __block NSData *data;

        subjectAction(^{ [task receiveData:data]; });

        beforeEach(^{
            data = [NSData data];
        });

        it(@"should not remove the task from the session's list of tasks", ^{
            session.dataTasks should contain(task);
        });

        context(@"when the delegate implements -URLSession:dataTask:didReceiveData:", ^{
            beforeEach(^{
                delegate stub_method("URLSession:dataTask:didReceiveData:");
            });

            it(@"should notify the delegate", ^{
                delegate should have_received("URLSession:dataTask:didReceiveData:").with(session, task, data);
            });
        });

        context(@"when the delegate does not implement -URLSession:dataTask:didReceiveData:", ^{
            beforeEach(^{
                delegate reject_method("URLSession:dataTask:didReceiveData:");
            });

            it(@"should not try to notify the delegate", ^{
                delegate should_not have_received("URLSession:dataTask:didReceiveData:");
            });
        });

        context(@"when the task has previously received a response", ^{
            __block NSURLResponse<CedarDouble> *response;

            beforeEach(^{
                response = fake_for([NSURLResponse class]);
                [task receiveResponse:response];
            });

            it(@"should not change the task's response property", ^{
                task.response should equal(response);
            });
        });

        context(@"when the task has not previously received a response", ^{
            it(@"should assign a default, successful response to the task's response property", ^{
                id response = task.response;
                [response statusCode] should equal(200);
            });
        });
    });

    describe(@"completeWithError:", ^{
        __block NSError *error;

        subjectAction(^{ [task completeWithError:error]; });

        beforeEach(^{
            error = fake_for([NSError class]);
        });

        it(@"should remove the task from the session's list of tasks", ^{
            session.dataTasks should_not contain(task);
        });

        context(@"when the delegate implements -URLSession:task:didCompleteWithError:", ^{
            beforeEach(^{
                delegate stub_method("URLSession:task:didCompleteWithError:");
            });

            it(@"should notify the delegate", ^{
                delegate should have_received("URLSession:task:didCompleteWithError:").with(session, task, error);
            });
        });

        context(@"when the delegate does not implement -URLSession:task:didCompleteWithError:", ^{
            beforeEach(^{
                delegate reject_method("URLSession:task:didCompleteWithError:");
            });

            it(@"should not try to notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didCompleteWithError:");
            });
        });

        context(@"when the task has previously received a response", ^{
            __block NSURLResponse<CedarDouble> *response;

            beforeEach(^{
                response = fake_for([NSURLResponse class]);
                [task receiveResponse:response];
            });

            it(@"should not change the task's response property", ^{
                task.response should equal(response);
            });
        });

        context(@"when the task has not previously received a response", ^{
            it(@"should assign a default, successful response to the task's response property", ^{
                id response = task.response;
                [response statusCode] should equal(200);
            });
        });
    });

    describe(@"-completeWithResponse:data:error:", ^{
        __block NSURLResponse *response;
        __block NSData *data;
        __block NSError *error;

        subjectAction(^{ [task completeWithResponse:response data:data error:error]; });

        beforeEach(^{
            response = fake_for([NSURLResponse class]);
            data = fake_for([NSData class]);
            error = fake_for([NSError class]);
        });

        it(@"should assign the response", ^{
            task.response should equal(response);
        });

        context(@"with data", ^{
            beforeEach(^{
                data should_not be_nil;
            });

            it(@"should should notify the delegate", ^{
                delegate should have_received("URLSession:dataTask:didReceiveResponse:completionHandler:").with(session, task, response, Arguments::anything);
                delegate should have_received("URLSession:dataTask:didReceiveData:").with(session, task, data);
                delegate should have_received("URLSession:task:didCompleteWithError:").with(session, task, error);
            });
        });

        context(@"without data", ^{
            beforeEach(^{
                data = nil;
            });

            it(@"should should notify the delegate", ^{
                delegate should have_received("URLSession:dataTask:didReceiveResponse:completionHandler:").with(session, task, response, Arguments::anything);
                delegate should_not have_received("URLSession:dataTask:didReceiveData:");
                delegate should have_received("URLSession:task:didCompleteWithError:").with(session, task, error);
            });
        });
    });

    describe(@"-receiveAuthenticationChallenge:", ^{
        __block NSURLAuthenticationChallenge *challenge;

        subjectAction(^{ [task receiveAuthenticationChallenge:challenge]; });

        beforeEach(^{
            challenge = fake_for([NSURLAuthenticationChallenge class]);
        });

        it(@"should not call the delegate method for session-level authentication", ^{
            delegate should_not have_received("URLSession:didReceiveChallenge:completionHandler:");
        });

        context(@"when the delegate implements -URLSession:task:didReceiveChallenge:completionHandler:", ^{
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeUseCredential;
            NSURLCredential *credential = fake_for([NSURLCredential class]);

            beforeEach(^{
                delegate stub_method("URLSession:task:didReceiveChallenge:completionHandler:").and_do(^(NSInvocation *invocation) {
                    void (^completionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential *);
                    [invocation getArgument:&completionHandler atIndex:5];

                    completionHandler(disposition, credential);
                });
            });

            it(@"should notify the delegate", ^{
                delegate should have_received("URLSession:task:didReceiveChallenge:completionHandler:").with(session, task, challenge, Arguments::anything);
            });

            it(@"should record the delegate's response to the challenge", ^{
                task.authenticationChallengeResponses should_not be_empty;
                [task.authenticationChallengeResponses.firstObject disposition] should equal(disposition);
                [task.authenticationChallengeResponses.firstObject credential] should equal(credential);
            });
        });

        context(@"when the delegate does not implement -URLSession:task:didReceiveChallenge:completionHandler:", ^{
            beforeEach(^{
                delegate reject_method("URLSession:task:didReceiveChallenge:completionHandler:");
            });

            it(@"should not try to notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didReceiveChallenge:completionHandler:");
            });
        });
    });
});

SPEC_END
