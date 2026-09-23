// 自分の vim 設定を踏まえてコマンドを提案する CLI。
//
// エージェントのハーネスを経由せず、Haiku へ単発の API コールを投げるだけ。
// 設定要約はバイナリに埋め込む。生の init.lua は渡さない。
package main

import (
	"context"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"iter"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
	"golang.org/x/text/unicode/norm"
)

const (
	model     = "claude-haiku-4-5"
	maxTokens = 200
)

// 設定要約。作り直す手順は README.md にある
//
//go:embed config-summary.md
var configSummary string

// 連続する空白をまとめるための正規表現
var spaces = regexp.MustCompile(`\s+`)

// --- Calculation: 外界に触らない部分 ---

// normalize はキャッシュキー用にクエリを正規化する。
// NFKC で全角と半角を揃えてから小文字にし、空白を1つに潰す
func normalize(query string) string {
	text := strings.ToLower(strings.TrimSpace(norm.NFKC.String(query)))
	return spaces.ReplaceAllString(text, " ")
}

// loadAPIKey は API キーを環境変数か、無ければ設定ファイルから読む。
// どちらにも無ければ空文字を返す
func loadAPIKey(getenv func(string) string, readFile func(string) (string, error)) string {
	if key := strings.TrimSpace(getenv("ANTHROPIC_API_KEY")); key != "" {
		return key
	}
	text, err := readFile(keyPath())
	if err != nil {
		return ""
	}
	return strings.TrimSpace(text)
}

// buildSystem は system prompt を組み立てる
func buildSystem(summary string) string {
	return fmt.Sprintf(`
あなたはvimコマンドの提案器です。ユーザーの vim 設定は以下の通り。

%s

出力は必ず以下の形式。前置きと補足は一切書かない。

<コマンド1行>
---
<構成要素>: <役割の説明>
<構成要素>: <役割の説明>

説明は各行40字以内。ユーザー独自のマッピングを使った場合はその旨を明示する。標準機能で足りる場合は独自マッピングを使わない。
`, summary)
}

// ask はクエリに答える。キャッシュにあればそれを返し、無ければ send で取りに行く。
//
// send はトークンのイテレータを返す。届いた端から w へ流すため、
// 呼び出し側が差し替えられるようにしてある
func ask(
	query string,
	cache map[string]string,
	w io.Writer,
	send func(string) iter.Seq2[string, error],
) (string, bool, error) {
	key := normalize(query)
	if text, ok := cache[key]; ok {
		return text, true, nil
	}

	var b strings.Builder
	for chunk, err := range send(query) {
		if err != nil {
			return "", false, err
		}
		b.WriteString(chunk)
		if _, err := io.WriteString(w, chunk); err != nil {
			return "", false, err
		}
	}

	text := b.String()
	cache[key] = text
	return text, false, nil
}

// --- Action: ファイルと API に触る部分 ---

// vqDir は XDG の環境変数を見て、無ければ ~/ 配下の既定値の下の vq/ を返す。
// os.UserCacheDir と os.UserConfigDir は macOS で ~/Library を返すので使わない。
// README と docs/ai-agents.md が XDG のパスで書いてある
func vqDir(env, fallback string) string {
	base := os.Getenv(env)
	if base == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return ""
		}
		base = filepath.Join(home, fallback)
	}
	return filepath.Join(base, "vq")
}

// cacheDir はキャッシュとログの置き場所。
// 取れなければ空文字を返し、保存を諦める (回答自体は出せるため)
func cacheDir() string {
	return vqDir("XDG_CACHE_HOME", ".cache")
}

// keyPath は鍵ファイルの場所
func keyPath() string {
	dir := vqDir("XDG_CONFIG_HOME", ".config")
	if dir == "" {
		return ""
	}
	return filepath.Join(dir, "api-key")
}

// writeJSON は JSON を1件書き出す。
// vim のコマンドは < > を多く含むので HTML エスケープは切る
func writeJSON(path string, flag int, v any) error {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|flag, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()

	enc := json.NewEncoder(f)
	enc.SetEscapeHTML(false)
	return enc.Encode(v)
}

// loadCache はローカルのキャッシュを読む。壊れていたら捨てて作り直す
func loadCache(dir string) map[string]string {
	cache := map[string]string{}
	if dir == "" {
		return cache
	}
	b, err := os.ReadFile(filepath.Join(dir, "cache.json"))
	if err != nil {
		return cache
	}
	if err := json.Unmarshal(b, &cache); err != nil {
		return map[string]string{}
	}
	return cache
}

// saveCache はキャッシュを書き戻す
func saveCache(dir string, cache map[string]string) error {
	if dir == "" {
		return nil
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	return writeJSON(filepath.Join(dir, "cache.json"), os.O_TRUNC, cache)
}

// logEntry は質問と回答を追記する。
// 何を繰り返し忘れているかが見えるので、config-summary.md を更新する材料になる
func logEntry(dir, query, answer string, cached bool) error {
	if dir == "" {
		return nil
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	row := struct {
		Query  string `json:"query"`
		Answer string `json:"answer"`
		Cached bool   `json:"cached"`
	}{query, answer, cached}
	return writeJSON(filepath.Join(dir, "log.jsonl"), os.O_APPEND, row)
}

// streamAnswer は API をストリーミングで叩く send を作る。
// 最初のトークンが出た時点で読み始められる
func streamAnswer(ctx context.Context, client anthropic.Client, system string) func(string) iter.Seq2[string, error] {
	return func(query string) iter.Seq2[string, error] {
		return func(yield func(string, error) bool) {
			stream := client.Messages.NewStreaming(ctx, anthropic.MessageNewParams{
				Model:     model,
				MaxTokens: maxTokens,
				System:    []anthropic.TextBlockParam{{Text: system}},
				Messages: []anthropic.MessageParam{
					anthropic.NewUserMessage(anthropic.NewTextBlock(query)),
				},
			})
			for stream.Next() {
				delta, ok := stream.Current().AsAny().(anthropic.ContentBlockDeltaEvent)
				if !ok {
					continue
				}
				if text, ok := delta.Delta.AsAny().(anthropic.TextDelta); ok && !yield(text.Text, nil) {
					return
				}
			}
			if err := stream.Err(); err != nil {
				yield("", err)
			}
		}
	}
}

// run は CLI 引数を解釈し、1問に答える
func run(ctx context.Context, args []string, stdout io.Writer) error {
	query := strings.TrimSpace(strings.Join(args, " "))
	if query == "" {
		return errors.New("usage: vq <聞きたい操作>")
	}

	apiKey := loadAPIKey(os.Getenv, func(path string) (string, error) {
		b, err := os.ReadFile(path)
		return string(b), err
	})
	if apiKey == "" {
		return fmt.Errorf("ANTHROPIC_API_KEY も %s も無い", keyPath())
	}

	client := anthropic.NewClient(option.WithAPIKey(apiKey))
	send := streamAnswer(ctx, client, buildSystem(configSummary))

	dir := cacheDir()
	cache := loadCache(dir)
	answer, cached, err := ask(query, cache, stdout, send)
	if err != nil {
		return err
	}
	// キャッシュに当たったぶんは streaming では出ていないので、ここで一度に出す
	if cached {
		if _, err := io.WriteString(stdout, answer); err != nil {
			return err
		}
	}
	if _, err := io.WriteString(stdout, "\n"); err != nil {
		return err
	}

	return errors.Join(saveCache(dir, cache), logEntry(dir, query, answer, cached))
}

func main() {
	if err := run(context.Background(), os.Args[1:], os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "vq: "+err.Error())
		os.Exit(1)
	}
}
