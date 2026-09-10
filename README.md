# iOSDC Japan 2026 パンフレット サンプル

iOSDC Japan 2026 の記事「Foundation Models と ExecuTorch によるオンデバイス要約の実装比較」で使用した iOS アプリのサンプルコードです。

## 機能

`OnDeviceSummary` は付属のサンプルデータを読み込み、同じ入力を二つのエンジンで要約します。

- サンプルデータの一覧表示と詳細表示
- Apple の Foundation Models による要約
- ExecuTorch と Qwen3 による要約
- 実行時間、初回トークンまでの時間、出力文字数の表示

## セットアップ

### 必要な環境

- macOS
- Xcode 26.5 以降
- iOS 26.0 以降の実機またはシミュレータ
- Foundation Models を使う場合は Apple Intelligence が有効な環境

### プロジェクトを開く

1. `OnDeviceSummary/OnDeviceSummary.xcodeproj` を Xcode で開きます。
2. `OnDeviceSummary` スキームを選びます。
3. Team を自分の Apple Developer アカウントへ変更します。
4. 実機またはシミュレータを選び、ビルドします。

### ExecuTorch モデルを使う

モデルファイルはサイズが大きいため、このリポジトリには含めていません。
モデルの書き出し、配置、C++ ヘッダの取得方法は [`OnDeviceSummary/models/README.md`](OnDeviceSummary/models/README.md) を参照してください。

精度を重視する場合は、4bit 量子化した Qwen3-1.7B を使用してください。
Qwen3-1.7B は実行時に数 GB のメモリを使用するため、`Increased Memory Limit` entitlement を設定した実機が必要です。
Qwen3-0.6B はメモリに制約がある場合の動作確認用ですが、要約の精度や内容の信頼性は 1.7B より低くなります。

モデルは次のディレクトリへ配置します。

```text
OnDeviceSummary/OnDeviceSummary/Resources/Models/
```

最低限、次のファイルが必要です。

```text
qwen3_0_6b.pte または qwen3_1_7b.pte
tokenizer.json
tokenizer_config.json
```

## ライセンス

このリポジトリのコードは [LICENSE](LICENSE) に従います。
