# testflutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# manapass

## Firestoreの問題データ

アプリはログイン中のユーザーに対して、Firestoreの `questions` コレクションから問題を読み込みます。Firebase ConsoleでCloud Firestoreデータベースを作成し、CLIの対象プロジェクトがアプリのFirebase設定と一致することを確認してから、次のコマンドでルールを反映してください。

```shell
firebase deploy --only firestore:rules
```

`questions` コレクションに、次の形式でドキュメントを登録します。ドキュメントIDには問題IDを指定します。サンプルは `assets/questions/questions.json` にあります。

| フィールド | 型 | 説明 |
|---|---|---|
| `exam` | 文字列 | 試験名 |
| `category` | 文字列 | 大分類 |
| `topic` | 文字列 | 出題分野 |
| `question` | 文字列 | 問題文 |
| `choices` | 文字列の配列 | 選択肢 |
| `answerIndex` | 数値 | 正解の選択肢番号（0始まり） |
| `explanation` | 文字列 | 解説 |

アプリは不正解の解答を `users/{ログインユーザーのUID}/questionProgress/{問題ID}` に保存します。正解すると復習対象から外れます。問題の読み取りと解答記録にはログインが必要です。
