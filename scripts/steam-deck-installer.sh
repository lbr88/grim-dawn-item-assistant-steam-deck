#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

title="Grim Dawn Item Assistant - Steam Deck"

dialog_error() {
  kdialog --title "$title" --error "$1" 2>/dev/null || printf 'ERROR: %s\n' "$1" >&2
}

dialog_info() {
  kdialog --title "$title" --msgbox "$1" 2>/dev/null || printf '%s\n' "$1"
}

cancelled() {
  dialog_info "Installation was cancelled. No further changes were made."
  exit 0
}

show_diagnostics() {
  local report
  report="$(mktemp /tmp/gdia-diagnostics.XXXXXX)"
  "$script_dir/diagnose.sh" >"$report" 2>&1 || true
  kdialog --title "$title" --textbox "$report" 720 520 2>/dev/null || sed -n '1,240p' "$report"
  rm -f -- "$report"
}

trap 'status=$?; if [[ $status -ne 0 ]]; then dialog_error "The installer stopped because a check or command failed. The terminal window contains the detailed error. No game saves or Item Assistant database were deleted."; fi' EXIT

command -v kdialog >/dev/null 2>&1 || die "kdialog is required. Run this installer in SteamOS Desktop Mode."

choice="$(kdialog --title "$title" --menu \
  "Choose an action. Full setup is recommended for a new installation." \
  full "Full setup: dependencies, Item Assistant, database, and Steam launcher" \
  runtime "Install or update only the combined Steam launcher" \
  diagnose "Run read-only diagnostics" \
  2>/dev/null)" || cancelled

if [[ "$choice" == "diagnose" ]]; then
  show_diagnostics
  exit 0
fi

steam_root="$(detect_steam_root)"
prefix="$steam_root/steamapps/compatdata/219990/pfx"
proton_dir="${PROTON_DIR:-$steam_root/steamapps/common/Proton 10.0}"

if [[ ! -f "$steam_root/steamapps/common/Grim Dawn/Grim Dawn.exe" ]]; then
  if kdialog --title "$title" --yesno "Grim Dawn was not found in the standard internal Steam library. Is it installed on an SD card or another Steam library?" 2>/dev/null; then
    grim_dawn_dir="$(kdialog --title "$title" --getexistingdirectory "$HOME" 2>/dev/null)" || cancelled
    [[ -f "$grim_dawn_dir/Grim Dawn.exe" ]] || {
      dialog_error "That folder does not contain Grim Dawn.exe. Select the game's 'Grim Dawn' directory."
      exit 1
    }
    export GRIM_DAWN_DIR="$grim_dawn_dir"
  else
    dialog_error "Install Grim Dawn in Steam, force official Proton 10, launch it once, and close it before running this installer."
    exit 1
  fi
fi

[[ -d "$prefix" ]] || {
  dialog_error "Grim Dawn's Proton prefix does not exist. In Steam, force official Proton 10, launch Grim Dawn once, then close it and rerun this installer."
  exit 1
}
[[ -x "$proton_dir/proton" ]] || {
  dialog_error "Official Proton 10 is not installed. Select Proton 10 for Grim Dawn in Steam, launch the game once, and rerun this installer."
  exit 1
}
assert_grim_dawn_closed

if [[ "$choice" == "full" ]]; then
  database_was_ready=0
  if has_parsed_item_database "$prefix"; then
    database_was_ready=1
  fi

  dialog_info "The installer will now check the existing Grim Dawn prefix. Already-installed components are skipped. Only missing components are downloaded and installed automatically."
  "$script_dir/ensure-windows-components.sh"
  "$script_dir/link-steam-detection.sh"

  if [[ "$database_was_ready" -eq 1 ]] || has_parsed_item_database "$prefix"; then
    database_count="$(item_database_count "$prefix")"
    note "Item Assistant database is already configured ($database_count records); skipping setup."
  else
    if ! flatpak info com.github.Matoking.protontricks >/dev/null 2>&1; then
      note "Installing Protontricks from Flathub for first-time Item Assistant configuration..."
      flatpak install --user -y flathub com.github.Matoking.protontricks
    fi
    dialog_info "Item Assistant needs one unavoidable first-time configuration. It will open now. Keep Grim Dawn closed, let the game database finish parsing, sign into Item Assistant online sync if wanted, wait for synchronization to finish, and then close Item Assistant."
    "$script_dir/run-ia-setup.sh"
    has_parsed_item_database "$prefix" || die "Item Assistant closed before its Grim Dawn database finished parsing. Open it again and allow setup to complete."
  fi
fi

"$script_dir/install-compatibility-tool.sh"

dialog_info "Installation is complete.\n\n1. Fully exit and restart Steam.\n2. Open Grim Dawn > Properties > Compatibility.\n3. Force 'GD Item Assistant - Proton 10'.\n4. Leave Launch Options empty.\n5. Launch only the official Grim Dawn entry.\n\nItem Assistant will start first and Grim Dawn will follow about 15 seconds later."
