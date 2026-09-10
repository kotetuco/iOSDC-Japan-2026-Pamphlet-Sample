//
//  UTF8StreamAssembler.h
//  OnDeviceSummary
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// トークン単位で分割されて届く UTF-8 バイト列を復元するアセンブラ。
/// ExecuTorch のトークンコールバックは 1 トークン分のバイト列を渡してくるが、
/// 日本語などのマルチバイト文字はトークン境界で分割されることがあるため、
/// 完成した文字列部分だけを切り出し、末尾の不完全なシーケンスは次回へ持ち越す。
@interface UTF8StreamAssembler : NSObject

/// バイト列を蓄積し、UTF-8 として完成している先頭部分を返す（未完成なら nil）。
- (nullable NSString *)consume:(NSData *)data;

/// 生成終了時に呼ぶ。復元できる残りを返し、不完全な末尾バイトは破棄する。
- (nullable NSString *)flush;

@end

NS_ASSUME_NONNULL_END
