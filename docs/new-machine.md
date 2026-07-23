# 新しいマシンに同じ環境を作る

マシン固有の情報は `hosts/<ホスト名>/` に隔離されているため、新しいマシンの追加は以下の手順で完了する。

## 1. NixOS をインストールする

公式 ISO でインストールする。デスクトップ環境は何を選んでもよい (この flake が上書きする) が、最小構成 + デスクトップなしが無駄がない。ディスク暗号化 (LUKS) も好みで設定する。

## 2. リポジトリを clone する

```bash
nix-shell -p git
git clone https://github.com/<あなたのリポジトリ>/dotnix.git ~/dotnix
cd ~/dotnix
```

> **NOTE**: Neovim 設定のシンボリックリンクなどが `~/dotnix` を前提にしているため、置き場所は `~/dotnix` にすること。別の場所に置きたい場合は `hosts/<ホスト名>/default.nix` に `home-manager.users.<ユーザ名>.dotfiles.path = "/path/to/dotnix";` を書いて既定値を上書きする ([modules/home/dotfiles.nix](../modules/home/dotfiles.nix))。

## 3. ホスト用ディレクトリを作る

```bash
HOST=my-new-machine   # 好きなホスト名
mkdir hosts/$HOST
# インストーラが生成したハードウェア構成をコピー
cp /etc/nixos/hardware-configuration.nix hosts/$HOST/
```

`hosts/$HOST/default.nix` を作成する。[hosts/thinkpad-x13-gen6/default.nix](../hosts/thinkpad-x13-gen6/default.nix) を雛形に、そのマシンに合わせて書き換える:

```nix
{inputs, ...}: {
  imports = [
    ./hardware-configuration.nix
    # https://github.com/NixOS/nixos-hardware にそのマシン用モジュールがあれば使う
    inputs.nixos-hardware.nixosModules.common-cpu-intel # AMD なら common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-laptop # デスクトップ機なら不要
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # インストール時の NixOS バージョンを設定し、以後変更しない
  system.stateVersion = "26.05";
}
```

## 4. flake.nix にホストを登録する

[flake.nix](../flake.nix) の `nixosConfigurations` に1行追加する:

```nix
nixosConfigurations = {
  inherit thinkpad-x13-gen6;
  my-new-machine = mkHost "my-new-machine"; # ← 追加
};
```

## 5. 適用する

```bash
sudo nixos-rebuild switch --flake ~/dotnix#my-new-machine
```

ホスト名が flake の設定名と一致していれば、次回からは `--flake ~/dotnix` だけでよい
(`mkHost` が `networking.hostName` を設定するので、初回適用後は一致する)。

## 6. 初回セットアップ

```bash
passwd                  # 初期パスワード (changeme) を変更
fprintd-enroll          # 指紋を登録 (対応ハードウェアの場合)
```

- SSH 鍵 (`~/.ssh/github`) の配置
- ブラウザや Slack などへのログイン

は手作業で行う。
