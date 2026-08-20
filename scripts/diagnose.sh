#!/usr/bin/env bash
set -u

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

failures=0

check_file() {
  local label="$1"
  local path="$2"

  if [[ -f "$path" ]]; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n      %s\n' "$label" "$path"
    failures=$((failures + 1))
  fi
}

check_dir() {
  local label="$1"
  local path="$2"

  if [[ -d "$path" ]]; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n      %s\n' "$label" "$path"
    failures=$((failures + 1))
  fi
}

steam_root="$(detect_steam_root)"
prefix="$steam_root/steamapps/compatdata/219990/pfx"
ia_dir="$prefix/drive_c/Program Files/IAGD"
webview_root="$prefix/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application"
tool_dir="$steam_root/compatibilitytools.d/GDIA-Proton-10"
windows_steam="$prefix/drive_c/Program Files (x86)/Steam"

note "Steam root: $steam_root"
note "Grim Dawn prefix: $prefix"
note ""

check_file "Grim Dawn executable" "$steam_root/steamapps/common/Grim Dawn/Grim Dawn.exe"
check_file "Grim Dawn database" "$steam_root/steamapps/common/Grim Dawn/database/database.arz"
check_file "Item Assistant executable" "$ia_dir/IAGrim.exe"
check_file "Item Assistant hook DLL" "$ia_dir/ItemAssistantHook_x64.dll"
check_file ".NET Desktop Runtime host" "$prefix/drive_c/Program Files/dotnet/dotnet.exe"
check_file "Steam config detection link" "$windows_steam/config/config.vdf"
check_file "Grim Dawn detection link" "$windows_steam/steamapps/common/Grim Dawn/database/database.arz"
check_file "Custom compatibility launcher" "$tool_dir/proton"
check_file "Upstream Proton link" "$tool_dir/upstream-proton"
check_dir "Item Assistant local data directory" "$prefix/drive_c/users/steamuser/AppData/Local/EvilSoft/IAGD"

webview_version="$(latest_webview_version "$webview_root")"
if [[ -n "$webview_version" ]]; then
  printf 'PASS  WebView2 runtime (%s)\n' "$webview_version"
else
  printf 'FAIL  WebView2 runtime\n      %s\n' "$webview_root"
  failures=$((failures + 1))
fi

if grep -q 'GDIA-Proton-10' "$steam_root/config/config.vdf" 2>/dev/null; then
  printf 'PASS  Steam compatibility-tool mapping is present\n'
else
  printf 'WARN  Steam mapping not detected. Select GD Item Assistant - Proton 10 in Grim Dawn Properties > Compatibility.\n'
fi

log_file="${XDG_STATE_HOME:-$HOME/.local/state}/gdia-steam-deck/launch.log"
if [[ -f "$log_file" ]]; then
  note ""
  note "Recent launcher milestones (credential-safe filter):"
  grep -E 'Starting Item Assistant|Starting Grim Dawn|Grim Dawn exited|ERROR:' "$log_file" | tail -n 12 || true
else
  note ""
  note "No runtime launch log exists yet: $log_file"
fi

note ""
if [[ "$failures" -eq 0 ]]; then
  note "All required files were found."
  exit 0
fi

note "$failures required check(s) failed. See docs/TROUBLESHOOTING.md."
exit 1
