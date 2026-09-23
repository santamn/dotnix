# AI コーディングエージェント (Claude Code / Codex / DeepSeek Harness) の共通環境
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

  # ディレクトリ配下のサブディレクトリ名を集める
  subdirs = dir:
    if builtins.pathExists dir
    then builtins.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir dir))
    else [];

  # ディレクトリ直下の .md ファイル名 (拡張子なし) を集める
  mdNames = dir:
    if builtins.pathExists dir
    then
      map (lib.removeSuffix ".md")
      (builtins.attrNames (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".md" n) (builtins.readDir dir)))
    else [];

  # 取り込むプラグイン
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
      japanese-tech-writing = "${inputs.japanese-tech-writing}";
      cognitive-rhythm-writing = "${inputs.cognitive-rhythm-writing}";

      ast-grep = "${inputs.ast-grep-skill}/ast-grep/skills/ast-grep";
      hunk-review = "${pkgs.hunk}/share/skills/hunk/hunk-review";
      hunk-extensions = "${pkgs.hunk}/share/skills/hunk/hunk-extensions";
      use-modern-go = "${pkgs.go-modern-guidelines}/share/skills/use-modern-go";
    }
    # trailofbits には50個以上のスキルがあるので使うものだけ選ぶ
    // lib.listToAttrs (map (n: lib.nameValuePair n "${inputs.trailofbits-skills}/plugins/${n}/skills/${n}") [
      "modern-python"
      "property-based-testing"
      "gh-cli"
    ])
    # 各プラグインの skills/ 配下
    // lib.foldl' (acc: name:
      acc
      // lib.listToAttrs (map (s: lib.nameValuePair s "${plugins.${name}}/skills/${s}")
        (subdirs "${plugins.${name}}/skills"))) {}
    pluginNames;

  # 自作 skill: 作業ツリーを直接指すので直接編集できる。
  # rust-guidelines だけは下に references を足すのでディレクトリごとは張らない
  ownSkills =
    lib.listToAttrs (map (n: lib.nameValuePair n (link "skills/${n}"))
      (lib.remove "rust-guidelines" (subdirs ../../../ai/skills)));

  # agents/ と commands/ を SKILL.md へ変換するツール。
  # ビルド時にしか使わないのでユーザの環境には入れない
  md2skill = pkgs.buildGoModule {
    pname = "md2skill";
    version = "1.0.0";
    src = ../../../ai/tools/md2skill;
    vendorHash = null; # 標準ライブラリだけで書いてあり依存が無い
  };

  # agents/ と commands/ を SKILL.md に変換したもの
  generatedSkills = pkgs.runCommand "dotnix-generated-skills" {} ''
    mkdir -p $out
    ${lib.concatMapStringsSep "\n" (name: let
        root = plugins.${name};
      in ''
        ${lib.concatMapStringsSep "\n" (a: ''
          mkdir -p $out/${a}
          ${md2skill}/bin/md2skill --kind agent --name ${a} ${root}/agents/${a}.md $out/${a}/SKILL.md
        '') (mdNames "${root}/agents")}
        ${lib.concatMapStringsSep "\n" (c: ''
          mkdir -p $out/source-command-${c}
          ${md2skill}/bin/md2skill --kind command --name ${c} ${root}/commands/${c}.md $out/source-command-${c}/SKILL.md
        '') (mdNames "${root}/commands")}
      '')
      pluginNames}
  '';

  # 自作した skill の derivation のディレクトリ名
  generated = lib.foldl' (acc: name: let
    root = plugins.${name};
  in
    acc
    // lib.listToAttrs (map (a: lib.nameValuePair a "${generatedSkills}/${a}")
      (mdNames "${root}/agents"))
    // lib.listToAttrs (map (c: lib.nameValuePair "source-command-${c}" "${generatedSkills}/source-command-${c}")
      (mdNames "${root}/commands"))) {}
  pluginNames;

  allSkills = externalSkills // generated // ownSkills;

  # .claude/skills/ と .agents/skills/ に展開する skill のリンクを作る
  # { .{claude or agent}/skills/skill-name = { source = "/nix/store/..."; } } の形
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
    pkgs.jq # lint-md.sh が hook の入力を読むのに必要
    inputs.ax.packages.${system}.default # HTTP 取得と HTML 抽出
    inputs.sem.packages.${system}.default # エンティティ単位の diff と影響範囲

    # --- 文章の lint ---
    textlint
    pkgs.markdownlint-cli

    # --- 人間用 ---
    pkgs.hunk # diff レビュー用 TUI
    pkgs.vq # vim のコマンドを思い出すためのツール
  ];

  # hunk は git の pager を奪うので無効化する。
  # git diff の見た目は programs.delta のままにする
  programs.hunk = {
    enable = true;
    enableGitIntegration = false;
  };

  home.file = lib.mkMerge [
    {
      # 全エージェント共通の規約
      ".claude/CLAUDE.md".source = link "AGENTS.md";
      ".codex/AGENTS.md".source = link "AGENTS.md";
      ".dsh/AGENTS.md".source = link "AGENTS.md";

      ".agents/hooks".source = link "hooks";
      ".claude/hooks".source = link "hooks";

      # Claude Code と Codex の設定。どちらもハーネス自身が書き換えるので作業ツリーを直接指す
      ".claude/settings.json".source = link "claude/settings.json";
      ".codex/config.toml".source = link "codex/config.toml";
      ".codex/hooks.json".source = link "codex/hooks.json";

      ".agents/skills/rust-guidelines/SKILL.md".source = link "skills/rust-guidelines/SKILL.md";
      ".claude/skills/rust-guidelines/SKILL.md".source = link "skills/rust-guidelines/SKILL.md";
      ".agents/skills/rust-guidelines/references".source = "${inputs.rust-guidelines}/src/guidelines";
      ".claude/skills/rust-guidelines/references".source = "${inputs.rust-guidelines}/src/guidelines";
    }

    # skill は Codex と DeepSeek が見る .agents と、Claude Code が見る .claude の両方にリンクする
    # ディレクトリごと張らないのは ~/.claude/skills/synced を巻き込まないため
    (skillLinks ".agents/skills")
    (skillLinks ".claude/skills")

    # Claude Code に対してはサブエージェントとスラッシュコマンドを素のまま渡す
    (lib.foldl' (acc: name: let
      root = plugins.${name};
    in
      acc
      // lib.listToAttrs (map (a: lib.nameValuePair ".claude/agents/${a}.md" {source = "${root}/agents/${a}.md";})
        (mdNames "${root}/agents"))
      // lib.listToAttrs (map (c: lib.nameValuePair ".claude/commands/${c}.md" {source = "${root}/commands/${c}.md";})
        (mdNames "${root}/commands"))) {}
    pluginNames)

    # hook スクリプトが使うプラグインのパスを提供する
    (lib.mapAttrs' (n: root: lib.nameValuePair ".agents/plugins/${n}" {source = root;}) plugins)
  ];
}
