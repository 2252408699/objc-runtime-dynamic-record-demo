#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>

static uint8_t AlignmentExponent(size_t alignment) {
    uint8_t exponent = 0;
    while (((size_t)1 << exponent) < alignment) {
        exponent++;
    }
    return exponent;
}

static id GetObjectIvar(id self, SEL _cmd) {
    NSString *propertyName = NSStringFromSelector(_cmd);
    NSString *ivarName = [@"_" stringByAppendingString:propertyName];
    Ivar ivar = class_getInstanceVariable(object_getClass(self), ivarName.UTF8String);
    return ivar ? object_getIvar(self, ivar) : nil;
}

static void SetObjectIvar(id self, SEL _cmd, id value) {
    NSString *selectorName = NSStringFromSelector(_cmd);
    NSString *body = [selectorName substringWithRange:NSMakeRange(3, selectorName.length - 4)];
    NSString *propertyName = [[[body substringToIndex:1] lowercaseString]
                              stringByAppendingString:[body substringFromIndex:1]];
    NSString *ivarName = [@"_" stringByAppendingString:propertyName];
    Ivar ivar = class_getInstanceVariable(object_getClass(self), ivarName.UTF8String);
    if (ivar) object_setIvar(self, ivar, value);
}

static NSString *RecordSummary(id self, SEL _cmd) {
    (void)_cmd;
    return [NSString stringWithFormat:@"Runtime record: name=%@, age=%@",
            [self valueForKey:@"name"],
            [self valueForKey:@"age"]];
}

static BOOL AddObjectProperty(Class cls,
                              const char *name,
                              const char *ivarName,
                              const char *objectType,
                              SEL getter,
                              SEL setter) {
    BOOL ivarAdded = class_addIvar(cls,
                                  ivarName,
                                  sizeof(id),
                                  AlignmentExponent(_Alignof(id)),
                                  "@");

    objc_property_attribute_t attributes[] = {
        {"T", objectType},
        {"&", ""},
        {"N", ""},
        {"V", ivarName}
    };
    BOOL propertyAdded = class_addProperty(cls, name, attributes, 4);
    BOOL getterAdded = class_addMethod(cls, getter, (IMP)GetObjectIvar, "@@:");
    BOOL setterAdded = class_addMethod(cls, setter, (IMP)SetObjectIvar, "v@:@");

    return ivarAdded && propertyAdded && getterAdded && setterAdded;
}

static Class CreateRuntimeRecordClass(void) {
    const char *className = "RuntimeUserRecordDemo";
    Class existing = objc_getClass(className);
    if (existing) return existing;

    Class cls = objc_allocateClassPair([NSObject class], className, 0);
    if (!cls) return Nil;

    BOOL nameOK = AddObjectProperty(cls,
                                    "name",
                                    "_name",
                                    "@\"NSString\"",
                                    @selector(name),
                                    @selector(setName:));
    BOOL ageOK = AddObjectProperty(cls,
                                   "age",
                                   "_age",
                                   "@\"NSNumber\"",
                                   @selector(age),
                                   @selector(setAge:));
    BOOL summaryOK = class_addMethod(cls,
                                     @selector(recordSummary),
                                     (IMP)RecordSummary,
                                     "@@:");

    if (!(nameOK && ageOK && summaryOK)) {
        objc_disposeClassPair(cls);
        return Nil;
    }

    objc_registerClassPair(cls);
    return cls;
}

int main(void) {
    @autoreleasepool {
        Class recordClass = CreateRuntimeRecordClass();
        NSCAssert(recordClass != Nil, @"Dynamic class creation failed");

        id record = [[recordClass alloc] init];

        void (*sendObject)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
        id (*sendReturnObject)(id, SEL) = (id (*)(id, SEL))objc_msgSend;

        sendObject(record, @selector(setName:), @"Avery");
        [record setValue:@42 forKey:@"age"];

        NSLog(@"name via KVC = %@", [record valueForKey:@"name"]);
        NSLog(@"age via runtime getter = %@", sendReturnObject(record, @selector(age)));
        NSLog(@"%@", sendReturnObject(record, @selector(recordSummary)));

        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(recordClass, &count);
        for (unsigned int index = 0; index < count; index++) {
            NSLog(@"property[%u] %s attributes=%s",
                  index,
                  property_getName(properties[index]),
                  property_getAttributes(properties[index]));
        }
        free(properties);
    }
    return 0;
}
