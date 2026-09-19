# AI コーディングエージェント (Claude Code / Codex / DeepSeek Harness) の共通環境
#
# ai/ を唯一の実体とし、各エージェントの探索パスからリンクを張る。
# 自作のものは作業ツリーを直接指すので、編集は rebuild なしに効く。
#
# マーケットプレイスのプラグイン機構は使わない。Claude Code の内部キャッシュ構造に
# 依存して脆いうえ、Claude Code しか読まないため。代わりにプラグインの中身
# (skills / agents / commands / hooks) を種類ごとに各エージェントが直接読む場所へ配る。
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  # リポジトリの ai/ ディレクトリ (nix store の外にある実体)
  aiDir = "${config.dotfiles.path}/ai";

  # 作業ツリーを直接指すリンクを作る短縮形
  link = path: config.lib.file.mkOutOfStoreSymlink "${aiDir}/${path}";

  # textlint と日本語向けプリセット一式
  textlint = pkgs.textlint.withPackages [
    pkgs.textlint-rule-preset-ai-words-ja
    pkgs.textlint-rule-preset-ai-writing
    pkgs.textlint-rule-preset-ja-technical-writing
  ];

  # ディレクトリ配下のサブディレクトリ名を集める。無いディレクトリには空を返す
  subdirs = dir:
    if builtins.pathExists dir
    then builtins.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir dir))
    else [];

  # ディレクトリ直下の .md ファイル名 (拡張子なし) を集める
  mdNames = dir:
    if builtins.pathExists dir
    then
      map (lib.removeSuffix ".md")
      (builtins.attrNames
        (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".md" n) (builtins.readDir dir)))
    else [];

  # 取り込むプラグイン。それぞれ skills / agents / commands / hooks のどれかを持つ
  #
  # code-review は入れない。本文が Claude のサブエージェントとモデル名 (Haiku, Sonnet) に
  # 依存していて、他エージェントへ持っていっても動かないため。
  # Claude Code には同名の組み込み skill があるので失うものはない。
  plugins = {
    superpowers = "${inputs.superpowers}";
    ponytail = "${inputs.ponytail}";
    humanizer = "${inputs.humanizer}";
    skill-creator = "${inputs.claude-plugins-official}/plugins/skill-creator";
    claude-md-management = "${inputs.claude-plugins-official}/plugins/claude-md-management";
    code-simplifier = "${inputs.claude-plugins-official}/plugins/code-simplifier";
  };

  pluginNames = builtins.attrNames plugins;

  # 外部から持ってくる skill: 名前 -> ディレクトリ
  externalSkills =
    {
      stop-ai-slop-jp = "${inputs.stop-ai-slop-jp}";
      ast-grep = "${inputs.ast-grep-skill}/ast-grep/skills/ast-grep";
      hunk-review = "${pkgs.hunk}/share/skills/hunk/hunk-review";
      hunk-extensions = "${pkgs.hunk}/share/skills/hunk/hunk-extensions";
      use-modern-go = "${pkgs.go-modern-guidelines}/share/skills/use-modern-go";
    }
    # trailofbits は50個以上あるので使うものだけ選ぶ。
    # description は全部が文脈に載るため、並べすぎると雑音になる
    // lib.listToAttrs (map (n:
      lib.nameValuePair n "${inputs.trailofbits-skills}/plugins/${n}/skills/${n}") [
      "modern-python"
      "property-based-testing"
      "gh-cli"
    ])
    # 各プラグインの skills/ 配下
    // lib.foldl' (acc: name:
      acc
      // lib.listToAttrs (map (s:
        lib.nameValuePair s "${plugins.${name}}/skills/${s}")
      (subdirs "${plugins.${name}}/skills"))) {}
    pluginNames;

  # 自作 skill: 作業ツリーを直接指すので編集が rebuild なしに効く
  ownSkills = lib.listToAttrs (map (n:
    lib.nameValuePair n (link "skills/${n}"))
  (subdirs ../../../ai/skills));

  # agents/ と commands/ を SKILL.md に変換したもの。
  # Codex と DeepSeek は SKILL.md しか読まないため、この変換が無いと届かない。
  # command の命名は Codex 自身の移行機構に合わせて source-command- を前置する。
  #
  # 変換に失敗したら (description が無いなど) ビルドごと失敗させる。
  # 黙って飛ばすと home.file のリンク先が無くなり、activation で分かりにくく壊れるため。
  generatedSkills = pkgs.runCommand "dotnix-generated-skills" {} ''
    mkdir -p $out
    ${lib.concatMapStringsSep "\n" (name: let
        root = plugins.${name};
      in ''
        ${lib.concatMapStringsSep "\n" (a: ''
          mkdir -p $out/${a}
          ${pkgs.python3}/bin/python3 ${../../../ai/tools/md2skill.py} \
            --kind agent --name ${a} \
            ${root}/agents/${a}.md $out/${a}/SKILL.md
        '') (mdNames "${root}/agents")}
        ${lib.concatMapStringsSep "\n" (c: ''
          mkdir -p $out/source-command-${c}
          ${pkgs.python3}/bin/python3 ${../../../ai/tools/md2skill.py} \
            --kind command --name ${c} \
            ${root}/commands/${c}.md $out/source-command-${c}/SKILL.md
        '') (mdNames "${root}/commands")}
      '')
      pluginNames}
  '';

  # 生成された skill の名前は変換元のファイル名から分かる。
  # generatedSkills を readDir すると import-from-derivation になり
  # nix flake check が通らなくなるので、名前は Nix 側で組み立てる
  generated = lib.foldl' (acc: name: let
    root = plugins.${name};
  in
    acc
    // lib.listToAttrs (map (a:
      lib.nameValuePair a "${generatedSkills}/${a}")
    (mdNames "${root}/agents"))
    // lib.listToAttrs (map (c:
      lib.nameValuePair "source-command-${c}" "${generatedSkills}/source-command-${c}")
    (mdNames "${root}/commands"))) {}
  pluginNames;

  # 全 skill。自作が最後なので同名なら自作が勝つ
  allSkills = externalSkills // generated // ownSkills;

  # 1つの skill を指定した探索パスへ張る
  skillLinks = prefix:
    lib.mapAttrs' (n: src: lib.nameValuePair "${prefix}/${n}" {source = src;}) allSkills;
