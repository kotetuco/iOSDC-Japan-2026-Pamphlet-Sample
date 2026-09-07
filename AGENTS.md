# AGENTS.md

## リポジトリの目的

このリポジトリは、iOSDC Japan 2026パンフレット記事
「Foundation ModelsとExecuTorchによるオンデバイス要約の実装比較」で使用した
iOSサンプルアプリを、読者が確認・実行できる形で公開するためのものです。

記事原稿や入稿用データではなく、再現に必要なサンプルコードと説明だけを管理します。
完成品としての堅牢性より、2つの推論方式の違いを小さく明瞭に示すことを優先します。

## 公開対象

- サンプルアプリのソースコード、テスト、セットアップ用スクリプトを管理します。
- 記事原稿、レビュー記録、入稿データ、作業メモ、生成PDF、個人用設定は含めません。
- このリポジトリ単体で、必要条件とセットアップ手順を理解できる状態にします。

## 想定する構成

- `OnDeviceSummary/` — Xcodeプロジェクト、アプリ、テスト、補助スクリプト
- `README.md` — サンプルの目的、要件、セットアップ、実行方法、制約
- `LICENSE` — このリポジトリ自身のライセンス
- `THIRD_PARTY_NOTICES.md` — 必要になった場合の依存物・モデルのライセンス表記

構成を変更するときは、READMEとこのファイルの記述も合わせて更新してください。

## 実装方針

- SwiftUIをUIの基本とし、既存のSwiftData、Foundation Models、ExecuTorchの構成を尊重します。
- AppleのAPIは、そのXcode SDKで利用できる公式APIを使用します。
- Foundation ModelsとExecuTorchの共通処理は共有し、方式固有の処理は各Engine配下に閉じ込めます。
- サンプルの理解に不要な抽象化、外部依存、機能追加は避けます。
- API名はSwift API Design Guidelinesに従い、型と責務が読み取れる名前にします。
- UIを変更するときはApple Human Interface Guidelinesとアクセシビリティを確認します。
- ユーザー向け文言とREADMEは日本語を基本とします。識別子は英語を使います。
- エラーは握りつぶさず、サンプル利用者が原因と対処を判断できる形で表示または記録します。

## 公開時の安全要件

- APIキー、証明書、プロビジョニング情報、署名ID、個人用Bundle ID、絶対パスをコミットしません。
- 実在人物のデータ、原稿執筆中の検証データ、端末由来のデータを含めません。
- サンプル入力には、公開用に作成した架空データだけを使用します。
- `.pte`、トークナイザー、生成済みヘッダーなどの大容量・再配布条件付きファイルはコミットしません。
- モデルや依存物は取得手順、対応バージョン、配布元、ライセンスをREADMEに記載します。
- 再配布する第三者コードやデータがある場合は、ライセンスを確認して必要な帰属表示を追加します。
- Xcodeプロジェクトから特定個人のDevelopment Teamを外し、コード署名なしでもCI用ビルドができる状態にします。

## ビルドとテスト

プロジェクトを追加した後は、まずschemeと利用可能なdestinationを確認します。

```sh
xcodebuild -list -project OnDeviceSummary/OnDeviceSummary.xcodeproj
xcrun simctl list devices available
```

変更後は、利用可能なiOS Simulatorを指定してテストします。

```sh
xcodebuild \
  -project OnDeviceSummary/OnDeviceSummary.xcodeproj \
  -scheme OnDeviceSummary \
  -destination 'platform=iOS Simulator,name=<available simulator>' \
  -derivedDataPath /tmp/OnDeviceSummary-DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

- Swiftを編集したらSwiftLintを実行し、違反を解消します。
- テストできない端末専用機能やモデル推論を変更した場合は、実施できた確認と未確認事項を報告します。
- モデルファイルがない状態でもアプリがビルドでき、ExecuTorchが利用不能である理由を案内できるようにします。
- Foundation Modelsを利用できないSimulatorや端末でも、クラッシュせず利用可否を表示できるようにします。

## テスト方針

- 日付処理、CSV解析、プロンプト生成、出力整形、ストリーム組み立てなどの決定的な処理を単体テストします。
- モデルの出力文そのものを完全一致で固定しません。構造、停止条件、整形結果など安定した契約を検証します。
- 実機、Apple Intelligence、外部モデルが必須のテストは通常の単体テストから分離します。
- 不具合修正では、可能なら修正前に失敗する最小の回帰テストを追加します。

## README更新要件

セットアップや挙動に影響する変更では、READMEに次の内容が揃っているか確認します。

- 対応するXcode、iOS、端末、Apple Intelligenceの要件
- クローン後の依存解決とモデル取得の手順
- Foundation Models版とExecuTorch版それぞれの実行方法
- モデルファイルをリポジトリに含めない理由と配置先
- 既知の制約、想定される失敗、トラブルシューティング
- 記事との関係、ライセンス、第三者への帰属表示

## 完了条件

- 変更範囲がサンプル公開の目的に沿っている。
- Git管理対象に秘密情報、個人設定、巨大生成物が含まれていない。
- 関連するビルド、テスト、SwiftLintが成功している。
- 実行できなかった検証がある場合、その理由が作業報告に明記されている。
- 初めて読む人がREADMEだけで必要条件とセットアップ手順を判断できる。

## Code Review Rules

- 公開対象外の原稿・レビュー資料・個人データが混入していないかを最優先で確認します。
- Development Team、署名設定、絶対パス、巨大モデルファイルの混入を指摘します。
- READMEの手順と実際のプロジェクト設定が一致しているか確認します。
- モデルがない環境やFoundation Models非対応環境で、安全に利用不能状態へ遷移するか確認します。
- 推論結果の揺らぎに依存する脆いテストや、記事の主題を隠す過剰な抽象化を指摘します。
