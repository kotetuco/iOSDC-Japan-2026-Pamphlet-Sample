# ExecuTorch モデルの準備

このアプリは、4bit 量子化した Qwen3-1.7B を主モデルとして使用します。
モデルファイルは大きいため Git には含めていません。

## 前提

- macOS
- Python 3.10 以降
- 空きディスク約 10GB
- `optimum-executorch`
- Xcode の ExecuTorch SwiftPM 依存が `swiftpm-1.3.1`

```bash
pip install optimum-executorch
```

## Qwen3-1.7B を 4bit 量子化する

`optimum-executorch` の XNNPACK レシピで、重みを 4bit 相当の `8da4w` 形式へ変換します。

```bash
optimum-cli export executorch \
  --model "Qwen/Qwen3-1.7B" \
  --task "text-generation" \
  --recipe "xnnpack" \
  --use_custom_sdpa \
  --use_custom_kv_cache \
  --qlinear 8da4w \
  --qembedding 8w \
  --max_seq_len 4096 \
  --output_dir="qwen3_1_7b_et"
```

`--max_seq_len 4096` は省略しないでください。
省略すると既定値の 2048 がモデルへ書き込まれ、アプリの `sequenceLength: 4096` と一致しません。

出力ディレクトリの `model.pte` を `qwen3_1_7b.pte` に変更します。

## モデルを配置する

次のディレクトリへファイルを置きます。

```text
OnDeviceSummary/OnDeviceSummary/Resources/Models/
```

必要なファイルは次のとおりです。

```text
qwen3_1_7b.pte
tokenizer.json
tokenizer_config.json
```

`tokenizer_config.json` は停止トークンの解決に使います。

```bash
curl -L -o OnDeviceSummary/OnDeviceSummary/Resources/Models/tokenizer_config.json \
  https://huggingface.co/Qwen/Qwen3-1.7B/resolve/main/tokenizer_config.json
```

Xcode で再ビルドすると、モデルがアプリへバンドルされます。

## メモリに関する注意

Qwen3-1.7B は `.pte` が約 1GB、実行時メモリが約 2.5〜4GB です。
Xcode の Signing & Capabilities で `Increased Memory Limit` entitlement を有効にし、対応する実機で実行してください。

メモリに制約がある場合は、Qwen3-0.6B へ差し替えられます。
同じコマンドの `--model` を `Qwen/Qwen3-0.6B` に変更し、出力を `qwen3_0_6b.pte` として配置してください。
0.6B は動作確認には使えますが、要約の精度と内容の信頼性は 1.7B より低くなります。

## C++ ヘッダを取得する

ビルド前に次のスクリプトを実行します。

```bash
OnDeviceSummary/scripts/fetch_executorch_headers.sh
```

取得先の `OnDeviceSummary/third_party/executorch/` は Git 管理外です。

## 既知の制限

ExecuTorch v1.3.1 の C++ トークナイザには、Qwen3 の正規化と UTF-8 境界に関する制限があります。
アプリ側で回避処理を行うため、`tokenizer.json` を手で編集する必要はありません。

## ライセンス

- [Qwen3-1.7B](https://huggingface.co/Qwen/Qwen3-1.7B)とQwen3-0.6BはApache License 2.0です。
- ExecuTorchはBSD-3-Clauseライセンスです。詳細はリポジトリ直下の
  [`THIRD_PARTY_NOTICES.md`](../../THIRD_PARTY_NOTICES.md)を参照してください。
