//
//  UTF8SafeTextRunner.h
//  OnDeviceSummary
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// ExecuTorch v1.3.1 の ObjC ラッパー（ExecuTorchLLMTextRunner）の置き換え。
///
/// 上流実装はトークンごとに `@(token.c_str())` で NSString 変換するため、
/// トークン境界で分割されたマルチバイト文字（日本語など）が欠落する。
/// 本クラスは同じ C++ ランナー（llm::TextLLMRunner）を直接呼び出し、
/// UTF8StreamAssembler で完成した文字列だけをコールバックへ渡す。
///
/// ビルドには third_party/executorch の C++ ヘッダが必要
/// （scripts/fetch_executorch_headers.sh で取得）。未取得の場合は
/// ビルド可能なスタブになり、実行時にエラーを返す。
NS_SWIFT_NAME(UTF8SafeTextRunner)
@interface ODSUTF8SafeTextRunner : NSObject

- (instancetype)initWithModelPath:(NSString *)modelPath
                    tokenizerPath:(NSString *)tokenizerPath
                    specialTokens:(NSArray<NSString *> *)specialTokens
    NS_DESIGNATED_INITIALIZER;

- (BOOL)isLoaded;

- (BOOL)loadWithError:(NSError **)error;

- (BOOL)generateWithPrompt:(NSString *)prompt
            sequenceLength:(NSInteger)sequenceLength
          maximumNewTokens:(NSInteger)maximumNewTokens
               temperature:(double)temperature
               echoEnabled:(BOOL)echoEnabled
             tokenCallback:(nullable void (^)(NSString *token))callback
                     error:(NSError **)error
    NS_SWIFT_NAME(generate(_:sequenceLength:maximumNewTokens:temperature:echoEnabled:tokenCallback:));

- (void)stop;

- (void)reset;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
