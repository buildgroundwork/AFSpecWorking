#import <Foundation/Foundation.h>

@interface NSURLRequest (Spec)

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end
