//
//  UTF8StreamAssembler.m
//  OnDeviceSummary
//

#import "UTF8StreamAssembler.h"

// UTF-8 は 1 文字最大 4 バイトなので、末尾に持ち越す未完成シーケンスは最大 3 バイト。
static const NSUInteger kMaxPendingTailLength = 3;

@implementation UTF8StreamAssembler {
    NSMutableData *_buffer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _buffer = [NSMutableData data];
    }
    return self;
}

- (nullable NSString *)consume:(NSData *)data {
    [_buffer appendData:data];
    return [self drainKeepingPartialTail:YES];
}

- (nullable NSString *)flush {
    NSString *rest = [self drainKeepingPartialTail:NO];
    [_buffer setLength:0];
    return rest;
}

/// バッファ先頭から UTF-8 として正しく復元できる最長部分を切り出す。
/// keepPartialTail が YES のときは、末尾最大 3 バイトをマルチバイト文字の
/// 形成途中とみなして次回の consume に持ち越す。それ以上の復元不能バイトは
/// 1 バイトずつ捨てて再同期する（不正バイトでストリームが詰まるのを防ぐ）。
- (nullable NSString *)drainKeepingPartialTail:(BOOL)keepPartialTail {
    NSMutableString *output = [NSMutableString string];

    while (_buffer.length > 0) {
        NSString *decoded = nil;
        NSUInteger decodedLength = _buffer.length;
        while (decodedLength > 0) {
            decoded = [[NSString alloc] initWithBytes:_buffer.bytes
                                               length:decodedLength
                                             encoding:NSUTF8StringEncoding];
            if (decoded) {
                break;
            }
            decodedLength--;
        }

        if (decoded && decodedLength > 0) {
            [output appendString:decoded];
            [_buffer replaceBytesInRange:NSMakeRange(0, decodedLength) withBytes:NULL length:0];
        }

        if (_buffer.length == 0) {
            break;
        }
        if (keepPartialTail && _buffer.length <= kMaxPendingTailLength) {
            break;
        }

        // 4 バイト以上残って復元できないなら形成途中の 1 文字ではあり得ない。
        // 先頭 1 バイトを捨てて再同期する。
        [_buffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
    }

    return output.length > 0 ? output : nil;
}

@end
