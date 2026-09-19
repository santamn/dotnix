#!/usr/bin/env python3
"""自分の vim 設定を踏まえてコマンドを提案する CLI。

エージェントのハーネスを経由すると、起動とツール定義のロードと発火判定の
固定コストが推論時間を上回る。このタスクはファイル探索も編集も要らないので、
単発の API コールだけを投げる。
"""

from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from pathlib import Path

MODEL = "claude-haiku-4-5-20251001"
MAX_TOKENS = 200

# 設定要約はこのスクリプトの隣に置く。生の init.lua は渡さない
SUMMARY_PATH = Path(__file__).with_name("config-summary.md")


def _cache_dir() -> Path:
    """キャッシュとログの置き場所。XDG に従う。"""
    base = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    return Path(base) / "vq"


def _key_path() -> Path:
    """鍵ファイルの場所。リポジトリの外に置く。"""
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return Path(base) / "vq" / "api-key"


def normalize(query: str) -> str:
    """キャッシュキー用にクエリを正規化する。

    NFKC で全角半角を揃え、前後と連続の空白を潰し、小文字に寄せる。
    """
    text = unicodedata.normalize("NFKC", query).strip().lower()
    return re.sub(r"\s+", " ", text)


def load_api_key(env: dict[str, str], read_file) -> str | None:
    """API キーを環境変数、無ければ設定ファイルから読む。

    リポジトリには鍵を置かないので、どちらもリポジトリ外を見る。
    read_file を引数に取るのは、テストで実ファイルを触らずに済ませるため。
    """
    key = env.get("ANTHROPIC_API_KEY", "").strip()
    if key:
        return key
    try:
        return read_file(_key_path()).strip() or None
    except OSError:
        return None


def build_system(summary: str) -> str:
    """system prompt を組み立てる。出力形式を厳しく固定して出力トークンを抑える。"""
    return f"""あなたはvimコマンドの提案器です。ユーザーの設定は以下の通り。

{summary}

出力は必ず以下の形式。前置きと補足は一切書かない。

<コマンド1行>
---
<構成要素>: <役割の説明>
<構成要素>: <役割の説明>

説明は各行40字以内。ユーザー独自のマッピングを使った場合は
その旨を明示する。標準機能で足りる場合は独自マッピングを使わない。"""


def ask(query: str, cache: dict[str, str], send) -> tuple[str, bool]:
    """クエリに答える。キャッシュにあればそれを返し、無ければ send で取りに行く。

    send はトークンのイテレータを返す呼び出し可能オブジェクト。
    ストリーミングをそのまま標準出力へ流すため、呼び出し側が差し替えられるようにしてある。
    """
    key = normalize(query)
    if key in cache:
        return cache[key], True
    chunks = []
    for chunk in send(query):
        chunks.append(chunk)
        sys.stdout.write(chunk)
        sys.stdout.flush()
    text = "".join(chunks)
    cache[key] = text
    return text, False


def _load_cache() -> dict[str, str]:
    """ローカルのキャッシュを読む。壊れていたら捨てて作り直す。"""
    path = _cache_dir() / "cache.json"
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _save_cache(cache: dict[str, str]) -> None:
    """キャッシュを書き戻す。"""
    directory = _cache_dir()
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "cache.json").write_text(
        json.dumps(cache, ensure_ascii=False), encoding="utf-8"
    )


def _log(query: str, answer: str, cached: bool) -> None:
    """質問と回答を追記する。何を繰り返し忘れているかを後から見るため。"""
    directory = _cache_dir()
    directory.mkdir(parents=True, exist_ok=True)
    row = {"query": query, "answer": answer, "cached": cached}
    with (directory / "log.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


def main() -> int:
    """CLI 入口。"""
    query = " ".join(sys.argv[1:]).strip()
    if not query:
        print("usage: vq <聞きたい操作>", file=sys.stderr)
        return 2

    api_key = load_api_key(
        dict(os.environ), lambda p: Path(p).read_text(encoding="utf-8")
    )
    if api_key is None:
        print(f"vq: ANTHROPIC_API_KEY も {_key_path()} も無い", file=sys.stderr)
        return 1

    import anthropic

    client = anthropic.Anthropic(api_key=api_key)
    system = build_system(SUMMARY_PATH.read_text(encoding="utf-8"))

    def send(text: str):
        """API をストリーミングで叩く。最初のトークンが出た時点で読み始められる。"""
        with client.messages.stream(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            system=system,
            messages=[{"role": "user", "content": text}],
        ) as stream:
            yield from stream.text_stream

    cache = _load_cache()
    answer, cached = ask(query, cache, send)
    if cached:
        sys.stdout.write(answer)
    sys.stdout.write("\n")
    _save_cache(cache)
    _log(query, answer, cached)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
