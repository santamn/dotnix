---
name: rust-guidelines
description: Rust を書く、直す、レビューするときに使う。Microsoft の Pragmatic Rust Guidelines を参照し、API 設計、安全性、正しさ、ドキュメント、AI から使いやすい設計の指針を示す。該当するカテゴリだけを読むための索引。
---

# Pragmatic Rust Guidelines

Microsoft の [Pragmatic Rust Guidelines](https://microsoft.github.io/rust-guidelines/) を引く。

## 読み方

全部で 135KB ある。**全部は読まない。** 下の表から該当するカテゴリを1つか2つ選び、
`references/<category>/` の中の `M-*.md` だけを読む。各ファイルは1つの指針で完結している。

| カテゴリ | いつ読むか |
| --- | --- |
| `universal` | すべての Rust コード。まずここ |
| `libs` | ライブラリや crate の公開 API を設計するとき |
| `apps` | アプリケーションを書くとき |
| `safety` | `unsafe` を書くとき、FFI を触るとき |
| `correctness` | 不変条件、エラー処理、型で誤用を防ぐとき |
| `docs` | 公開 API のドキュメントを書くとき |
| `ai` | エージェントが触る前提で API を設計するとき |

`references/` の実体は上流の `src/guidelines/` なので、上の表にないディレクトリが
増えていることがある。迷ったら `ls references/` で確認する。

## 指針の引き方

各指針には `M-DESIGN-FOR-AI` のような ID が振ってある。レビューで指摘するときは ID を添える。

`references/<category>/README.md` にそのカテゴリの概要がある。どのカテゴリか決めきれないときはそこから入る。
