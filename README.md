# Objective-C Runtime Dynamic Record Demo

A runnable macOS command-line project that creates a class at runtime from a small server-style schema.

The demo adds object ivars, property metadata, getters, setters, and a summary method before registering the class. It then assigns values through both normal Objective-C messaging and Key-Value Coding (KVC), and inspects the registered properties.

## Requirements

- macOS
- Xcode or Xcode Command Line Tools

```bash
xcode-select --install
```

## Download and run

```bash
git clone https://github.com/2252408699/objc-runtime-dynamic-record-demo.git
cd objc-runtime-dynamic-record-demo
make run
```

## Why the demo uses object-backed fields

Both `name` and `age` use Objective-C object storage (`NSString *` and `NSNumber *`). This keeps the runtime accessors type-correct and avoids pretending that a 64-bit `NSInteger` uses the 32-bit `i` encoding.

## References

- Apple Objective-C Runtime documentation: https://developer.apple.com/documentation/objectivec/objective-c-runtime
- Apple Key-Value Coding guide: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/index.html

## Clean

```bash
make clean
```
