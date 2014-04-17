#import "NSURLRequest+Spec.h"
#import "objc/runtime.h"

#pragma mark - NSURLRequest+Spec
@implementation NSURLRequest (Spec)

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self.mutableHeaderFields setObject:value forKey:field];
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    return self.allHTTPHeaderFields[field];
}

static const char ALL_HTTP_HEADER_FIELDS_ASSOC_KEY;
- (NSDictionary *)allHTTPHeaderFields {
    return objc_getAssociatedObject(self, &ALL_HTTP_HEADER_FIELDS_ASSOC_KEY);
}

#pragma mark Private interface

- (NSMutableDictionary *)mutableHeaderFields {
    NSMutableDictionary *fields = objc_getAssociatedObject(self, &ALL_HTTP_HEADER_FIELDS_ASSOC_KEY);
    if (!fields) {
        fields = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &ALL_HTTP_HEADER_FIELDS_ASSOC_KEY, fields, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return fields;
}

@end


#pragma mark - NSMutableURLRequest+Spec
@implementation NSMutableURLRequest (Spec)

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    NSString *oldValue = [self valueForHTTPHeaderField:field];
    if (oldValue) {
        value = [NSString stringWithFormat:@"%@,%@", oldValue, value];
    }
    [self setValue:value forHTTPHeaderField:field];
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [super setValue:value forHTTPHeaderField:field];
}

- (void)setAllHTTPHeaderFields:(NSDictionary *)fields {
    [self.mutableHeaderFields setDictionary:fields];
}

@end
