#import "NSURLRequest+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(NSURLRequestSpec)

describe(@"NSURLRequest", ^{
    __block NSURLRequest *request;

    beforeEach(^{
        NSURL *url = [NSURL URLWithString:@"/"];
        request = [NSURLRequest requestWithURL:url];
    });

    describe(@"-setValue:forHTTPHeaderField:", ^{
        NSString *value = @"application/wibble", *header = @"X-Silly-Content-Type";

        subjectAction(^{ [request setValue:value forHTTPHeaderField:header]; });

        it(@"should add the header", ^{
            [request valueForHTTPHeaderField:header] should equal(value);
        });
    });
});

describe(@"NSMutableRequest", ^{
    __block NSMutableURLRequest *request;

    beforeEach(^{
        NSURL *url = [NSURL URLWithString:@"/"];
        request = [NSMutableURLRequest requestWithURL:url];
    });

    describe(@"-addValue:forHTTPHeaderField:", ^{
        NSString *value = @"application/wibble", *header = @"X-Silly-Content-Type";

        subjectAction(^{ [request addValue:value forHTTPHeaderField:header]; });

        context(@"when the request already has a header with that value", ^{
            NSString *oldValue = @"old/value";

            beforeEach(^{
                [request addValue:oldValue forHTTPHeaderField:header];
            });

            it(@"should append the new value to the old value", ^{
                [request valueForHTTPHeaderField:header] should equal([NSString stringWithFormat:@"%@,%@", oldValue, value]);
            });
        });

        context(@"when the request does not have a header with that value", ^{
            beforeEach(^{
                [request valueForHTTPHeaderField:header] should be_nil;
            });

            it(@"should add the header", ^{
                [request valueForHTTPHeaderField:header] should equal(value);
            });
        });
    });

    describe(@"-setValue:forHTTPHeaderField:", ^{
        NSString *value = @"application/foobar", *header = @"X-Silly-Content-Type";

        subjectAction(^{ [request setValue:value forHTTPHeaderField:header]; });

        context(@"when the request already has a header with that value", ^{
            beforeEach(^{
                [request addValue:@"something/else" forHTTPHeaderField:header];
            });

            it(@"should update the header value", ^{
                [request valueForHTTPHeaderField:header] should equal(value);
            });
        });

        context(@"when the request does not have a header with that value", ^{
            beforeEach(^{
                [request valueForHTTPHeaderField:header] should be_nil;
            });

            it(@"should add the header", ^{
                [request valueForHTTPHeaderField:header] should equal(value);
            });
        });
    });

    describe(@"-setAllHTTPHeaderFields:", ^{
        NSDictionary *fields = @{ @"Content-Type": @"application/wibbleml" };

        subjectAction(^{ [request setAllHTTPHeaderFields:fields]; });

        context(@"with no previously set headers", ^{
            beforeEach(^{
                request.allHTTPHeaderFields should be_empty;
            });

            it(@"should add all the specified headers", ^{
                request.allHTTPHeaderFields should equal(fields);
            });
        });

        context(@"with previously set headers", ^{
            beforeEach(^{
                [request setValue:@"application/foobarml" forHTTPHeaderField:@"Content-Type"];
            });

            it(@"should replace the headers", ^{
                request.allHTTPHeaderFields should equal(fields);
            });
        });
    });
});

SPEC_END
