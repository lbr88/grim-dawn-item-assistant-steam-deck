#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

usage() {
  cat >&2 <<'USAGE'
Usage:
  install-windows-components.sh
  install-windows-components.sh ITEM_ASSISTANT_EXE DOTNET_DESKTOP_RUNTIME_EXE WEBVIEW2_RUNTIME_EXE

With no arguments, missing components are downloaded from their official sources.
The three-argument form remains available for manually supplied installers.
USAGE
  exit 2
}

if [[ $# -eq 0 ]]; then
  exec "$script_dir/ensure-windows-components.sh"
fi

[[ $# -eq 3 ]] || usage
[[ -f "$1" ]] || die "Item Assistant installer not found: $1"
[[ -f "$2" ]] || die ".NET Desktop Runtime installer not found: $2"
[[ -f "$3" ]] || die "WebView2 installer not found: $3"

ia_installer="$(readlink -f -- "$1")"
dotnet_installer="$(readlink -f -- "$2")"
webview_installer="$(readlink -f -- "$3")"
command -v flatpak >/dev/null 2>&1 || die "Flatpak is not installed."
flatpak info com.github.Matoking.protontricks >/dev/null 2>&1 || die "Install Protontricks from Discover/Flathub first."

assert_grim_dawn_closed
steam_root="$(detect_steam_root)"
compat_data="$steam_root/steamapps/compatdata/219990"
prefix="$compat_data/pfx"
installer_dir="$compat_data/gdia-installers"

[[ -d "$prefix" ]] || die "Grim Dawn's Proton prefix does not exist at $prefix. Launch the game once with Proton 10, then close it."

ia_missing=0
dotnet_missing=0
webview_missing=0
vcrun_missing=0
has_item_assistant "$prefix" || ia_missing=1
has_dotnet_desktop_runtime "$prefix" || dotnet_missing=1
has_webview2_runtime "$prefix" || webview_missing=1
has_vcrun2013 "$prefix" || vcrun_missing=1

if [[ $((ia_missing + dotnet_missing + webview_missing + vcrun_missing)) -eq 0 ]]; then
  note "All Windows components are already installed; nothing will be copied or reinstalled."
  exit 0
fi

mkdir -p "$installer_dir"
[[ "$ia_missing" -eq 0 ]] || install -m 0644 "$ia_installer" "$installer_dir/item-assistant-installer.exe"
[[ "$dotnet_missing" -eq 0 ]] || install -m 0644 "$dotnet_installer" "$installer_dir/dotnet-desktop-runtime.exe"
[[ "$webview_missing" -eq 0 ]] || install -m 0644 "$webview_installer" "$installer_dir/webview2-runtime.exe"

if [[ "$vcrun_missing" -eq 1 ]]; then
  note "Installing Visual C++ 2013 into Grim Dawn's prefix..."
  flatpak run com.github.Matoking.protontricks 219990 -q vcrun2013
fi

if [[ "$dotnet_missing" -eq 1 ]]; then
  note "Installing the .NET Desktop Runtime..."
  flatpak run com.github.Matoking.protontricks \
    -c "wine '$installer_dir/dotnet-desktop-runtime.exe' /install /quiet /norestart" \
    219990
fi

if [[ "$webview_missing" -eq 1 ]]; then
  note "Installing Microsoft Edge WebView2 Runtime..."
  flatpak run com.github.Matoking.protontricks \
    -c "wine '$installer_dir/webview2-runtime.exe' /silent /install" \
    219990
fi

if [[ "$ia_missing" -eq 1 ]]; then
  note "Installing Grim Dawn Item Assistant..."
  flatpak run com.github.Matoking.protontricks \
    -c "wine '$installer_dir/item-assistant-installer.exe' /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" \
    219990
fi

ia_dir="$prefix/drive_c/Program Files/IAGD"
webview_root="$prefix/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application"

[[ -f "$ia_dir/IAGrim.exe" ]] || die "The installer finished, but IAGrim.exe was not found at $ia_dir"
[[ -f "$ia_dir/ItemAssistantHook_x64.dll" ]] || warn "The standard hook DLL was not found. Check the Item Assistant release contents."
webview_version="$(latest_webview_version "$webview_root")"
[[ -n "$webview_version" ]] || die "WebView2 files were not found under $webview_root"

note "Windows components installed successfully. WebView2 version: $webview_version"
note "Next, run: $script_dir/link-steam-detection.sh"
