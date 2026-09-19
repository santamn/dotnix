"""vq のキャッシュキーと鍵の読み出しを固定するテスト。API は呼ばない。"""

import unittest

from vq import ask, build_system, load_api_key, normalize


class TestNormalize(unittest.TestCase):
    # 前後の空白と連続空白を潰すこと
    def test_collapses_whitespace(self):
        self.assertEqual(normalize("  delete   inside quotes "), "delete inside quotes")

    # 全角英数を半角に揃えること (NFKC)
    def test_nfkc(self):
        self.assertEqual(normalize("ｄｅｌｅｔｅ"), "delete")

    # 表記が同じなら同じキーになること
    def test_same_key(self):
        self.assertEqual(normalize("a  b"), normalize(" a b "))


class TestLoadApiKey(unittest.TestCase):
    # 環境変数があればそれを使うこと
    def test_prefers_env(self):
        key = load_api_key({"ANTHROPIC_API_KEY": "from-env"}, lambda _: "from-file")
        self.assertEqual(key, "from-env")

    # 環境変数が無ければファイルを読むこと
    def test_falls_back_to_file(self):
        key = load_api_key({}, lambda _: "from-file\n")
        self.assertEqual(key, "from-file")

    # どちらも無ければ None を返すこと
    def test_returns_none(self):
        def missing(_):
            raise FileNotFoundError

        self.assertIsNone(load_api_key({}, missing))


class TestBuildSystem(unittest.TestCase):
    # 設定要約を埋め込むこと
    def test_embeds_summary(self):
        self.assertIn("LEADER=space", build_system("LEADER=space"))

    # 出力形式の指示を含むこと
    def test_states_output_format(self):
        self.assertIn("---", build_system("x"))


class TestAsk(unittest.TestCase):
    # キャッシュにあれば send を呼ばないこと
    def test_cache_hit_skips_send(self):
        def boom(_):
            raise AssertionError("send should not be called")

        text, cached = ask("a b", {"a b": 'ci"i'}, boom)
        self.assertEqual(text, 'ci"i')
        self.assertTrue(cached)

    # キャッシュに無ければ send を呼び、結果を書き戻すこと
    def test_cache_miss_calls_send(self):
        cache: dict[str, str] = {}
        text, cached = ask(" A  B ", cache, lambda q: iter(["ci", '"', "i"]))
        self.assertEqual(text, 'ci"i')
        self.assertFalse(cached)
        self.assertEqual(cache["a b"], 'ci"i')


if __name__ == "__main__":
    unittest.main()
