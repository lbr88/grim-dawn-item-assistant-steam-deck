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

choose_installer() {
  local prompt="$1"
  local selected

  selected="$(kdialog --title "$title" --getopenfilename "$HOME/Downloads" '*.exe|Windows installers (*.exe)' 2>/dev/null)" || return 1
  [[ -n "$selected" ]] || return 1
  [[ -f "$selected" ]] || {
    dialog_error "$prompt was not found."
    return 1
  }
  printf '%s\n' "$selected"
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
  if ! flatpak info com.github.Matoking.protontricks >/dev/null 2>&1; then
    if kdialog --title "$title" --yesno "Protontricks is required for the one-time Windows component installation. Install it from Flathub now?" 2>/dev/null; then
      flatpak install --user -y flathub com.github.Matoking.protontricks
    else
      cancelled
    fi
  fi

  if ! kdialog --title "$title" --yesno "Before continuing, download these three official Windows x64 installers:\n\n- Grim Dawn Item Assistant\n- .NET Desktop Runtime required by Item Assistant\n- Microsoft Edge WebView2 Evergreen Runtime\n\nHave you downloaded all three?" 2>/dev/null; then
    xdg-open 'https://grimdawn.evilsoft.net/' >/dev/null 2>&1 || true
    xdg-open 'https://dotnet.microsoft.com/download/dotnet/' >/dev/null 2>&1 || true
    xdg-open 'https://developer.microsoft.com/microsoft-edge/webview2/' >/dev/null 2>&1 || true
    dialog_info "The official download pages were opened in your browser. Download the three Windows x64 installers, then run this desktop installer again."
    exit 0
  fi

  dialog_info "Select the Grim Dawn Item Assistant installer."
  ia_installer="$(choose_installer 'The Item Assistant installer')" || cancelled
  dialog_info "Select the Windows x64 .NET Desktop Runtime installer."
  dotnet_installer="$(choose_installer 'The .NET Desktop Runtime installer')" || cancelled
  dialog_info "Select the Windows x64 Microsoft Edge WebView2 Runtime installer."
  webview_installer="$(choose_installer 'The WebView2 installer')" || cancelled

  dialog_info "The Windows components will now be installed into Grim Dawn's Proton prefix. This can take several minutes. Follow any installer windows that appear."
  "$script_dir/install-windows-components.sh" "$ia_installer" "$dotnet_installer" "$webview_installer"
  "$script_dir/link-steam-detection.sh"

  dialog_info "Item Assistant will open by itself for one-time configuration. Keep Grim Dawn closed. Let the Grim Dawn database finish parsing, sign into Item Assistant online sync if wanted, wait for all items to download, and then close Item Assistant to continue."
  "$script_dir/run-ia-setup.sh"

  if ! kdialog --title "$title" --yesno "Did Item Assistant detect Grim Dawn, finish parsing its database, and complete any online synchronization?" 2>/dev/null; then
    dialog_info "The combined Steam launcher was not installed yet. Rerun this installer after Item Assistant configuration succeeds."
    exit 0
  fi
fi

"$script_dir/install-compatibility-tool.sh"

dialog_info "Installation is complete.\n\n1. Fully exit and restart Steam.\n2. Open Grim Dawn > Properties > Compatibility.\n3. Force 'GD Item Assistant - Proton 10'.\n4. Leave Launch Options empty.\n5. Launch only the official Grim Dawn entry.\n\nItem Assistant will start first and Grim Dawn will follow about 15 seconds later."
