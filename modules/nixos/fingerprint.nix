# 指紋認証 (fprintd) と PAM の設定
#
# 方針: 指紋はあくまで「追加の手段」であり、どの場面でも必ずパスワード入力に
# フォールバックできるようにする (指が荒れて指紋が読めなくなることがあるため)。
#
# - ログイン画面 (SDDM): パスワードのみ
#     初回ログインはパスワードで行わないと gnome-keyring が解錠されないため、
#     あえて指紋を使わない
# - ロック画面 (hyprlock): 指紋とパスワードを「同時に」受け付ける
#     PAM 経由ではなく hyprlock 内蔵の指紋対応を使う (modules/home/desktop/hyprlock.nix)。
#     そのためここでは hyprlock の PAM に fprintAuth を設定しない
# - sudo / polkit: まず指紋を試行し、失敗 (規定回数ミス or タイムアウト) すると
#     自動的にパスワード入力へ切り替わる
#
# 指紋の登録: `fprintd-enroll` を実行して指示に従う
{...}: {
  services.fprintd.enable = true;

  security.pam.services = {
    # sudo: 指紋 → 失敗時パスワード
    sudo.fprintAuth = true;
    # GUI の権限昇格ダイアログ (polkit): 指紋 → 失敗時パスワード
    polkit-1.fprintAuth = true;

    login = {
      # ログイン時は指紋認証を使わない (キーリング解錠のためパスワード必須)
      fprintAuth = false;
      # ログインパスワードで gnome-keyring を自動解錠
      enableGnomeKeyring = true;
    };

    # hyprlock は内蔵の指紋対応を使うため PAM はパスワード認証のままにする
    # (fprintAuth = true にすると指紋の待機がパスワード入力をブロックしてしまう)
    hyprlock = {};
  };
}
