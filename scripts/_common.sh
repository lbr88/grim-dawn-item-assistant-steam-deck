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

item_assistant_dir() {
  local prefix="$1"
  printf '%s\n' "$prefix/drive_c/Program Files/IAGD"
}

item_assistant_data_dir() {
  local prefix="$1"
  printf '%s\n' "$prefix/drive_c/users/steamuser/AppData/Local/EvilSoft/IAGD"
}

has_item_assistant() {
  local ia_dir
  ia_dir="$(item_assistant_dir "$1")"
  [[ -f "$ia_dir/IAGrim.exe" && -f "$ia_dir/ItemAssistantHook_x64.dll" ]]
}

has_dotnet_desktop_runtime() {
  local runtime_root="$1/drive_c/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App"
  local candidate

  shopt -s nullglob
  for candidate in "$runtime_root"/10.*; do
    [[ -d "$candidate" ]] && return 0
  done
  return 1
}

has_webview2_runtime() {
  local webview_root="$1/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application"
  [[ -n "$(latest_webview_version "$webview_root")" ]]
}

has_vcrun2013() {
  local prefix="$1"
  [[ -f "$prefix/drive_c/windows/system32/msvcp120.dll" \
    && -f "$prefix/drive_c/windows/system32/msvcr120.dll" \
    && -f "$prefix/drive_c/windows/syswow64/msvcp120.dll" \
    && -f "$prefix/drive_c/windows/syswow64/msvcr120.dll" ]]
}

item_database_count() {
  local database
  database="$(item_assistant_data_dir "$1")/data/userdata.db"

  command -v sqlite3 >/dev/null 2>&1 || return 1
  [[ -f "$database" ]] || return 1
  sqlite3 -readonly "$database" 'SELECT count(*) FROM DatabaseItem_v2;' 2>/dev/null
}

has_parsed_item_database() {
  local count
  count="$(item_database_count "$1")" || return 1
  [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]]
}
