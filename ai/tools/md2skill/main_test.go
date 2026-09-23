// md2skill の変換規則を固定するテスト。
package main

import (
	"maps"
	"strings"
	"testing"
)

// frontmatter に Claude 固有のキーを持つ典型的な agent 定義
const agentSrc = `---
name: code-simplifier
description: Simplifies code.
model: opus
---

Follow the standards in CLAUDE.md.
`

func TestSplitFrontmatter(t *testing.T) {
	tests := map[string]struct {
		in       string
		wantMeta map[string]string
		wantBody string
	}{
		// frontmatter と本文を分けられること
		"frontmatter と本文を分ける": {
			in:       "---\nname: foo\ndescription: does a thing\n---\n\nBody line.\n",
			wantMeta: map[string]string{"name": "foo", "description": "does a thing"},
			wantBody: "Body line.\n",
		},
		// frontmatter が無い入力は空の map と全文を返すこと
		"frontmatter が無い": {
			in:       "Just a body.\n",
			wantMeta: nil,
			wantBody: "Just a body.\n",
		},
		// 値に含まれるコロンで切らないこと
		"値にコロンを含む": {
			in:       "---\ndescription: a: b: c\n---\nx\n",
			wantMeta: map[string]string{"description": "a: b: c"},
			wantBody: "x\n",
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			meta, body := splitFrontmatter(tt.in)
			if !maps.Equal(meta, tt.wantMeta) {
				t.Errorf("meta = %v, want %v", meta, tt.wantMeta)
			}
			if body != tt.wantBody {
				t.Errorf("body = %q, want %q", body, tt.wantBody)
			}
		})
	}
}

// agent は frontmatter の name を使い、Claude 固有のキーを落とすこと
func TestToSkillAgentDropsClaudeOnlyKeys(t *testing.T) {
	out, err := toSkill(agentSrc, "code-simplifier", "agent")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "name: code-simplifier\n") {
		t.Errorf("name が引き継がれていない: %q", out)
	}
	if !strings.Contains(out, "description: Simplifies code.\n") {
		t.Errorf("description が引き継がれていない: %q", out)
	}
	if strings.Contains(out, "model:") {
		t.Errorf("Claude 固有のキーが落ちていない: %q", out)
	}
}

// 本文の CLAUDE.md を AGENTS.md に置換すること
func TestToSkillRewritesDocName(t *testing.T) {
	out, err := toSkill(agentSrc, "code-simplifier", "agent")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "Follow the standards in AGENTS.md.") || strings.Contains(out, "CLAUDE.md") {
		t.Errorf("文書名が置換されていない: %q", out)
	}
}

// command は Codex に合わせて source-command- を前置すること
func TestToSkillCommandNamePrefix(t *testing.T) {
	out, err := toSkill("---\ndescription: Revise it.\n---\n\nDo the thing.\n", "revise-claude-md", "command")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "name: source-command-revise-claude-md\n") {
		t.Errorf("接頭辞が付いていない: %q", out)
	}
}

// CRLF の入力でも frontmatter を切れること
func TestToSkillHandlesCRLF(t *testing.T) {
	out, err := toSkill("---\r\nname: crlf\r\ndescription: windows endings\r\n---\r\n\r\nbody\r\n", "crlf", "agent")
	if err != nil {
		t.Fatal(err)
	}
	if want := "---\nname: crlf\ndescription: windows endings\n---\n\nbody\n"; out != want {
		t.Errorf("out = %q, want %q", out, want)
	}
}

// description が無い入力は拒否すること (Codex が必須にしている)
func TestToSkillMissingDescriptionIsError(t *testing.T) {
	if _, err := toSkill("---\nname: x\n---\n\nbody\n", "x", "agent"); err == nil {
		t.Error("description が無いのにエラーにならない")
	}
}
