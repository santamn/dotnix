{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    libnotify # 'notify-send' コマンド用 (通知バナー)
    gsound # コマンド完了音用
  ];

  programs = {
    nushell = {
      enable = true;
      # ref: https://wiki.nixos.org/wiki/Nushell
      # Nushell の設定ファイルを nu で編集したい場合 config.nu はどこに置いても良い
      # configFile.source = ./.../config.nu;

      # config.nu を直接書き換えたい場合はこちらを使う
      extraConfig = ''
        # よく使われる ls コマンドのエイリアス inspired by https://github.com/nushell/nushell/issues/7190
        def lla [...args] { ls -la ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
        def la  [...args] { ls -a  ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
        def ll  [...args] { ls -l  ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
        def l   [...args] { ls     ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }

        # ------------------ 補完設定 ------------------
        #   ref: https://www.nushell.sh/cookbook/external_completers.html
        #   carapace による補完設定: https://www.nushell.sh/cookbook/external_completers.html#carapace-completer
        #     ERR エラーの修正も含む: https://www.nushell.sh/cookbook/external_completers.html#err-unknown-shorthand-flag-using-carapace

        # Carapace パッケージと統合を有効化するための環境変数を設定
        let carapace_completer = {|spans|
          carapace $spans.0 nushell ...$spans
          | from json
          | if ($in | default [] | where value == $"($spans | last)ERR" | is-empty) { $in } else { null }
        }
        # いくつかの補完はブリッジを介してのみ利用可能 e.g. tailscale: https://carapace-sh.github.io/carapace-bin/setup.html#nushell
        $env.CARAPACE_BRIDGES = 'zsh,bash,inshellisense'
        # zoxide による補完: https://www.nushell.sh/cookbook/external_completers.html#zoxide-completer
        let zoxide_completer = {|spans| $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD} }
        # 複数の補完を組み合わせるための関数: エイリアス展開もここで行う
        let multiple_completers = {|spans|
          # エイリアス補完: https://www.nushell.sh/cookbook/external_completers.html#alias-completions
          let expanded_alias = scope aliases | where name == $spans.0 | get -o 0.expansion
          let spans = if $expanded_alias != null {
            $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
          } else {
            $spans
          }
          match $spans.0 {
            __zoxide_z | __zoxide_zi => $zoxide_completer
            _ => $carapace_completer
          } | do $in $spans
        }

        $env.config = {
          show_banner: false, # Nushell 起動時のバナー表示を無効化
          completions: {
            case_sensitive: true,  # 補完時に大文字小文字を区別する
            quick: true,           # 補完の自動選択を有効化
            partial: true,         # 部分的な補完を有効化
            algorithm: "fuzzy",    # 補完アルゴリズムをファジーに設定 (デフォルトは "prefix" で、完全一致のみ)
            external: {
              enable: true,        # Carapace や zoxide などの外部補完を有効化
              max_results: 100,    # 外部補完の最大結果数
              completer: $multiple_completers,
            },
          },
          hooks: {
            env_change: {
              # ディレクトリ変更時に自動で ls
              PWD: [{|before, after| if $before != null { print (ls) } }],
            },
            # --- コマンド完了通知 ---
            # コマンド実行前: 時間を記録
            pre_execution: [{ || $env.CMD_START_TIME = (date now) }],
            # プロンプト表示前（コマンド終了後）: 時間をチェックして通知
            pre_prompt: [{ ||
              if ($env.CMD_START_TIME? != null) {
                let duration = ((date now) - $env.CMD_START_TIME)
                if $duration > 10sec { # 10秒以上かかったら通知
                  notify-send "コマンド完了" $"所要時間: ($duration)" -i terminal --urgency=normal
                  try { gsound-play -i complete }
                }
              }
              # 次回のためにリセット
              $env.CMD_START_TIME = null
            }],
          },
        }
        # PATH の設定: カスタムアプリケーションのパスを追加
        $env.PATH = ($env.PATH | prepend ($env.HOME | path join ".apps") | uniq)
      '';
    };

    fish.enable = false; # fish補完を使う場合
    carapace = {
      enable = true;
      enableNushellIntegration = true;
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
}
