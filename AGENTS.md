# dotnix

## Project Overview

A personal environment configuration repository built on NixOS + Home Manager. The desktop layer (Hyprland/HyDE) is provided by a personal fork of hydenix (`github:santamn/hydenix`, input `hydenix`); this repo owns the multi-host setup, fingerprint auth, shell/editor/terminal choices, and everything hydenix doesn't provide (see [architecture.md](docs/architecture.md) for the history and the full division of responsibility).

### Directory Structure

- `flake.nix` — Entry point. Inputs (including the `hydenix` input) and the host list (`mkHost`)
- `hosts/<name>/` — Machine-specific settings (hardware-configuration.nix, stateVersion, etc.). Do not put shared settings here
- `modules/nixos/` — System settings shared by all hosts (one concern per file). Desktop/theme concerns live in hydenix, not here
- `modules/home/` — Home Manager settings for individual apps (`programs/`). Hyprland/waybar/rofi/wlogout/hyprlock live in hydenix's `hydenix.hm.*`, configured from `home/<user>.nix`
- `home/<user>.nix` — Per-user Home Manager entry point, including the `hydenix.hm` options for that user
- `nvim/` — Neovim's Lua configuration. Symlinked to `~/.config/nvim` and takes effect without a rebuild (see [neovim.md](docs/neovim.md) for the policy)
- `templates/` — devShell templates used by `nix flake init -t`

### Conventions

- Coloring/theming for the desktop is owned by hydenix (`hydenix.hm.theme`, wallbash). Don't reintroduce stylix or hand-roll desktop-layer configs that hydenix already provides — check `docs/architecture.md`'s division-of-responsibility table before adding to `modules/nixos/` or `modules/home/` for anything Hyprland/waybar/rofi/theme-related
- Put machine-specific values (e.g. battery thresholds) under `hosts/`; everything else goes under `modules/`
- This project is sometimes edited on machines that aren't running NixOS. In that case, don't run verification such as `nix flake check` on the editing machine — ask the user to run it on a NixOS machine instead

## Code Quality Practices

- Keep complexity under control through appropriate abstraction, concretization, and use of libraries
  - Remove code and libraries that are no longer needed
- When using a library, consult its documentation and use it correctly
  - Refer to the documentation for how to specify library versions
  - Unless the documentation instructs otherwise, use the latest stable version
- Refactor code following established best practices such as those in *The Art of Readable Code* to improve readability
- Always attach comments **in Japanese** explaining the meaning of functions, structs, and any other semantically cohesive pieces of code
