#import "NSURLSession+Spec.h"
#import "NSURLSessionDataTask+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(NSURLSessionSpec)

describe(@"NSURLSession", ^{
    __block NSURLSession *session;
    __block id<NSURLSessionDelegate> delegate;
    __block NSURLRequest *request;

    beforeEach(^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        delegate = fake_for(@protocol(NSURLSessionDelegate));
        session = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];

        request = fake_for([NSURLRequest class]);
    });

    describe(@"-dataTaskWithRequest:", ^{
        subjectAction(^{ [session dataTaskWithRequest:request]; });

        it(@"should create a data task for the request", ^{
            session.tasks should_not be_empty;
        });

        it(@"should associate the data task with the specified request", ^{
            NSURLSessionTask *task = session.dataTasks[0];
            task.originalRequest should equal(request);
        });
    });

    describe(@"-invalidateAndCancel", ^{
        subjectAction(^{ [session invalidateAndCancel]; });

        it(@"should prevent the session from creating new tasks", ^{
            ^{ [session dataTaskWithRequest:request]; } should raise_exception;
        });

        context(@"with active tasks", ^{
            beforeEach(^{
                [session dataTaskWithRequest:request];
            });

            it(@"should cancel all pending tasks", ^{
                session.tasks should be_empty;
            });
        });

        context(@"when the delegate implements the -URLSession:didBecomeInvalidWithError: method", ^{
            beforeEach(^{
                delegate stub_method("URLSession:didBecomeInvalidWithError:");
            });

            it(@"should notify the delegate, with no error", ^{
                delegate should have_received("URLSession:didBecomeInvalidWithError:").with(session, nil);
            });
        });

        context(@"when the delegate does not implement the -URLSession:didBecomeInvalidWithError: method", ^{
            beforeEach(^{
                delegate reject_method("URLSession:didBecomeInvalidWithError:");
            });

            it(@"should not try to notify the delegate", ^{
                delegate should_not have_received("URLSession:didBecomeInvalidWithError:");
            });
        });
    });

    describe(@"-finishTasksAndInvalidate", ^{
        subjectAction(^{ [session finishTasksAndInvalidate]; });

        it(@"should prevent the session from creating new tasks", ^{
            ^{ [session dataTaskWithRequest:request]; } should raise_exception;
        });

        context(@"with an active task", ^{
            __block NSURLSessionTask *task;

            beforeEach(^{
                task = [session dataTaskWithRequest:request];
            });

            it(@"should not cancel pending tasks", ^{
                session.tasks should contain(task);
            });

            context(@"when the delegate implements the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate stub_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should not notify the delegate (yet)", ^{
                    delegate should_not have_received("URLSession:didBecomeInvalidWithError:");
                });
            });

            context(@"when the delegate does not implement the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate reject_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should not try to notify the delegate", ^{
                    delegate should_not have_received("URLSession:didBecomeInvalidWithError:");
                });
            });
        });

        context(@"with no active tasks", ^{
            beforeEach(^{
                session.tasks should be_empty;
            });

            context(@"when the delegate implements the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate stub_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should notify the delegate, with no error", ^{
                    delegate should have_received("URLSession:didBecomeInvalidWithError:").with(session, nil);
                });
            });

            context(@"when the delegate does not implement the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate reject_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should not try to notify the delegate", ^{
                    delegate should_not have_received("URLSession:didBecomeInvalidWithError:");
                });
            });
        });
    });

    context(@"when invalidated with an active task", ^{
        __block NSURLSessionDataTask *task;

        beforeEach(^{
            request stub_method("URL").and_return([NSURL URLWithString:@"/"]);

            task = [session dataTaskWithRequest:request];
            [task resume];
            [session finishTasksAndInvalidate];
        });

        describe(@"when the task completes", ^{
            subjectAction(^{ [task completeWithError:nil]; });

            context(@"when the delegate implements the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate stub_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should notify the delegate, with no error", ^{
                    delegate should have_received("URLSession:didBecomeInvalidWithError:").with(session, nil);
                });
            });

            context(@"when the delegate does not implement the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate reject_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should not try to notify the delegate", ^{
                    delegate should_not have_received("URLSession:didBecomeInvalidWithError:");
                });
            });
        });

        describe(@"when the task is canceled", ^{
            subjectAction(^{ [task cancel]; });

            context(@"when the delegate implements the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate stub_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should notify the delegate, with no error", ^{
                    delegate should have_received("URLSession:didBecomeInvalidWithError:").with(session, nil);
                });
            });

            context(@"when the delegate does not implement the -URLSession:didBecomeInvalidWithError: method", ^{
                beforeEach(^{
                    delegate reject_method("URLSession:didBecomeInvalidWithError:");
                });

                it(@"should not try to notify the delegate", ^{
                    delegate should_not have_received("URLSession:didBecomeInvalidWithError:");
                });
            });
        });
    });
});

SPEC_END
