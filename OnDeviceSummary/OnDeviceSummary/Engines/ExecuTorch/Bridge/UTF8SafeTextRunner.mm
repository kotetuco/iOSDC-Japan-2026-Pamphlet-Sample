//
//  UTF8SafeTextRunner.mm
//  OnDeviceSummary
//
//  executorch v1.3.1 の extension/llm/apple/ExecuTorchLLM/Exported/
//  ExecuTorchLLMTextRunner.mm を土台に、トークンコールバックへ渡す前に
//  UTF8StreamAssembler でバイト列を復元する修正を加えた移植版。
//

#import "UTF8SafeTextRunner.h"

#import "UTF8StreamAssembler.h"

#if __has_include(<executorch/extension/llm/runner/text_llm_runner.h>)
#define ODS_HAS_EXECUTORCH_LLM_HEADERS 1
#import <executorch/extension/llm/runner/text_llm_runner.h>
#endif

static NSString *const ODSUTF8SafeTextRunnerErrorDomain = @"UTF8SafeTextRunner";

#if ODS_HAS_EXECUTORCH_LLM_HEADERS

using namespace executorch::extension;
using namespace executorch::runtime;

@implementation ODSUTF8SafeTextRunner {
  NSString *_modelPath;
  NSString *_tokenizerPath;
  std::unique_ptr<std::vector<std::string>> _specialTokens;
  std::unique_ptr<llm::TextLLMRunner> _runner;
}

- (instancetype)initWithModelPath:(NSString *)modelPath
                    tokenizerPath:(NSString *)tokenizerPath
                    specialTokens:(NSArray<NSString *> *)specialTokens {
  self = [super init];
  if (self) {
    _modelPath = [modelPath copy];
    _tokenizerPath = [tokenizerPath copy];
    _specialTokens = std::make_unique<std::vector<std::string>>();
    for (NSString *token in specialTokens) {
      _specialTokens->emplace_back(token.UTF8String);
    }
  }
  return self;
}

- (BOOL)isLoaded {
  return _runner && _runner->is_loaded();
}

- (BOOL)loadWithError:(NSError **)error {
  if (![self isLoaded]) {
    _runner = llm::create_text_llm_runner(
      _modelPath.UTF8String,
      llm::load_tokenizer(_tokenizerPath.UTF8String, std::move(_specialTokens))
    );
    if (!_runner) {
      if (error) {
        *error = [NSError errorWithDomain:ODSUTF8SafeTextRunnerErrorDomain
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create runner"}];
      }
      return NO;
    }
  }
  auto status = _runner->load();
  if (status != Error::Ok) {
    if (error) {
      *error = [NSError errorWithDomain:ODSUTF8SafeTextRunnerErrorDomain
                                   code:(NSInteger)status
                               userInfo:nil];
    }
    return NO;
  }
  return YES;
}

- (BOOL)generateWithPrompt:(NSString *)prompt
            sequenceLength:(NSInteger)sequenceLength
          maximumNewTokens:(NSInteger)maximumNewTokens
               temperature:(double)temperature
               echoEnabled:(BOOL)echoEnabled
             tokenCallback:(nullable void (^)(NSString *token))callback
                     error:(NSError **)error {
  if (![self loadWithError:error]) {
    return NO;
  }
  llm::GenerationConfig config;
  config.echo = echoEnabled;
  config.max_new_tokens = (int32_t)maximumNewTokens;
  config.seq_len = (int32_t)sequenceLength;
  config.temperature = (float)temperature;

  UTF8StreamAssembler *assembler = [[UTF8StreamAssembler alloc] init];
  auto status = _runner->generate(
    prompt.UTF8String,
    config,
    [callback, assembler](const std::string& token) {
      if (!callback) {
        return;
      }
      NSData *bytes = [NSData dataWithBytes:token.data() length:token.size()];
      NSString *piece = [assembler consume:bytes];
      if (piece.length > 0) {
        callback(piece);
      }
    }
  );
  NSString *rest = [assembler flush];
  if (callback && rest.length > 0) {
    callback(rest);
  }
  if (status != Error::Ok) {
    if (error) {
      *error = [NSError errorWithDomain:ODSUTF8SafeTextRunnerErrorDomain
                                   code:(NSInteger)status
                               userInfo:nil];
    }
    return NO;
  }
  return YES;
}

- (void)stop {
  if (_runner) {
    _runner->stop();
  }
}

- (void)reset {
  if (_runner) {
    _runner->reset();
  }
}

@end

#else // !ODS_HAS_EXECUTORCH_LLM_HEADERS

// C++ ヘッダ未取得でもビルドを通すためのスタブ。実行時にエラーを返す。
static NSError *ODSMissingHeadersError(void) {
  return [NSError errorWithDomain:ODSUTF8SafeTextRunnerErrorDomain
                             code:-2
                         userInfo:@{
    NSLocalizedDescriptionKey:
        @"ExecuTorch の C++ ヘッダが見つかりません。samples/OnDeviceSummary/"
        @"scripts/fetch_executorch_headers.sh を実行して再ビルドしてください。"
  }];
}

@implementation ODSUTF8SafeTextRunner

- (instancetype)initWithModelPath:(NSString *)modelPath
                    tokenizerPath:(NSString *)tokenizerPath
                    specialTokens:(NSArray<NSString *> *)specialTokens {
  return [super init];
}

- (BOOL)isLoaded {
  return NO;
}

- (BOOL)loadWithError:(NSError **)error {
  if (error) {
    *error = ODSMissingHeadersError();
  }
  return NO;
}

- (BOOL)generateWithPrompt:(NSString *)prompt
            sequenceLength:(NSInteger)sequenceLength
          maximumNewTokens:(NSInteger)maximumNewTokens
               temperature:(double)temperature
               echoEnabled:(BOOL)echoEnabled
             tokenCallback:(nullable void (^)(NSString *token))callback
                     error:(NSError **)error {
  if (error) {
    *error = ODSMissingHeadersError();
  }
  return NO;
}

- (void)stop {
}

- (void)reset {
}

@end

#endif // ODS_HAS_EXECUTORCH_LLM_HEADERS
