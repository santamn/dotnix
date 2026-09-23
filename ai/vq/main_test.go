// vq のキャッシュキーと鍵の読み出しを固定するテスト。API は呼ばない。
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

func TestNormalize(t *testing.T) {
	tests := map[string]struct{ in, want string }{
		// 前後の空白と連続空白を潰すこと
		"空白を潰す": {"  delete   inside quotes ", "delete inside quotes"},
		// 全角英数を半角に揃えること (NFKC)
		"NFKC で全角を半角に": {"ｄｅｌｅｔｅ", "delete"},
		// 全角スペースも半角として扱うこと
		"全角スペース": {"a　　b", "a b"},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			if got := normalize(tt.in); got != tt.want {
				t.Errorf("normalize(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}

// 表記が違っても同じキーになること
func TestNormalizeSameKey(t *testing.T) {
	if normalize("a  b") != normalize(" A b ") {
		t.Errorf("同じ意味のクエリが別キーになっている")
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
	if !strings.Contains(buildSystem("LEADER=space"), "LEADER=space") {
		t.Error("設定要約が埋め込まれていない")
	}
	// 出力形式の指示を含むこと
	if !strings.Contains(buildSystem("x"), "---") {
		t.Error("出力形式の指示が無い")
	}
}

// キャッシュにあれば send を呼ばないこと
func TestAskCacheHitSkipsSend(t *testing.T) {
	boom := func(string) iter.Seq2[string, error] {
		t.Fatal("キャッシュに当たったのに send が呼ばれた")
		return nil
	}

	var out strings.Builder
	text, cached, err := ask("a b", map[string]string{"a b": `ci"i`}, &out, boom)
	if err != nil {
		t.Fatal(err)
	}
	if text != `ci"i` || !cached {
		t.Errorf("text = %q, cached = %v", text, cached)
	}
	// キャッシュ時は呼び出し側がまとめて出すので、ask は書かないこと
	if out.String() != "" {
		t.Errorf("out = %q, want empty", out.String())
	}
}

// キャッシュに無ければ send を呼び、流しながら結果を書き戻すこと
func TestAskCacheMissCallsSend(t *testing.T) {
	cache := map[string]string{}
	var out strings.Builder

	text, cached, err := ask(" A  B ", cache, &out, func(string) iter.Seq2[string, error] {
		return seq("ci", `"`, "i")
	})
	if err != nil {
		t.Fatal(err)
	}
	if text != `ci"i` || cached {
		t.Errorf("text = %q, cached = %v", text, cached)
	}
	if cache["a b"] != `ci"i` {
		t.Errorf("cache = %v, 正規化したキーで書き戻していない", cache)
	}
	// 届いた端から流していること
	if out.String() != `ci"i` {
		t.Errorf("out = %q, want %q", out.String(), `ci"i`)
	}
}

// send が失敗したらキャッシュを汚さずに返すこと
func TestAskSendError(t *testing.T) {
	want := errors.New("api down")
	cache := map[string]string{}

	_, _, err := ask("a b", cache, &strings.Builder{}, func(string) iter.Seq2[string, error] {
		return func(yield func(string, error) bool) { yield("", want) }
	})
	if !errors.Is(err, want) {
		t.Errorf("err = %v, want %v", err, want)
	}
	if len(cache) != 0 {
		t.Errorf("失敗した回答をキャッシュしている: %v", cache)
	}
}
