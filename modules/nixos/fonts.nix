# フォント
{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      inter # ロック画面などで使う UI フォント (SF Pro 風)
      terminus_font
      cantarell-fonts
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [
          "Noto Serif CJK JP"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Noto Sans CJK JP"
          "Noto Color Emoji"
        ];
        monospace = [
          "FiraCode Nerd Font"
          "Noto Sans CJK JP"
        ];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
