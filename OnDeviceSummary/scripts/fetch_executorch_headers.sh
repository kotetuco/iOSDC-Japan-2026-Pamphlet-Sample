#!/bin/bash
# ExecuTorch v1.3.1 の C++ ヘッダを third_party/ に取得する。
#
# UTF8SafeTextRunner.mm は上流の ObjC ラッパーが同梱していない
# C++ ヘッダ（extension/llm/runner ほか）を include するため、
# ビルド前に手動で実行する。取得済みなら即終了する。
# ヘッダのみを使用し、ビルドは行わない（シンボルは SwiftPM の
# executorch_llm xcframework から解決される）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DEST="$ROOT_DIR/third_party/executorch"

# SwiftPM のバイナリは swiftpm-1.3.1 ブランチ産のため、タグ v1.3.1 と
# ヘッダがずれる場合はここを該当コミットに変更する。
EXECUTORCH_REF="v1.3.1"

if [ -d "$DEST/.git" ]; then
  echo "third_party/executorch は取得済みです: $DEST"
  exit 0
fi

mkdir -p "$ROOT_DIR/third_party"
git clone --depth 1 --branch "$EXECUTORCH_REF" https://github.com/pytorch/executorch.git "$DEST"
git -C "$DEST" submodule update --init --depth 1 extension/llm/tokenizers

echo "完了: $DEST（ref: $EXECUTORCH_REF）"
