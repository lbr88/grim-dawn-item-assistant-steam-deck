#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$script_dir/_common.sh"

mode="install"
case "${1:-}" in
  --check) mode="check" ;;
  --dry-run) mode="dry-run" ;;
  "") ;;
  *) die "Usage: ensure-windows-components.sh [--check|--dry-run]" ;;
esac

steam_root="$(detect_steam_root)"
compat_data="$steam_root/steamapps/compatdata/219990"
prefix="$compat_data/pfx"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/gdia-steam-deck/installers"
installer_dir="$compat_data/gdia-installers"

[[ -d "$prefix" ]] || die "Grim Dawn's Proton prefix does not exist at $prefix. Launch it once with Proton 10, close it, and rerun this installer."

ia_missing=0
dotnet_missing=0
webview_missing=0
vcrun_missing=0

if has_item_assistant "$prefix"; then
  note "FOUND  Grim Dawn Item Assistant"
else
  note "MISSING Grim Dawn Item Assistant"
  ia_missing=1
fi

if has_dotnet_desktop_runtime "$prefix"; then
  note "FOUND  .NET Desktop Runtime"
else
  note "MISSING .NET Desktop Runtime"
  dotnet_missing=1
fi

if has_webview2_runtime "$prefix"; then
  note "FOUND  Microsoft Edge WebView2 Runtime"
else
  note "MISSING Microsoft Edge WebView2 Runtime"
  webview_missing=1
fi

if has_vcrun2013 "$prefix"; then
  note "FOUND  Microsoft Visual C++ 2013 Runtime"
else
  note "MISSING Microsoft Visual C++ 2013 Runtime"
  vcrun_missing=1
fi

missing_count=$((ia_missing + dotnet_missing + webview_missing + vcrun_missing))
if [[ "$missing_count" -eq 0 ]]; then
  note "All Windows components are already installed; nothing will be downloaded or reinstalled."
  exit 0
fi

if [[ "$mode" == "check" ]]; then
  exit 1
fi

if [[ "$mode" == "dry-run" ]]; then
  note "$missing_count component(s) would be downloaded or installed. No changes were made."
  exit 0
fi

assert_grim_dawn_closed
command -v curl >/dev/null 2>&1 || die "curl is required but was not found."
command -v flatpak >/dev/null 2>&1 || die "Flatpak is required but was not found."

if ! flatpak info com.github.Matoking.protontricks >/dev/null 2>&1; then
  note "Installing Protontricks from Flathub..."
  flatpak install --user -y flathub com.github.Matoking.protontricks
fi

mkdir -p "$cache_dir" "$installer_dir"

download_with_hash() {
  local url="$1"
  local destination="$2"
  local algorithm="$3"
  local expected="$4"
  local actual

  if [[ -f "$destination" ]]; then
    actual="$(${algorithm}sum "$destination" | awk '{print $1}')"
    if [[ "$actual" == "$expected" ]]; then
      note "Using verified cached download: ${destination##*/}"
      return 0
    fi
    warn "Cached ${destination##*/} failed verification; downloading a clean copy."
  fi

  curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 30 \
    "$url" -o "$destination.part"
  actual="$(${algorithm}sum "$destination.part" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || die "Checksum verification failed for ${destination##*/}."
  mv -- "$destination.part" "$destination"
}

download_pe() {
  local url="$1"
  local destination="$2"
  local size

  if [[ -f "$destination" ]]; then
    size="$(stat -c '%s' "$destination" 2>/dev/null || printf 0)"
    if [[ "$(head -c 2 "$destination" 2>/dev/null)" == "MZ" && "$size" -gt 1000000 ]]; then
      note "Using cached download: ${destination##*/}"
      return 0
    fi
    warn "Cached ${destination##*/} is invalid; downloading a clean copy."
  fi

  curl --proto '=https' --tlsv1.2 -fL --retry 3 --connect-timeout 30 \
    "$url" -o "$destination.part"
  size="$(stat -c '%s' "$destination.part" 2>/dev/null || printf 0)"
  [[ "$(head -c 2 "$destination.part" 2>/dev/null)" == "MZ" && "$size" -gt 1000000 ]] \
    || die "The downloaded ${destination##*/} is not a valid Windows installer."
  mv -- "$destination.part" "$destination"
}

if [[ "$ia_missing" -eq 1 ]]; then
  ia_cache="$cache_dir/GDItemAssistant-1.5.9700.13021.exe"
  download_with_hash \
    'https://github.com/marius00/iagd/releases/download/1.5.9700.13021/GDItemAssistant.exe' \
    "$ia_cache" sha256 \
    '445eded974f2450480423292ee137989c5d02e6de770ee57b5351ab62af81d34'
  install -m 0644 "$ia_cache" "$installer_dir/item-assistant-installer.exe"
fi

if [[ "$dotnet_missing" -eq 1 ]]; then
  dotnet_cache="$cache_dir/windowsdesktop-runtime-10.0.11-win-x64.exe"
  download_with_hash \
    'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/10.0.11/windowsdesktop-runtime-10.0.11-win-x64.exe' \
    "$dotnet_cache" sha512 \
    '4dbf26b0b78f55c5f59a46c3c81327b23a04f449f7ac6798204dcd19d99459258936daaede61d1b8c1ba523d6c26bf68bac86b3371d22e67cef235edbdc2f26c'
  install -m 0644 "$dotnet_cache" "$installer_dir/dotnet-desktop-runtime.exe"
fi

if [[ "$webview_missing" -eq 1 ]]; then
  webview_cache="$cache_dir/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
  download_pe 'https://go.microsoft.com/fwlink/?linkid=2124701' "$webview_cache"
  install -m 0644 "$webview_cache" "$installer_dir/webview2-runtime.exe"
fi

if [[ "$vcrun_missing" -eq 1 ]]; then
  note "Installing Microsoft Visual C++ 2013 Runtime..."
  flatpak run com.github.Matoking.protontricks 219990 -q vcrun2013
  has_vcrun2013 "$prefix" || die "Visual C++ 2013 installation completed, but its runtime DLLs were not found."
fi

if [[ "$dotnet_missing" -eq 1 ]]; then
  note "Installing .NET Desktop Runtime..."
  flatpak run com.github.Matoking.protontricks \
    -c "wine '$installer_dir/dotnet-desktop-runtime.exe' /install /quiet /norestart" 219990
  has_dotnet_desktop_runtime "$prefix" || die ".NET installation completed, but the desktop runtime was not found."
fi

if [[ "$webview_missing" -eq 1 ]]; then
  note "Installing Microsoft Edge WebView2 Runtime..."
  flatpak run com.github.Matoking.protontricks \
    -c "wine '$installer_dir/webview2-runtime.exe' /silent /install" 219990
  has_webview2_runtime "$prefix" || die "WebView2 installation completed, but the runtime was not found."
fi

if [[ "$ia_missing" -eq 1 ]]; then
  note "Installing Grim Dawn Item Assistant..."
  flatpak run com.github.Matoking.protontricks \
    -c "wine '$installer_dir/item-assistant-installer.exe' /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" 219990
  has_item_assistant "$prefix" || die "Item Assistant installation completed, but its executable or hook DLL was not found."
fi

note "Every required Windows component is now installed."
