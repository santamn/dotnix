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
- When writing Japanese, enter through the `japanese-writing` skill and let it pick the style guide. `japanese-tech-writing`, `cognitive-rhythm-writing` and `stop-ai-slop-jp` each assume a genre, and applying one to the wrong genre makes the text worse. In particular, `stop-ai-slop-jp` asks for bite, self-deprecation and lukewarm verdicts, which belong in personal writing and ruin a README.
- Fix every lint finding without changing what the document says. Do not delete content to satisfy the linter.

## Coding

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Follow functional programming style.
  - Prefer to make data immutable.
  - Specify three components: Actions, Calculation, Data (This principle is written in the book "Grokking Simplicity"). Specifically, carefully isolate Actions.
- Always attach comments **in Japanese** explaining the meaning of functions, structs, and any other semantically cohesive pieces of code
