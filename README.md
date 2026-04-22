# Dotenv Config Repo

Machine config repo with a split between shared configs and OS-specific configs.

## Intent

- Keep reusable configs in `common/`.
- Keep Arch-only configs in `arch/`.
- Use symlinks from home paths into this repo so config is versioned and portable.

## Current Layout

- `common/`
  - `common/nvim`
  - `common/zsh`
- `arch/`
  - Arch-focused desktop/system configs (sway, waybar, kitty, etc.)
- `scripts/`
  - `scripts/link-configs.sh` for safe symlink setup

## Symlink Workflow

Run:

```bash
./scripts/link-configs.sh
```

This currently manages:

- `~/.config/nvim` -> `common/nvim`
- `~/.config/zsh` -> `common/zsh`
- `~/.gitconfig` -> `.gitconfig`

If a path already exists and is not the expected link target, the script backs it up as `*.bak.<timestamp>` and then creates the new symlink.
