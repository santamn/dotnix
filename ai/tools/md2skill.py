#!/usr/bin/env python3
"""Claude Code の agents/commands 定義を Agent Skills 形式の SKILL.md へ変換する。

Codex と DeepSeek Harness は SKILL.md しか読まない。サブエージェント定義も
スラッシュコマンド定義も「frontmatter + 本文」という SKILL.md と同じ形なので、
Claude 固有のキーを落とせば skill として通る。
"""

from __future__ import annotations

import argparse
import re
import sys

# skill の frontmatter に残すキー。これ以外はハーネス固有なので落とす
KEPT_KEYS = ("name", "description")

# Codex がプラグインのコマンドを移行するときに付ける接頭辞に合わせる
COMMAND_PREFIX = "source-command-"


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """先頭の YAML frontmatter を辞書に、残りを本文として返す。

    対象ファイルの frontmatter はすべて1行1キーの平坦な形なので、
    YAML パーサは使わず最初のコロンだけで切る。
    """
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 3)
    if end == -1:
        return {}, text
    meta: dict[str, str] = {}
    for line in text[4:end].splitlines():
        key, sep, value = line.partition(":")
        if sep and not key.startswith(" "):
            meta[key.strip()] = value.strip()
    return meta, text[end + 5 :].lstrip("\n")


def _rewrite(body: str) -> str:
    """ハーネス固有の文書名を共通の名前に直す。

    Codex 自身のコマンド移行も同じ置換だけを行う。
    """
    return re.sub(r"\bCLAUDE\.md\b", "AGENTS.md", body)


def to_skill(text: str, name: str, kind: str) -> str:
    """定義ファイルの中身を SKILL.md の中身に変換する。"""
    meta, body = split_frontmatter(text)
    description = meta.get("description", "").strip()
    if not description:
        raise ValueError(f"{name}: description がないため skill にできない")

    skill_name = COMMAND_PREFIX + name if kind == "command" else meta.get("name", name)
    kept = {"name": skill_name, "description": description}
    front = "".join(f"{k}: {kept[k]}\n" for k in KEPT_KEYS)
    return f"---\n{front}---\n\n{_rewrite(body)}"


def main() -> int:
    """CLI 入口。1ファイルを変換して書き出す。"""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kind", choices=("agent", "command"), required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("src")
    parser.add_argument("dst")
    args = parser.parse_args()

    with open(args.src, encoding="utf-8") as f:
        text = f.read()
    try:
        out = to_skill(text, args.name, args.kind)
    except ValueError as exc:
        print(f"md2skill: skip: {exc}", file=sys.stderr)
        return 1
    with open(args.dst, "w", encoding="utf-8") as f:
        f.write(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
