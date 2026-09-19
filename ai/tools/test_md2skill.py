"""md2skill の変換規則を固定するテスト。"""

import unittest

from md2skill import split_frontmatter, to_skill


class TestSplitFrontmatter(unittest.TestCase):
    # frontmatter と本文を分けられること
    def test_splits_keys_and_body(self):
        meta, body = split_frontmatter(
            "---\nname: foo\ndescription: does a thing\n---\n\nBody line.\n"
        )
        self.assertEqual(meta, {"name": "foo", "description": "does a thing"})
        self.assertEqual(body, "Body line.\n")

    # frontmatter が無い入力は空の辞書と全文を返すこと
    def test_no_frontmatter(self):
        meta, body = split_frontmatter("Just a body.\n")
        self.assertEqual(meta, {})
        self.assertEqual(body, "Just a body.\n")

    # 値に含まれるコロンで切らないこと
    def test_value_containing_colon(self):
        meta, _ = split_frontmatter("---\ndescription: a: b: c\n---\nx\n")
        self.assertEqual(meta["description"], "a: b: c")


class TestToSkill(unittest.TestCase):
    AGENT = (
        "---\n"
        "name: code-simplifier\n"
        "description: Simplifies code.\n"
        "model: opus\n"
        "---\n"
        "\n"
        "Follow the standards in CLAUDE.md.\n"
    )

    # agent は名前をそのまま使い、Claude 固有のキーを落とすこと
    def test_agent_drops_claude_only_keys(self):
        out = to_skill(self.AGENT, "code-simplifier", "agent")
        self.assertIn("name: code-simplifier\n", out)
        self.assertIn("description: Simplifies code.\n", out)
        self.assertNotIn("model:", out)

    # CLAUDE.md を AGENTS.md に置換すること
    def test_rewrites_doc_name(self):
        out = to_skill(self.AGENT, "code-simplifier", "agent")
        self.assertIn("Follow the standards in AGENTS.md.", out)
        self.assertNotIn("CLAUDE.md", out)

    # command は Codex に合わせて source-command- を前置すること
    def test_command_name_prefix(self):
        src = "---\ndescription: Revise it.\n---\n\nDo the thing.\n"
        out = to_skill(src, "revise-claude-md", "command")
        self.assertIn("name: source-command-revise-claude-md\n", out)

    # description が無い入力は拒否すること (Codex が必須にしている)
    def test_missing_description_is_error(self):
        with self.assertRaises(ValueError):
            to_skill("---\nname: x\n---\n\nbody\n", "x", "agent")


if __name__ == "__main__":
    unittest.main()
