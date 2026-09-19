# vq

自分の vim 設定を踏まえてコマンドを提案する CLI。

```sh
vq "クォートの中だけ消したい"
```

skill にしていないのは、エージェントのハーネスを経由すると起動とツール定義のロードと発火判定の固定コストが推論時間を上回るため。このタスクはファイル探索も編集も要らないので、単発の API コールだけを投げる。

## API キー

`ANTHROPIC_API_KEY`、無ければ `$XDG_CONFIG_HOME/vq/api-key` を読む。どちらもリポジトリの外に置く。

## config-summary.md の作り直し

nvim の設定を変えたときだけ作り直す。

1. 実キーマップを dump する。

   ```sh
   nvim --headless \
     -c 'lua local t={} for _,m in ipairs({"n","i","v","x","o","t"}) do for _,k in ipairs(vim.api.nvim_get_keymap(m)) do t[#t+1]=m.." "..k.lhs.." "..(k.desc or "") end end io.write(table.concat(t,"\n"))' \
     -c 'qa' > /tmp/keymap.txt
   ```

2. `/tmp/keymap.txt` と `nvim/lazy-lock.json` を Opus に渡し、次を30〜50行に圧縮させる。

   - leader キー
   - 自分で足したマッピング
   - 入っているプラグインと、それが追加するオペレータおよびテキストオブジェクト

3. 結果を `config-summary.md` に置く。

生の `init.lua` を system prompt に渡さないこと。入力トークンが増えて最初のトークンまでが遅くなり、モデルも関係ない行に引っ張られる。

## ログ

質問と回答は `$XDG_CACHE_HOME/vq/log.jsonl` に溜まる。何を繰り返し忘れているかが見えるので、マッピングを作るべきか体に入っていないだけかの判断材料になる。`config-summary.md` を更新するときの材料にもなる。
