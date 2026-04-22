#!/usr/bin/env bash
# Symlink ~/.config/nvim and ~/.config/zsh to this repo (absolute targets).
# Backs up existing non-matching paths. Safe to re-run if links already correct.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp="$(date +%Y%m%d%H%M%S)"

ensure_symlink() {
  local name="$1"
  local target="${REPO_ROOT}/${name}"
  local link="${CONFIG_DIR}/${name}"

  if [[ ! -d "$target" ]]; then
    echo "error: missing repo directory: $target" >&2
    return 1
  fi

  local abs_target
  abs_target="$(cd "$target" && pwd)"

  mkdir -p "$CONFIG_DIR"

  if [[ -L "$link" ]]; then
    local cur
    cur="$(readlink -f "$link" 2>/dev/null || true)"
    if [[ "$cur" == "$abs_target" ]]; then
      ln -sfn "$abs_target" "$link"
      echo "ok: refreshed $link -> $abs_target"
      return 0
    fi
    echo "warn: $link is a symlink elsewhere; moving to ${link}.bak.${stamp}"
    mv "$link" "${link}.bak.${stamp}"
  elif [[ -e "$link" ]]; then
    echo "warn: $link exists; moving to ${link}.bak.${stamp}"
    mv "$link" "${link}.bak.${stamp}"
  fi

  ln -sfn "$abs_target" "$link"
  echo "ok: created $link -> $abs_target"
}

ensure_symlink nvim
ensure_symlink zsh
