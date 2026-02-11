{
  config,
  pkgs,
  nixConfigPath,
  ...
}: {
  programs.nix-ld.enable = true;
  # Mason dependencies for Neovim LSP servers and tools
  programs.nix-ld.libraries = with pkgs; [
    # --- 基本的なC/C++ライブラリ (必須) ---
    stdenv.cc.cc.lib # libstdc++.so.6 など
    zlib # libz.so.1
    glibc

    # --- 多くのツールが要求する共通ライブラリ ---
    fuse3 # AppImage形式のツール用
    icu # Unicode処理 (libicui18n.so など)
    zstd # 圧縮関連
    nss # セキュリティ関連
    openssl # 暗号化 (libssl.so, libcrypto.so)
    curl # 通信 (libcurl.so)
    expat # XMLパース (libexpat.so)

    # --- システム/デバイス関連 ---
    libuuid # UUID生成 (util-linux に含まれる場合も)
    libxml2 # XML処理
    systemd # libudev.so など (ハードウェア情報の取得)

    # --- グラフィックス/GUI関連 (稀に必要) ---
    mesa
    gtk3
    cairo
    pango
    atk
    gdk-pixbuf
    glib

    # --- その他、特定の言語でよく使われるもの ---
    libunwind
    libssh
    bzip2
    libelf
  ];

  # ~/.config/nvim を ~/dotnix/nvim への直リンクに: どちらのファイルを編集しても即座に反映さる
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${nixConfigPath}/nvim";
}
