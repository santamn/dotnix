{lib, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # インタラクティブセッションでnushellを起動
    initContent = lib.mkBefore ''
      # インタラクティブシェルの場合のみ nushell を起動
      # Neovim のターミナルでは、親シェルから NUSHELL_ACTIVE が引き継がれて
      # zsh->nu への自動切り替えが抑止されることがあるため、NVIM 配下では常に許可する
      if [[ $- == *i* ]] \
        && command -v nu >/dev/null 2>&1 \
        && { [[ -z "$NUSHELL_ACTIVE" ]] || [[ -n "$NVIM" ]]; }; then
        export NUSHELL_ACTIVE=1
        exec nu
      fi
    '';
  };
}
