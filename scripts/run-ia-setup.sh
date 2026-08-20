#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

assert_grim_dawn_closed
command -v flatpak >/dev/null 2>&1 || die "Flatpak is not installed."
flatpak info com.github.Matoking.protontricks >/dev/null 2>&1 || die "Install Protontricks from Discover/Flathub first."

steam_root="$(detect_steam_root)"
prefix="$steam_root/steamapps/compatdata/219990/pfx"
ia_dir="$prefix/drive_c/Program Files/IAGD"
webview_root="$prefix/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application"

[[ -f "$ia_dir/IAGrim.exe" ]] || die "Item Assistant not found at $ia_dir/IAGrim.exe"
webview_version="$(latest_webview_version "$webview_root")"
[[ -n "$webview_version" ]] || die "No WebView2 runtime found under $webview_root"

webview_windows_path="C:\\Program Files (x86)\\Microsoft\\EdgeWebView\\Application\\$webview_version"
cd "$ia_dir"

note "Starting Item Assistant in configuration-only mode. Keep Grim Dawn closed."
note "Parse the database and finish online sync, then close Item Assistant before installing/testing the runtime compatibility tool."

exec flatpak run \
  "--env=WEBVIEW2_BROWSER_EXECUTABLE_FOLDER=$webview_windows_path" \
  com.github.Matoking.protontricks --no-background-wineserver \
  -c 'wine "C:\Program Files\IAGD\IAGrim.exe"' \
  219990
