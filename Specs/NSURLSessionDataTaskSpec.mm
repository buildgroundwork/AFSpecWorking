#import "AFSpecWorking/SpecHelpers.h"
#import "SingleTrack/SpecHelpers.h"

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

    describe(@"on initialization", ^{
        it(@"should set the state to NSURLSessionTaskStateSuspended", ^{
            task.state should equal(NSURLSessionTaskStateSuspended);
        });
    });

    describe(@"-taskIdentifier", ^{
        __block NSURLSessionTask *otherTask;

        beforeEach(^{
            NSURLRequest *otherRequest = fake_for([NSURLRequest class]);
            otherTask = [session dataTaskWithRequest:otherRequest];
        });

        it(@"should be unique for tasks in the session", ^{
            task.taskIdentifier should_not equal(otherTask.taskIdentifier);
        });
    });

    describe(@"-resume", ^{
        subjectAction(^{ [task resume]; });

        context(@"when the task is suspended", ^{
            beforeEach(^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should change the state of the task to NSURLSessionTaskStateRunning", ^{
                task.state should equal(NSURLSessionTaskStateRunning);
            });
        });

        context(@"when the task is running", ^{
            beforeEach(^{
                [task resume];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateRunning);
            });
        });

        context(@"when the task is canceled", ^{
            beforeEach(^{
                [task cancel];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });
        });
    });

    describe(@"-suspend", ^{
        subjectAction(^{ [task suspend]; });

        context(@"when the task is suspended", ^{
            beforeEach(^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });
        });

        context(@"when the task is running", ^{
            beforeEach(^{
                [task resume];
            });

            it(@"should change the state of the task to NSURLSessionTaskStateSuspended", ^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            context(@"when the task has received a response", ^{
                __block NSURLResponse *response;

                beforeEach(^{
                    response = fake_for([NSURLResponse class]);
                    [task receiveResponse:response];
                });

                it(@"should reset the response", ^{
                    [task completeWithError:nil];
                    task.response should_not be_same_instance_as(response);
                });
            });
        });

        context(@"when the task is completed", ^{
            beforeEach(^{
                [task cancel];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });
        });
    });

    describe(@"-cancel", ^{
        subjectAction(^{ [task cancel]; });

        context(@"when the task is running", ^{
            beforeEach(^{
                [task resume];
            });

            it(@"should remove the task from the session's list of tasks", ^{
                session.dataTasks should_not contain(task);
            });

            it(@"should change the state of the task to NSURLSessionTaskStateCompleted", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
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

        context(@"when the task is complete", ^{
            beforeEach(^{
                [task cancel];
                [delegate reset_sent_messages];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didCompleteWithError:");
            });
        });
    });

    describe(@"-receiveResponse:", ^{
        __block NSURLResponse *response;

        subjectAction(^{ [task receiveResponse:response]; });

        context(@"when running", ^{
            beforeEach(^{
                [task resume];
                delegate stub_method("URLSession:dataTask:didReceiveResponse:completionHandler:");
            });

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

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateRunning);
            });

            context(@"when the delegate implements -URLSession:dataTask:didReceiveResponse:completionHandler:", ^{
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

        context(@"when suspended", ^{
            beforeEach(^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:dataTask:didReceiveResponse:completionHandler:");
            });
        });

        context(@"when complete", ^{
            beforeEach(^{
                [task cancel];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });

            it(@"should not notify the delegate", ^{
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

        context(@"when running", ^{
            beforeEach(^{
                [task resume];
                delegate stub_method("URLSession:dataTask:didReceiveData:");
            });

            it(@"should not remove the task from the session's list of tasks", ^{
                session.dataTasks should contain(task);
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateRunning);
            });

            context(@"when the delegate implements -URLSession:dataTask:didReceiveData:", ^{
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

        context(@"when suspended", ^{
            beforeEach(^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:dataTask:didReceiveData:");
            });
        });

        context(@"when complete", ^{
            beforeEach(^{
                [task cancel];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:dataTask:didReceiveData:");
            });
        });
    });

    describe(@"completeWithError:", ^{
        __block NSError *error;

        subjectAction(^{ [task completeWithError:error]; });

        beforeEach(^{
            error = fake_for([NSError class]);
        });

        context(@"when running", ^{
            beforeEach(^{
                [task resume];
                delegate stub_method("URLSession:task:didCompleteWithError:");
            });

            it(@"should remove the task from the session's list of tasks", ^{
                session.dataTasks should_not contain(task);
            });

            it(@"should change the state of the task to NSURLSessionTaskStateCompleted", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });

            context(@"when the delegate implements -URLSession:task:didCompleteWithError:", ^{
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

        context(@"when suspended", ^{
            beforeEach(^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didCompleteWithError:");
            });
        });

        context(@"when complete", ^{
            beforeEach(^{
                [task cancel];
                [delegate reset_sent_messages];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didCompleteWithError:");
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

        context(@"when running", ^{
            beforeEach(^{
                [task resume];
            });

            it(@"should assign the response", ^{
                task.response should equal(response);
            });

            it(@"should change the state of the task to NSURLSessionTaskStateCompleted", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
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

        context(@"when suspended", ^{
            beforeEach(^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not notify the delegate", ^{
                [delegate sent_messages] should be_empty;
            });
        });

        context(@"when complete", ^{
            beforeEach(^{
                [task cancel];
                [delegate reset_sent_messages];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });

            it(@"should not notify the delegate", ^{
                [delegate sent_messages] should be_empty;
            });
        });
    });

    describe(@"-receiveAuthenticationChallenge:", ^{
        __block NSURLAuthenticationChallenge *challenge;

        subjectAction(^{ [task receiveAuthenticationChallenge:challenge]; });

        beforeEach(^{
            challenge = fake_for([NSURLAuthenticationChallenge class]);
        });

        context(@"when running", ^{
            beforeEach(^{
                [task resume];
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

        context(@"when suspended", ^{
            beforeEach(^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateSuspended);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didReceiveChallenge:completionHandler:");
            });
        });

        context(@"when complete", ^{
            beforeEach(^{
                [task cancel];
            });

            it(@"should not change the state of the task", ^{
                task.state should equal(NSURLSessionTaskStateCompleted);
            });

            it(@"should not notify the delegate", ^{
                delegate should_not have_received("URLSession:task:didReceiveChallenge:completionHandler:");
            });
        });
    });
});

SPEC_END
