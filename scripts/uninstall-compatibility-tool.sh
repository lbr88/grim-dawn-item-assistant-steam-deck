#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

steam_root="$(detect_steam_root)"
tool_name="GDIA-Proton-10"
target="$steam_root/compatibilitytools.d/$tool_name"
backup_root="${XDG_DATA_HOME:-$HOME/.local/share}/gdia-steam-deck/disabled"
timestamp="$(date +%Y%m%d-%H%M%S)"
disabled="$backup_root/$tool_name-$timestamp"

[[ -e "$target" || -L "$target" ]] || die "$tool_name is not installed at $target"

case "$target" in
  "$steam_root/compatibilitytools.d/$tool_name") ;;
  *) die "Refusing unexpected compatibility-tool target: $target" ;;
esac

mkdir -p "$backup_root"
mv -- "$target" "$disabled"

note "Disabled the compatibility tool without deleting it."
note "Moved it to: $disabled"
note ""
note "In Steam, set Grim Dawn back to official Proton 10 (or clear the forced-tool selection), then restart Steam."
note "To restore this exact copy later, fully exit Steam and move the directory back to:"
note "$target"
