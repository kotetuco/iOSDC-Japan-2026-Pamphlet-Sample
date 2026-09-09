# ExecuTorch モデル配置手順

このディレクトリは、記事検証用の Qwen3-0.6B ExecuTorch モデルを書き出してアプリに配置するためのメモです。`.pte` と `tokenizer.json` はサイズが大きいため Git にはコミットしません。

## 前提

- Python 3.10 以降
- macOS
- 空きディスク約 10GB
- optimum-executorch（`pip install optimum-executorch`。依存として入る executorch が 1.3 系であることを確認する）
- Xcode 側の SwiftPM 依存は `swiftpm-1.3.1` ブランチ（export 側の executorch バージョンと揃える）

## Export（optimum-executorch を使用・実際のフロー）

Hugging Face の optimum-executorch で 8da4w + XNNPACK 向けに export します。

```bash
optimum-cli export executorch \
  --model "Qwen/Qwen3-0.6B" \
  --task "text-generation" \
  --recipe "xnnpack" \
  --use_custom_sdpa \
  --use_custom_kv_cache \
  --qlinear 8da4w \
  --qembedding 8w \
  --max_seq_len 4096 \
  --output_dir="qwen3_0_6b_et"
```

- **`--max_seq_len 4096` を必ず指定する**。未指定のデフォルトは **2048**（`CausalLMExportableModule` の既定値）で、この値が `get_max_seq_len` として .pte に焼き込まれ、静的 KV キャッシュ長にもなる。アプリ側の `sequenceLength: 4096` と揃えること
- `--output_dir` に `model.pte` と `tokenizer.json` が保存される。`model.pte` を `qwen3_0_6b.pte`（1.7B なら `qwen3_1_7b.pte`）にリネームして配置する
- 焼き込み値は、アプリ実行時の Xcode コンソールに出る `Metadata: get_max_seq_len = ...` の行で確認できる

### 停止トークンに関する既知の制限

optimum-executorch が書くメタデータは `get_eos_id`（単数、HF config の 151645）だが、iOS のランナー（TextLLMRunner）が読むキーは `get_eos_ids`（複数）でキー名が一致しない。さらにフォールバック先の C++ HFTokenizer も、eos を tokenizer.json 本体からは読まず**同じディレクトリの `tokenizer_config.json`** から解決するため、これが無いと停止トークン集合が既定値 `{0}` になり、**全生成がトークン上限（`maximumNewTokens`）まで走る**（2026-07-14 調査確定。実測で全44回が512トークン分の時間を消費していた）。

対処は2段構え（いずれもアプリ実装済み）:

1. `tokenizer_config.json` を配置する（下記）→ eos が `<|im_end|>`（151645）として解決され、正常な出力はそこで止まる
2. 脱線時の `<|endoftext|>`（151643）は eos 単一値では登録できないため、トークンコールバックで終端マーカーを検知して `stop()` を呼ぶ（`ExecuTorchSummarizer`）。表示前の切り捨て（`cleanOutput`）も維持

### NFC 正規化バグ（濁点・半濁点の欠落）に関する既知の制限

ExecuTorch v1.3.1 の C++ HFTokenizer は tokenizer.json の NFC ノーマライザ実装が壊れており、エンコード時に濁点・半濁点付きかなを清音化する（が→か、プ→フ。NFD テーブルが結合文字を出力せず、再合成テーブルはラテン文字のみのため）。Qwen3 の tokenizer.json は NFC 指定なので日本語プロンプトが破壊される。アプリは `TokenizerNormalizerWorkaround` で normalizer を無効化した tokenizer.json のコピーを実行時に生成して回避している（入力は Swift 由来で常に NFC のため挙動は本来の NFC と同一）。**tokenizer.json を手で編集する必要はない**。詳細は docs/plans/2026-07-05-executorch-output-format-stability.md の追記4。

参考: executorch 本体の `python -m extension.llm.export.export_llm` を使う場合は `export.max_seq_length` / `export.max_context_length`（セットで 4096）と `base.metadata` の `get_eos_ids` に `[151645, 151643]` を指定すれば、停止トークンも export 時に修正できる。

## アプリへの配置

以下の3ファイルを `samples/OnDeviceSummary/OnDeviceSummary/Resources/Models/` に置いて、Xcode で再ビルドしてください。

- `qwen3_0_6b.pte`
- `tokenizer.json`
- `tokenizer_config.json`（停止トークンの解決に必要。次で取得: `curl -sLO https://huggingface.co/Qwen/Qwen3-1.7B/resolve/main/tokenizer_config.json`）

`OnDeviceSummary` は Xcode の synced folder なので、通常は追加のプロジェクト操作なしでバンドルされます。実機検証時に見つからない場合は、バンドル内配置がルート直下か `Models/` サブディレクトリかを確認してください。アプリ側は両方を検索します。

## C++ ヘッダの取得

アプリは v1.3.1 の ObjC ラッパーの UTF-8 破損（トークン境界でマルチバイト文字が欠落する）を回避するため、自作ブリッジ `UTF8SafeTextRunner` で C++ ランナーを直接呼び出します。ビルドには ExecuTorch の C++ ヘッダが必要です。

ヘッダはビルド前に次のスクリプトを実行して取得します。初回のみ clone が走るため数分かかります（オフラインでは実行できません）。取得済みなら何もしません。

```bash
samples/OnDeviceSummary/scripts/fetch_executorch_headers.sh
```

`samples/OnDeviceSummary/third_party/executorch/` にヘッダ用ソースが clone されます（Git 管理外）。

## 目安

- `.pte`: 約 472MB
- 実行時 RAM: 約 1GB
- iPhone 15 Pro: 75〜80 tok/s 程度が目安

## Qwen3-1.7B（第一候補モデル）

アプリは `qwen3_1_7b.pte` があれば優先して使い、無ければ `qwen3_0_6b.pte` にフォールバックします（トークナイザは Qwen3 全サイズ共通のため `tokenizer.json` は 1 ファイルを共用）。

- export は 0.6B と同じ optimum-cli コマンドで `--model "Qwen/Qwen3-1.7B"` に差し替え、**`--max_seq_len 4096` を必ず指定**（未指定だとデフォルト 2048 が焼き込まれる）
- 出力された `model.pte` を `qwen3_1_7b.pte` にリネームして `Resources/Models/` に配置
- `.pte` 約 1GB、実行時 RAM 2.5〜4GB 見込み。ロード時にメモリでクラッシュする場合は、Xcode の Signing & Capabilities で **Increased Memory Limit**（`com.apple.developer.kernel.increased-memory-limit`）を追加する
- 採用理由: 0.6B は few-shot 例の丸写し（例文汚染）が発生し、書式は安定しても内容の信頼性が確保できなかった（2026-07-06 実測、docs/plans/2026-07-05-executorch-output-format-stability.md 参照）
