#!/usr/bin/env bash
# Symlink selected config paths to this repo (absolute targets).
# Backs up existing non-matching paths. Safe to re-run if links already correct.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp="$(date +%Y%m%d%H%M%S)"

ensure_link() {
  local target="$1"
  local link="$2"
  local expected_type="${3:-any}"

  if [[ ! -e "$target" ]]; then
    echo "error: missing repo path: $target" >&2
    return 1
  fi
  if [[ "$expected_type" == "dir" && ! -d "$target" ]]; then
    echo "error: expected directory target: $target" >&2
    return 1
  fi
  if [[ "$expected_type" == "file" && ! -f "$target" ]]; then
    echo "error: expected file target: $target" >&2
    return 1
  fi

  local abs_target
  abs_target="$(readlink -f "$target")"
  mkdir -p "$(dirname "$link")"

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

ensure_link "${REPO_ROOT}/nvim" "${CONFIG_DIR}/nvim" "dir"
ensure_link "${REPO_ROOT}/zsh" "${CONFIG_DIR}/zsh" "dir"
ensure_link "${REPO_ROOT}/.gitconfig" "${HOME}/.gitconfig" "file"
