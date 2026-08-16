# フォント
#
# hydenix (pkgs.hyde) が同梱するのは HyDE 自身のアイコン用フォントのみで、
# 日本語 CJK や絵文字などシステム全体のフォントはここで別途用意する必要がある
{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      inter # 汎用 UI フォント
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
          "Noto Sans Mono CJK JP"
        ];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
