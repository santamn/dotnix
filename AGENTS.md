# dotnix

## Project Overview

A personal environment configuration repository built on NixOS + Home Manager. It used to be based on hydenix, but is now built from plain NixOS + Home Manager + stylix (see [architecture.md](docs/architecture.md) for the history and overall picture).

### Directory Structure

- `flake.nix` — Entry point. Inputs and the host list (`mkHost`)
- `hosts/<name>/` — Machine-specific settings (hardware-configuration.nix, stateVersion, etc.). Do not put shared settings here
- `modules/nixos/` — System settings shared by all hosts (one concern per file)
- `modules/home/` — Home Manager settings. `desktop/` holds the full Hyprland setup, `programs/` holds individual apps
- `home/<user>.nix` — Per-user Home Manager entry point
- `nvim/` — Neovim's Lua configuration. Symlinked to `~/.config/nvim` and takes effect without a rebuild (see [neovim.md](docs/neovim.md) for the policy)
- `themes/` — base16 color schemes for stylix
- `templates/` — devShell templates used by `nix flake init -t`

### Conventions

- Centralize all coloring through stylix
  - Don't hardcode app-specific colors; reference `config.lib.stylix.colors` instead
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
