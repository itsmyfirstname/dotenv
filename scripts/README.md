# Link Script

`link-configs.sh` creates safe symlinks from your home config paths to this repo.

- Common/shared configs live in `common/` (currently `common/nvim`, `common/zsh`).
- Arch-specific configs live under `arch/`.

Current links managed:

- `~/.config/nvim` -> `common/nvim`
- `~/.config/zsh` -> `common/zsh`
- `~/.gitconfig` -> `.gitconfig`

If an existing path points elsewhere (or is a real file/dir), the script backs it up as `*.bak.<timestamp>` before relinking.
