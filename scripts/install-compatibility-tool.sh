#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

steam_root="$(detect_steam_root)"
proton_dir="${PROTON_DIR:-$steam_root/steamapps/common/Proton 10.0}"
tool_name="GDIA-Proton-10"
target="$steam_root/compatibilitytools.d/$tool_name"
backup_root="${XDG_DATA_HOME:-$HOME/.local/share}/gdia-steam-deck/backups"
timestamp="$(date +%Y%m%d-%H%M%S)"

[[ -x "$proton_dir/proton" ]] || die "Official Proton 10 was not found at $proton_dir. Install/select Proton 10 in Steam first, or set PROTON_DIR."

required_runtime_files=(
  files
  filelock.py
  proton_3.7_tracked_files
  steampipe_fixups.json
  steampipe_fixups.py
  version
)

for runtime_file in "${required_runtime_files[@]}"; do
  [[ -e "$proton_dir/$runtime_file" ]] || die "The Proton runtime is missing $proton_dir/$runtime_file"
done

case "$target" in
  "$steam_root/compatibilitytools.d/$tool_name") ;;
  *) die "Refusing unexpected compatibility-tool target: $target" ;;
esac

mkdir -p "$steam_root/compatibilitytools.d" "$backup_root"

if [[ -e "$target" || -L "$target" ]]; then
  backup="$backup_root/$tool_name-$timestamp"
  mv -- "$target" "$backup"
  note "Moved the previous tool to: $backup"
fi

mkdir -p "$target"
install -m 0755 "$repo_root/compatibility-tool/proton" "$target/proton"
install -m 0644 "$repo_root/compatibility-tool/compatibilitytool.vdf" "$target/compatibilitytool.vdf"
install -m 0644 "$repo_root/compatibility-tool/toolmanifest.vdf" "$target/toolmanifest.vdf"

ln -s "$proton_dir/proton" "$target/upstream-proton"
for runtime_file in "${required_runtime_files[@]}"; do
  ln -s "$proton_dir/$runtime_file" "$target/$runtime_file"
done

note "Installed $tool_name at: $target"
note ""
note "Next steps:"
note "1. Fully exit and restart Steam."
note "2. Open Grim Dawn > Properties > Compatibility."
note "3. Enable the forced compatibility tool and choose: GD Item Assistant - Proton 10"
note "4. Leave Grim Dawn's Launch Options empty."
note "5. Launch only the official Grim Dawn library entry."
