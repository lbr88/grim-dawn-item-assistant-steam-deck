#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

safe_link() {
  local source_path="$1"
  local target_path="$2"

  if [[ -e "$target_path" && ! -L "$target_path" ]]; then
    die "Refusing to replace a real file or directory: $target_path"
  fi

  ln -sfn -- "$source_path" "$target_path"
}

assert_grim_dawn_closed
steam_root="$(detect_steam_root)"
compat_data="$steam_root/steamapps/compatdata/219990"
prefix="$compat_data/pfx"
grim_dawn_dir="${GRIM_DAWN_DIR:-$steam_root/steamapps/common/Grim Dawn}"
grim_dawn_dir="$(readlink -f -- "$grim_dawn_dir")"

[[ -f "$steam_root/config/config.vdf" ]] || die "Steam config not found at $steam_root/config/config.vdf"
[[ -f "$grim_dawn_dir/Grim Dawn.exe" ]] || die "Grim Dawn.exe not found under $grim_dawn_dir. Set GRIM_DAWN_DIR if it is in another Steam library."
[[ -f "$grim_dawn_dir/database/database.arz" ]] || die "Grim Dawn database not found under $grim_dawn_dir/database"
[[ -d "$prefix" ]] || die "Grim Dawn's Proton prefix does not exist at $prefix"

windows_steam="$prefix/drive_c/Program Files (x86)/Steam"
mkdir -p "$windows_steam/config" "$windows_steam/steamapps/common"

safe_link "$steam_root/config/config.vdf" "$windows_steam/config/config.vdf"
safe_link "$grim_dawn_dir" "$windows_steam/steamapps/common/Grim Dawn"

note "Linked Steam detection paths inside Grim Dawn's Proton prefix."
note "Item Assistant can now detect: C:\\Program Files (x86)\\Steam\\steamapps\\common\\Grim Dawn"
note "Next, run Item Assistant for setup with: $script_dir/run-ia-setup.sh"
