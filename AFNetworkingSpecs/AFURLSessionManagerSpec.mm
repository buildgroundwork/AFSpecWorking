#import "AFURLSessionManager.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AFURLSessionManagerSpec)

describe(@"AFURLSessionManager", ^{
    __block AFURLSessionManager *manager;
    __block NSURLSessionConfiguration *configuration;
    __block NSURLRequest *request;

    beforeEach(^{
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

        spy_on(manager.session);

        NSURL *url = [NSURL URLWithString:@"http://www.example.com"];
        request = [NSURLRequest requestWithURL:url];
    });

    describe(@"-session", ^{
        it(@"should not be nil", ^{
            manager.session should_not be_nil;
        });
    });

    describe(@"-tasks", ^{
        it(@"should include data tasks, download task, and upload tasks", PENDING);
    });

    describe(@"-dataTaskWithRequest:completionHandler:", ^{
        __block NSURLSessionTask *newTask, *fakeTask;

        subjectAction(^{ newTask = [manager dataTaskWithRequest:request completionHandler:nil]; });

        beforeEach(^{
            fakeTask = nice_fake_for([NSURLSessionTask class]);
            manager.session stub_method("dataTaskWithRequest:").and_return(fakeTask);
        });

        afterEach(^{
            // For the moment, clean up the KVO that the manager object applies to the
            // task on creation.
            [fakeTask removeObserver:manager forKeyPath:@"state"];
        });

        it(@"should ask the session to create a data task", ^{
            manager.session should have_received("dataTaskWithRequest:").with(request);
        });

        it(@"should return the task created by the session", ^{
            newTask should equal(fakeTask);
        });
    });

    describe(@"-invalidateSessionCancelingTasks:", ^{
        __block BOOL cancelTasks;

        subjectAction(^{ [manager invalidateSessionCancelingTasks:cancelTasks]; });

        context(@"when canceling tasks", ^{
            beforeEach(^{
                cancelTasks = YES;
            });

            it(@"should invoke -invalidateAndCancel on the session", ^{
                manager.session should have_received("invalidateAndCancel");
            });
        });

        context(@"when not canceling tasks", ^{
            beforeEach(^{
                cancelTasks = NO;
            });

            it(@"should invoke -finishTasksAndInvalidate on the session", ^{
                manager.session should have_received("finishTasksAndInvalidate");
            });
        });
    });
});

SPEC_END

