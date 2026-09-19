---
name: japanese-writing
description: 日本語の文章を書く、直す、レビューするときに使う。技術文書、記事や書籍の原稿、個人のブログ、commit や PR の短文で適用するルールが違うため、まずジャンルを決めてから該当する reference だけを読む。AI が書いた日本語に出る癖の除去、論証の厳密さ、段落構成、認知リズム、主体性の回復を扱う。
---

# 日本語ライティング

## 最初にジャンルを決める

適用するルールはジャンルで変わる。技術文書に個人のブログ向けのルールを当てると逆効果になる
(README に毒や自虐を入れることになる)。書き始める前に下から1つ選ぶ。

| ジャンル | 対象 | 読む reference |
| --- | --- | --- |
| 技術文書 | README、docs/、設計書、API ドキュメント、コードコメント | `llm-tells.md`、`tech-docs.md` |
| 読み物 | 記事、書籍の章、解説、チュートリアル | `llm-tells.md`、`tech-docs.md`、`long-form.md` |
| 個人の文章 | ブログ、感想、ポエム | `llm-tells.md`、`personal.md` |
| 短文 | commit message、PR 説明、issue | `llm-tells.md` |

判断に迷ったら、その文章に**書き手個人の立場が要るか**で決める。要るなら個人の文章、
要らないなら技術文書。

## 全ジャンル共通

`references/llm-tells.md` は必ず読む。LLM が量産する空句、英語慣用句の直訳、
無生物主語の擬人化は、どのジャンルでも等しく害になる。

## textlint との分担

語彙と記号の機械的な判定は textlint に任せてある。この skill では扱わない。

- textlint が拾う: 偏愛語、全角ダッシュ、中黒での3項目並列、`**` の残骸、コロンの後の半角スペース
- この skill が扱う: false agency、論証の飛躍、命題型 H2、未回収の緊張、立場の不在

`.md` を書いたら `~/.agents/hooks/lint-md.sh <file>` を走らせる。

## 迷ったときの参照

`references/examples.md` に、AI 版と人間版の対比をジャンルのタグ付きで置いてある。
