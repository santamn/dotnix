# dotnix

## Project Overview

A personal environment configuration repository built on NixOS + Home Manager. The desktop layer (Hyprland/HyDE) is provided by a personal fork of hydenix (`github:santamn/hydenix`, input `hydenix`); this repo owns the multi-host setup, fingerprint auth, shell/editor/terminal choices, and everything hydenix doesn't provide.

### Directory Structure

- `flake.nix` — Entry point. Inputs (including the `hydenix` input) and the host list (`mkHost`)
- `hosts/<name>/` — Machine-specific settings (hardware-configuration.nix, stateVersion, etc.). Do not put shared settings here
- `modules/nixos/` — System settings shared by all hosts (one concern per file). Desktop/theme concerns live in hydenix, not here
- `modules/home/` — Home Manager settings for individual apps (`programs/`). Hyprland/waybar/rofi/wlogout/hyprlock live in hydenix's `hydenix.hm.*`, configured from `home/<user>.nix`
- `home/<user>.nix` — Per-user Home Manager entry point, including the `hydenix.hm` options for that user
- `nvim/` — Neovim's Lua configuration. Symlinked to `~/.config/nvim` and takes effect without a rebuild (see [neovim.md](docs/neovim.md) for the policy)
- `ai/` — Shared AI agent layer: the common AGENTS.md, skills, and lint hooks. Linked into `~/.agents/`, `~/.claude/`, `~/.codex/` and `~/.dsh/`. Like `nvim/`, edits take effect without a rebuild (see [ai-agents.md](docs/ai-agents.md))
- `pkgs/` — Package definitions for what nixpkgs does not carry. Read from `modules/nixos/overlays.nix` via `callPackage`
- `templates/` — devShell templates used by `nix flake init -t`

### Conventions

- Put machine-specific values (e.g. battery thresholds) under `hosts/`; everything else goes under `modules/`
- This project is sometimes edited on machines that aren't running NixOS. In that case, don't run verification such as `nix flake check` on the editing machine — ask the user to run it on a NixOS machine instead
