#!/usr/bin/env bash

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

note() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARNING: %s\n' "$*" >&2
}

detect_steam_root() {
  local candidate

  if [[ -n "${STEAM_ROOT:-}" ]]; then
    candidate="$STEAM_ROOT"
  elif [[ -d "$HOME/.local/share/Steam" ]]; then
    candidate="$HOME/.local/share/Steam"
  elif [[ -d "$HOME/.steam/root" ]]; then
    candidate="$HOME/.steam/root"
  else
    die "Steam was not found. Set STEAM_ROOT to the Steam directory."
  fi

  readlink -f -- "$candidate"
}

latest_webview_version() {
  local webview_root="$1"
  local candidate

  shopt -s nullglob
  for candidate in "$webview_root"/*; do
    [[ -f "$candidate/msedgewebview2.exe" ]] || continue
    printf '%s\n' "${candidate##*/}"
  done | sort -V | tail -n 1
}

assert_grim_dawn_closed() {
  if pgrep -x 'Grim Dawn.exe' >/dev/null 2>&1; then
    die "Grim Dawn is running. Close it before changing or configuring its Proton prefix."
  fi
}
