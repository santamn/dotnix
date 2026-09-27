// vq の API キー読み出しと回答処理を固定するテスト。API は呼ばない。
package main

import (
	"errors"
	"iter"
	"strings"
	"testing"
)

// seq は決め打ちのチャンク列を返すイテレータを作る
func seq(chunks ...string) iter.Seq2[string, error] {
	return func(yield func(string, error) bool) {
		for _, c := range chunks {
			if !yield(c, nil) {
				return
			}
		}
	}
}

func TestLoadAPIKey(t *testing.T) {
	fromFile := func(string) (string, error) { return "from-file\n", nil }
	missing := func(string) (string, error) { return "", errors.New("no such file") }
	empty := func(string) string { return "" }

	// 環境変数があればそれを使うこと
	t.Run("環境変数を優先する", func(t *testing.T) {
		got := loadAPIKey(func(string) string { return "from-env" }, fromFile)
		if got != "from-env" {
			t.Errorf("got %q, want %q", got, "from-env")
		}
	})

	// 環境変数が無ければファイルを読むこと
	t.Run("ファイルに落ちる", func(t *testing.T) {
		if got := loadAPIKey(empty, fromFile); got != "from-file" {
			t.Errorf("got %q, want %q", got, "from-file")
		}
	})

	// どちらも無ければ空文字を返すこと
	t.Run("どちらも無い", func(t *testing.T) {
		if got := loadAPIKey(empty, missing); got != "" {
			t.Errorf("got %q, want empty", got)
		}
	})
}

func TestBuildSystem(t *testing.T) {
	// 設定要約を埋め込むこと
	if !strings.Contains(buildSystemPrompt("LEADER=space"), "LEADER=space") {
		t.Error("設定要約が埋め込まれていない")
	}
	// 出力形式の指示を含むこと
	if !strings.Contains(buildSystemPrompt("x"), "---") {
		t.Error("出力形式の指示が無い")
	}
}
