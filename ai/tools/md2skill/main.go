// Claude Code の agents/commands 定義を Agent Skills 形式の SKILL.md へ変換する。
//
// Codex と DeepSeek Harness は SKILL.md しか読まない。サブエージェント定義も
// スラッシュコマンド定義も「frontmatter + 本文」という SKILL.md と同じ形なので、
// Claude 固有のキーを落とせば skill として通る。
package main

import (
	"cmp"
	"errors"
	"flag"
	"fmt"
	"os"
	"regexp"
	"strings"
)

// Codex がプラグインのコマンドを移行するときに付ける接頭辞に合わせる
const commandPrefix = "source-command-"

// ハーネス固有の文書名。共通の AGENTS.md へ置き換える
var claudeDoc = regexp.MustCompile(`\bCLAUDE\.md\b`)

// splitFrontmatter は先頭の YAML frontmatter を map に、残りを本文として返す。
//
// 対象ファイルの frontmatter はすべて1行1キーの平坦な形なので、
// YAML パーサは使わず最初のコロンだけで切る。
func splitFrontmatter(text string) (map[string]string, string) {
	rest, ok := strings.CutPrefix(text, "---\n")
	if !ok {
		return nil, text
	}
	head, body, ok := strings.Cut(rest, "\n---\n")
	if !ok {
		return nil, text
	}

	meta := make(map[string]string)
	for line := range strings.SplitSeq(head, "\n") {
		key, value, ok := strings.Cut(line, ":")
		// インデントされた行はネストした値なので、平坦なキーだけを拾う
		if ok && !strings.HasPrefix(key, " ") {
			meta[strings.TrimSpace(key)] = strings.TrimSpace(value)
		}
	}
	return meta, strings.TrimLeft(body, "\n")
}

// toSkill は定義ファイルの中身を SKILL.md の中身に変換する。
// 残すキーは name と description だけで、他はハーネス固有なので落とす。
func toSkill(text, name, kind string) (string, error) {
	// 改行は LF に揃えてから切る。CRLF のままだと frontmatter の区切りを見落とす
	meta, body := splitFrontmatter(strings.ReplaceAll(text, "\r\n", "\n"))
	description := meta["description"]
	if description == "" {
		return "", fmt.Errorf("%s: description がないため skill にできない", name)
	}

	// command は Codex の移行結果と同じ名前にする。
	// agent は frontmatter の name を優先し、無ければファイル名を使う
	skillName := cmp.Or(meta["name"], name)
	if kind == "command" {
		skillName = commandPrefix + name
	}

	return fmt.Sprintf(
		"---\nname: %s\ndescription: %s\n---\n\n%s",
		skillName,
		description,
		claudeDoc.ReplaceAllString(body, "AGENTS.md"),
	), nil
}

// run は CLI 引数を解釈し、1ファイルを変換して書き出す。
func run() error {
	kind := flag.String("kind", "", "変換元の種別 (agent か command)")
	name := flag.String("name", "", "skill 名のもとにする定義名")
	flag.Parse()

	if !(*kind == "agent" || *kind == "command") {
		return errors.New("--kind には agent か command を渡す")
	}
	if *name == "" || flag.NArg() != 2 {
		return errors.New("usage: md2skill --kind {agent|command} --name NAME SRC DST")
	}

	text, err := os.ReadFile(flag.Arg(0))
	if err != nil {
		return err
	}
	out, err := toSkill(string(text), *name, *kind)
	if err != nil {
		return err
	}
	return os.WriteFile(flag.Arg(1), []byte(out), 0o644)
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "md2skill: "+err.Error())
		os.Exit(1)
	}
}
