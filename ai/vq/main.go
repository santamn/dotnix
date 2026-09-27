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
	"strings"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
)

const (
	model     = "claude-haiku-4-5"
	maxTokens = 200
)

// 設定要約。作り直す手順は README.md にある
//
//go:embed config-summary.md
var configSummary string

// loadAPIKey は API キーを環境変数か、無ければ設定ファイルから読む。
// どちらにも無ければ空文字を返す
func loadAPIKey(getenv func(string) string, readFile func(string) (string, error)) string {
	if key := strings.TrimSpace(getenv("VQ_API_KEY")); key != "" {
		return key
	}
	text, err := readFile(keyPath())
	if err != nil {
		return ""
	}
	return strings.TrimSpace(text)
}

func buildSystemPrompt(summary string) string {
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

// vqDir は XDG の環境変数を見て、無ければ ~/ 配下の既定値の下の vq/ を返す。
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

// keyPath は鍵ファイルの場所
func keyPath() string {
	dir := vqDir("XDG_CONFIG_HOME", ".config")
	if dir == "" {
		return ""
	}
	return filepath.Join(dir, "api-key")
}

// appendJSON は JSON を1件書き出す。
// vim のコマンドは < > を多く含むので HTML エスケープは切る
func appendJSON(path string, v any) error {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()

	enc := json.NewEncoder(f)
	enc.SetEscapeHTML(false)
	return enc.Encode(v)
}

// recordInteraction は質問と回答を追記する。
// 何を繰り返し忘れているかが見えるので、config-summary.md を更新する材料になる
func recordInteraction(query, answer string) error {
	logDir := vqDir("XDG_STATE_HOME", filepath.Join(".local", "state"))
	if logDir == "" {
		return nil
	}

	if err := os.MkdirAll(logDir, 0o755); err != nil {
		return err
	}

	return appendJSON(
		filepath.Join(logDir, "log.jsonl"),
		map[string]string{"query": query, "answer": answer},
	)
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
			defer stream.Close()

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
		return fmt.Errorf(
			"API キーが見つかりません。環境変数 VQ_API_KEY か、設定ファイル %s に書き込んでください",
			keyPath(),
		)
	}

	client := anthropic.NewClient(option.WithAPIKey(apiKey))
	send := streamAnswer(ctx, client, buildSystemPrompt(configSummary))

	var answer strings.Builder
	for chunk, err := range send(query) {
		if err != nil {
			return err
		}
		answer.WriteString(chunk)
		if _, err := io.WriteString(stdout, chunk); err != nil {
			return err
		}
	}

	if _, err := io.WriteString(stdout, "\n"); err != nil {
		return err
	}

	return recordInteraction(query, answer.String())
}

func main() {
	if err := run(context.Background(), os.Args[1:], os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "vq: "+err.Error())
		os.Exit(1)
	}
}
