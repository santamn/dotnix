# AGENTS.md

Conventions shared by every project. A project's own AGENTS.md wins over this file.

## Routing

Before you start, find your situation here.

| Situation | Do this |
| --- | --- |
| Writing or editing Japanese prose | Start from the `japanese-writing` skill. It routes you to the right style guide for the genre. Never reach for a style guide directly |
| You wrote or edited a `.md` file | Run `~/.agents/hooks/lint-md.sh <file>` and fix what it reports |
| Writing Go | Use the `use-modern-go` skill. It detects the project's Go version through the `go-modern-guidelines` CLI |
| Writing Python | Read the `modern-python` skill |
| Writing Rust | Use the `rust-guidelines` skill and read only the categories its index points you to |
| About to read a large source file | Get its structure first with `ast-grep outline <path>` or `zat <path>` |
| About to change or remove a function signature | Check the blast radius with `sem impact` first |
| Reporting how much changed | Do not count `+`/`-` lines from `git diff`. Use the entity counts from `sem diff` |
| Working with HTML or an API | Reach for `ax` before writing a Python or Node script. Run `ax agent-context` to learn it — use it instead of throwaway scripts. |
| A regex code search is getting fragile | Switch to `ast-grep`. See the `ast-grep` skill for rule syntax |
| Looking for a file or directory | `fd`, not `find` |
| Searching text | `rg`, not `grep -r` |

## Writing

- Do not hard wrap prose. Insert line breaks only between paragraphs — never mid-paragraph to constrain visual line width. Let the display handle soft wrapping.
- When writing Japanese prose, enter through the `japanese-writing` skill and let it pick the style guide.
- For short Japanese text (code comments, chat replies), follow these rules from `japanese-tech-writing`; the skill itself won't load for such text.
  - 次のような言い回しは、無意味に「ちゃんと書いている感」を演出するだけなので、使ってはならない
    - **予告と総括**：「重要なのは〜である」「本章では〜を扱う／探求する」「ここでは〜について見ていく」「まとめると」「要するに」（直前の言い換えだけのとき）、「〜に他ならない」
    - **正面から系**：「正面から扱う」「正面から回収する」「正面から見る／書く／立てる」——中身の代わりに姿勢だけを宣言する
    - **空虚な形容**：「不可欠」「核心的」「鍵となる」「根本的な」（主張の中身を説明せず強調だけする）、「多角的」「包括的」「総合的」（何をどう見たかを書かない）
    - **空虚な動詞**：「掘り下げる」「深掘りする」「言語化する」（何をどう書いたかを示さず終わる）、「触れる」「言及する」（一段落で済ませるだけ）
    - **接続の型**：「〜において」「〜という側面から」「〜の観点から」（新情報なし）、「さらに」「また」「加えて」の連打
    - **弱い緩和と称賛**：「〜と言えるだろう」「〜かもしれない」（根拠なく主張を弱める場合だけ。推量・仮定・読者の疑念・作中人物の認識なら残す）、「非常に」「極めて」「大いに」（中身のない強調）
    - 例
      - 悪い例：「本章では、〇〇の理論を正面から扱う」「この前提を、ここで正面から回収する」「多角的に分析すると、重要なのは〜である」。
      - 良い例：「本章では、〇〇の理論を扱う」「ここで、この前提を回収する」「評価の核心は、正しさを誰が知っているかにある」。
  - LLM は日本語として存在しない言い回しを次の三つの経路で生成する。これはは書き手（LLM）に比喩や演出の意識がないまま混入するので、比喩を使ったつもりのない文も含めて点検し、使わないよう注意すること
    - **英語慣用句の直訳**：英語の技術文では carry / open / expose / live / land などの比喩的用法が慣用句として定着しており、比喩として意識されない。これを日本語の対応語に直訳すると、日本語では慣用化していないため、字義どおりに読める奇妙な生きた比喩になる。
      - 悪い例：「ベクトルが選好を運ぶ」（carry）。良い例：「選好がベクトルとして表現される」「ベクトルに反映される」。
      - 悪い例：「この問いは開かれている」（open question）。良い例：「この問いにはまだ答えが出ていない」「未解決である」。
      - 悪い例：「推敲の軸が露出する」（expose）。良い例：「推敲の軸が線形に取り出せる」。
      - 悪い例：「この情報は残差ストリームに住んでいる」（live in）。良い例：「残差ストリームに含まれる」。
    - **無生物主語構文の直輸入**：英語では無生物主語の他動詞文が普通だが、そのまま日本語にすると、モデル、データ、ベクトル、損失といった抽象物が意思を持って振る舞う擬人化になる。日本語では、人か処理を主体に戻すか、「〜から分かる」「〜に含まれる」の形に言い直す。
      - 悪い例：「モデルは文体を知っている」。良い例：「モデルの出力には文体の一貫性がある」など、確認できる事実として書く。
      - 悪い例：「データが語るのは〜である」。良い例：「データから分かるのは〜である」。
    - **研究者の話し言葉の混入**：機械学習の口頭議論で流通する動詞（「効く」「刺さる」「筋がいい」など）は、話し言葉としては通じるが、書き言葉の技術文書では俗語である。効果や見込みの内容を具体的に書く。
      - 悪い例：「規範スキルが効く」。良い例：「規範スキルを与えると生成が選好に近づく」。
      - 悪い例：「この手法は筋がいい」。良い例：「この手法は〜という理由で有望である」。
    - 比喩か擬人化か迷ったら2段で判定する。その述語を初めて見た読者が字義どおりの動作を想像しうるなら疑い、次に動作の主体と対象を具体語で言い直せるか試す。言い直せるならその言い直しを書き、言い直せないなら、その文は指す内容が決まっていないので削る
  - 術語・訳語は、その分野で慣用されている語を選ぶ（プッシュ通知は「配送」ではなく「配信」、など）。意味の近い漢語を一般語の感覚で充てない。
  - 術語の響きを持つ語を、術語でない場面に流用しない（システムから人間までの連なりを「経路」と呼ぶ、など）。「届くまでの流れ」「あいだに何があるか」のように普通の言い方で書く。
- Fix every lint finding without changing what the document says. Do not delete content to satisfy the linter.

## Coding

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Follow functional programming style.
  - Prefer to make data immutable.
  - Specify three components: Actions, Calculation, Data (This principle is written in the book "Grokking Simplicity"). Specifically, carefully isolate Actions.
- Always attach comments **in Japanese** explaining the meaning of functions, structs, and any other semantically cohesive pieces of code
