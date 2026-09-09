//
//  TokenizerNormalizerWorkaround.swift
//  OnDeviceSummary
//

import Foundation

/// ExecuTorch v1.3.1 の C++ HFTokenizer は NFC ノーマライザの実装が壊れており、
/// 濁点・半濁点付きかなを清音化してしまう（が→か、プ→フ）。
/// NFD テーブルが「が(0x304C)→か(0x304B)」の1対1置換で結合文字 U+3099 を出力せず、
/// 再合成テーブルもラテン文字のみのため、NFC(が) = か になる
/// （tokenizers/third-party/llama.cpp-unicode/src/unicode.cpp、2026-07-06 調査）。
///
/// アプリの入力文字列は Swift 由来で常に NFC 形式のため、tokenizer.json から
/// normalizer を外しても本来の正しい NFC と挙動は同一。normalizer を null にした
/// コピーを生成して壊れたコードパス自体を回避する。
///
/// あわせて、C++ HFTokenizer が eos を tokenizer.json 本体からは読まず、同じ
/// ディレクトリの tokenizer_config.json / special_tokens_map.json から解決する
/// 仕様（v1.3.1）に対応するため、これらの設定ファイルが元の場所にあればコピー先
/// ディレクトリにも並べる。並べないと停止トークンが既定値 0 のままになり、
/// 生成が終端で止まらない（2026-07-14 調査）。
enum TokenizerNormalizerWorkaround {
    /// normalizer を無効化した tokenizer.json のコピーを返す。
    /// normalizer が元々無い場合や、変換に失敗した場合は元の URL をそのまま返す。
    static func preparedTokenizerURL(from source: URL) -> URL {
        do {
            let data = try Data(contentsOf: source)
            guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return source
            }
            guard let normalizer = json["normalizer"], !(normalizer is NSNull) else {
                return source
            }

            let destination = destinationURL(for: source)
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            copyEOSConfigsIfAvailable(from: source, into: destination.deletingLastPathComponent())
            if isUpToDate(destination, comparedTo: source) {
                return destination
            }

            json["normalizer"] = NSNull()
            let patched = try JSONSerialization.data(withJSONObject: json)
            try patched.write(to: destination, options: .atomic)
            print("ExecuTorch tokenizer: disabled broken NFC normalizer -> \(destination.lastPathComponent)")
            return destination
        } catch {
            print("ExecuTorch tokenizer: normalizer workaround failed (\(error)); using original tokenizer.json")
            return source
        }
    }

    /// eos の定義を含む設定ファイル。HFTokenizer はトークナイザのパスと
    /// 同じディレクトリでこの名前だけを探す。
    private static let eosConfigFileNames = ["tokenizer_config.json", "special_tokens_map.json"]

    private static func copyEOSConfigsIfAvailable(from source: URL, into directory: URL) {
        let sourceDirectory = source.deletingLastPathComponent()
        for name in eosConfigFileNames {
            let configSource = sourceDirectory.appendingPathComponent(name)
            let configDestination = directory.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: configSource.path),
                  !isUpToDate(configDestination, comparedTo: configSource) else {
                continue
            }
            do {
                try? FileManager.default.removeItem(at: configDestination)
                try FileManager.default.copyItem(at: configSource, to: configDestination)
                print("ExecuTorch tokenizer: copied \(name) for eos resolution")
            } catch {
                print("ExecuTorch tokenizer: failed to copy \(name) (\(error))")
            }
        }
    }

    private static func destinationURL(for source: URL) -> URL {
        let baseName = source.deletingPathExtension().lastPathComponent
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        // ディレクトリ単位で分けるのは、HFTokenizer の設定ファイル探索が
        // 「トークナイザと同じディレクトリ」固定のため（テストの並列実行でも衝突しない）
        return directory
            .appendingPathComponent("executorch-tokenizer-\(baseName)", isDirectory: true)
            .appendingPathComponent("tokenizer.json")
    }

    private static func isUpToDate(_ destination: URL, comparedTo source: URL) -> Bool {
        let fileManager = FileManager.default
        guard
            let destinationDate = (try? fileManager.attributesOfItem(atPath: destination.path))?[.modificationDate]
                as? Date,
            let sourceDate = (try? fileManager.attributesOfItem(atPath: source.path))?[.modificationDate] as? Date
        else {
            return false
        }
        return destinationDate > sourceDate
    }
}