in {
  home.packages = [
    # --- エージェント本体 ---
    pkgs.claude-code
    pkgs.codex

    # --- エージェントが使うツール ---
    pkgs.ast-grep # 構文木ベースの検索と書き換え
    pkgs.zat # コードのアウトライン表示
    pkgs.go-modern-guidelines # use-modern-go skill が呼ぶ
    pkgs.gh # issue と PR の操作
    pkgs.jq # lint-md.sh が hook の入力を読む
    inputs.ax.packages.${system}.default # HTTP 取得と HTML 抽出
    inputs.sem.packages.${system}.default # エンティティ単位の diff と影響範囲

    # --- 文章の lint ---
    textlint
    pkgs.markdownlint-cli

    # --- 人間用 (エージェントは使わない) ---
    pkgs.hunk # diff レビュー用 TUI
    pkgs.vq # vim のコマンドを思い出すための CLI
  ];

  # hunk は git の pager を奪うので無効化する。
  # git diff の見た目は programs.delta のままにする
  programs.hunk = {
    enable = true;
    enableGitIntegration = false;
  };

  home.file = lib.mkMerge [
    {
      # 全エージェント共通の規約。3ハーネスが別々の場所を見るので同じ実体へ3本張る。
      # DeepSeek のユーザ全体規約は ~/.agents ではなく dshHome (~/.dsh) に置かれる
      ".claude/CLAUDE.md".source = link "AGENTS.md";
      ".codex/AGENTS.md".source = link "AGENTS.md";
      ".dsh/AGENTS.md".source = link "AGENTS.md";

      # lint スクリプト。AGENTS.md からはハーネス非依存の ~/.agents/hooks を案内する
      ".agents/hooks".source = link "hooks";
      ".claude/hooks".source = link "hooks";

      # Claude Code と Codex の設定。どちらもハーネス自身が書き換えるので作業ツリーを直接指す
      ".claude/settings.json".source = link "claude/settings.json";
      ".codex/config.toml".source = link "codex/config.toml";
      ".codex/hooks.json".source = link "codex/hooks.json";

      # rust-guidelines の索引 SKILL.md は ai/skills/ にあり、
      # 本文 135KB は上流の src/guidelines/ を references として見せる
      ".agents/skills/rust-guidelines/references".source = "${inputs.rust-guidelines}/src/guidelines";
      ".claude/skills/rust-guidelines/references".source = "${inputs.rust-guidelines}/src/guidelines";
    }

    # skill は Codex と DeepSeek が見る .agents と、Claude Code が見る .claude の両方へ。
    # ディレクトリごと張らないのは ~/.claude/skills/synced (claude.ai 同期) を巻き込まないため
    (skillLinks ".agents/skills")
    (skillLinks ".claude/skills")

    # サブエージェントとスラッシュコマンドは Claude Code へは素のまま渡す
    (lib.foldl' (acc: name: let
      root = plugins.${name};
    in
      acc
      // lib.listToAttrs (map (a:
        lib.nameValuePair ".claude/agents/${a}.md" {source = "${root}/agents/${a}.md";})
      (mdNames "${root}/agents"))
      // lib.listToAttrs (map (c:
        lib.nameValuePair ".claude/commands/${c}.md" {source = "${root}/commands/${c}.md";})
      (mdNames "${root}/commands"))) {}
    pluginNames)

    # プラグインのルートを安定パスで見せる。
    # hook スクリプトがここからの相対で自分の位置を解決するので、
    # settings.json と hooks.json に store path を書かずに済む
    (lib.mapAttrs' (n: root:
      lib.nameValuePair ".agents/plugins/${n}" {source = root;})
    plugins)
  ];
}
