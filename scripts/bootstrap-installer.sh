#!/usr/bin/env bash
set -euo pipefail

repository_url="${GDIA_REPOSITORY_ARCHIVE_URL:-https://github.com/lbr88/grim-dawn-item-assistant-steam-deck/archive/refs/heads/main.tar.gz}"
data_root="${XDG_DATA_HOME:-$HOME/.local/share}/gdia-steam-deck"
target="$data_root/repository"
backup_root="$data_root/backups"
timestamp="$(date +%Y%m%d-%H%M%S)"
temp_dir="$(mktemp -d /tmp/gdia-bootstrap.XXXXXX)"

cleanup() {
  rm -r -- "$temp_dir"
}
trap cleanup EXIT

command -v curl >/dev/null 2>&1 || {
  printf 'ERROR: curl is required but was not found.\n' >&2
  exit 1
}
command -v tar >/dev/null 2>&1 || {
  printf 'ERROR: tar is required but was not found.\n' >&2
  exit 1
}

printf 'Downloading the Grim Dawn Item Assistant Steam Deck installer...\n'
curl -fL --connect-timeout 60 "$repository_url" -o "$temp_dir/repository.tar.gz"
tar -xzf "$temp_dir/repository.tar.gz" -C "$temp_dir"

installer_path="$(find "$temp_dir" -mindepth 3 -maxdepth 3 -type f -path '*/scripts/steam-deck-installer.sh' -print -quit)"
[[ -n "$installer_path" ]] || {
  printf 'ERROR: The downloaded archive did not contain the guided installer.\n' >&2
  exit 1
}
source_root="$(cd -- "$(dirname -- "$installer_path")/.." && pwd)"

mkdir -p "$data_root" "$backup_root"
if [[ -e "$target" || -L "$target" ]]; then
  backup="$backup_root/repository-$timestamp"
  mv -- "$target" "$backup"
  printf 'Saved the previous installer files at: %s\n' "$backup"
fi

mv -- "$source_root" "$target"
chmod +x "$target/compatibility-tool/proton" "$target/scripts/"*.sh

printf 'Installer files are ready at: %s\n' "$target"
if [[ "${GDIA_BOOTSTRAP_ONLY:-0}" == "1" ]]; then
  exit 0
fi

cleanup
trap - EXIT
exec "$target/scripts/steam-deck-installer.sh"
